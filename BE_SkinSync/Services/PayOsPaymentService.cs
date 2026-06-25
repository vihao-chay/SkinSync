using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Net.payOS;
using Net.payOS.Types;
using SkinSync.Data;
using SkinSync.Models.Dtos.Payment;
using SkinSync.Models.Entities;
using SkinSync.Services.AIPlatform;

namespace SkinSync.Services;

public class PayOsPaymentService : IPayOsPaymentService
{
    private readonly PayOS _payOS;
    private readonly AppDbContext _dbContext;
    private readonly ISubscriptionPlanService _subscriptionService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<PayOsPaymentService> _logger;

    private static readonly HashSet<string> ValidPlanCodes = new(StringComparer.OrdinalIgnoreCase)
    {
        "plus",
        "premium"
    };

    public PayOsPaymentService(
        PayOS payOS,
        AppDbContext dbContext,
        ISubscriptionPlanService subscriptionService,
        IConfiguration configuration,
        ILogger<PayOsPaymentService> _logger)
    {
        _payOS = payOS;
        _dbContext = dbContext;
        _subscriptionService = subscriptionService;
        _configuration = configuration;
        this._logger = _logger;
    }

    public async Task<PaymentLinkResponseDto> CreatePaymentLinkAsync(Guid userId, string planCode, CancellationToken cancellationToken)
    {
        var normalizedPlanCode = planCode.Trim().ToLowerInvariant();
        if (!ValidPlanCodes.Contains(normalizedPlanCode))
        {
            throw new AiFeatureException("INVALID_PLAN", "Chỉ hỗ trợ mua gói 'plus' hoặc 'premium'.", 400);
        }

        var plan = await _dbContext.SubscriptionPlans
            .FirstOrDefaultAsync(x => x.Code == normalizedPlanCode && x.IsActive, cancellationToken)
            ?? throw new AiFeatureException("PLAN_NOT_FOUND", "Gói đăng ký không tồn tại hoặc đã bị vô hiệu hóa.", 404);

        // Generate unique orderCode
        long orderCode;
        int attempts = 0;
        do
        {
            if (attempts++ > 10)
            {
                throw new AiFeatureException("ORDER_GEN_FAILED", "Không thể tạo mã đơn hàng độc nhất. Hãy thử lại.", 500);
            }
            // Use current timestamp in ms + random 3 digits to ensure uniqueness
            var random = new Random();
            orderCode = (DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000) + random.Next(100, 999);
        } while (await _dbContext.PaymentOrders.AnyAsync(x => x.OrderCode == orderCode, cancellationToken));

        var returnUrl = _configuration["PayOS:ReturnUrl"] ?? "skinsync://payment/success";
        var cancelUrl = _configuration["PayOS:CancelUrl"] ?? "skinsync://payment/cancel";

        // PayOS amount is integer
        int amount = (int)plan.Price;

        var items = new List<ItemData>
        {
            new ItemData($"Gói dịch vụ {plan.Name}", 1, amount)
        };

        var paymentData = new PaymentData(
            orderCode: orderCode,
            amount: amount,
            description: $"SkinSync {plan.Name}",
            items: items,
            cancelUrl: cancelUrl,
            returnUrl: returnUrl
        );

        try
        {
            CreatePaymentResult paymentLinkRes = await _payOS.createPaymentLink(paymentData);

            var paymentOrder = new PaymentOrder
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                PlanId = plan.Id,
                OrderCode = orderCode,
                Amount = plan.Price,
                Status = "pending",
                PayOsPaymentLinkId = paymentLinkRes.paymentLinkId,
                CheckoutUrl = paymentLinkRes.checkoutUrl,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.PaymentOrders.Add(paymentOrder);
            await _dbContext.SaveChangesAsync(cancellationToken);

            return new PaymentLinkResponseDto
            {
                CheckoutUrl = paymentLinkRes.checkoutUrl,
                OrderCode = orderCode
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi tạo payment link với PayOS cho user {UserId}, gói {PlanCode}", userId, planCode);
            throw new AiFeatureException("PAYMENT_LINK_CREATION_FAILED", $"Lỗi tạo liên kết thanh toán PayOS: {ex.Message}", 500);
        }
    }

    public async Task<bool> HandleWebhookAsync(WebhookType webhookData, CancellationToken cancellationToken)
    {
        try
        {
            // Check if it's a confirmation/test webhook ping from PayOS
            if (webhookData.desc == "confirm-webhook" || 
                (webhookData.data != null && (webhookData.data.desc == "confirm-webhook" || webhookData.data.orderCode == 123 || webhookData.data.orderCode < 1000)))
            {
                _logger.LogInformation("Nhận xác thực webhook hoặc giao dịch test từ PayOS (bypass signature)");
                return true;
            }

            // Verify and extract webhook data
            WebhookData verifiedData = _payOS.verifyPaymentWebhookData(webhookData);
            
            long orderCode = verifiedData.orderCode;
            _logger.LogInformation("Nhận webhook PayOS cho đơn hàng {OrderCode}, trạng thái webhook: {Desc}", orderCode, verifiedData.desc);

            var paymentOrder = await _dbContext.PaymentOrders
                .Include(x => x.Plan)
                .FirstOrDefaultAsync(x => x.OrderCode == orderCode, cancellationToken);

            if (paymentOrder == null)
            {
                _logger.LogWarning("Không tìm thấy đơn hàng tương ứng với orderCode {OrderCode} từ Webhook PayOS", orderCode);
                return true; // Trả về true (200 OK) cho PayOS
            }

            if (paymentOrder.Status == "pending")
            {
                if (verifiedData.desc == "success" || verifiedData.desc == "Thành công")
                {
                    paymentOrder.Status = "paid";
                    paymentOrder.PaidAt = DateTime.UtcNow;
                    
                    // Activate subscription
                    await _subscriptionService.ChangeUserPlanAsync(paymentOrder.UserId, paymentOrder.Plan.Code, cancellationToken);
                    
                    await _dbContext.SaveChangesAsync(cancellationToken);
                    _logger.LogInformation("Thanh toán thành công qua Webhook cho user {UserId}, gói {PlanCode}, đơn hàng {OrderCode}", 
                        paymentOrder.UserId, paymentOrder.Plan.Code, orderCode);
                }
                else
                {
                    paymentOrder.Status = "cancelled";
                    await _dbContext.SaveChangesAsync(cancellationToken);
                    _logger.LogInformation("Đơn hàng {OrderCode} bị hủy hoặc thất bại qua Webhook", orderCode);
                }
            }

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi xử lý webhook từ PayOS");
            return false;
        }
    }

    public async Task<VerifyPaymentResponseDto> VerifyPaymentAsync(long orderCode, CancellationToken cancellationToken)
    {
        var paymentOrder = await _dbContext.PaymentOrders
            .Include(x => x.Plan)
            .FirstOrDefaultAsync(x => x.OrderCode == orderCode, cancellationToken)
            ?? throw new AiFeatureException("ORDER_NOT_FOUND", "Không tìm thấy đơn hàng thanh toán này.", 404);

        if (paymentOrder.Status != "pending")
        {
            return new VerifyPaymentResponseDto
            {
                Status = paymentOrder.Status,
                PlanCode = paymentOrder.Plan.Code
            };
        }

        try
        {
            // Query latest status from PayOS
            PaymentLinkInformation paymentInfo = await _payOS.getPaymentLinkInformation(orderCode);
            var payOsStatus = paymentInfo.status.ToUpperInvariant();

            _logger.LogInformation("Polling trạng thái PayOS cho đơn hàng {OrderCode}: {Status}", orderCode, payOsStatus);

            if (payOsStatus == "PAID")
            {
                // Double check to prevent race conditions
                var latestOrder = await _dbContext.PaymentOrders
                    .Include(x => x.Plan)
                    .FirstOrDefaultAsync(x => x.Id == paymentOrder.Id, cancellationToken);
                
                if (latestOrder != null && latestOrder.Status == "pending")
                {
                    latestOrder.Status = "paid";
                    latestOrder.PaidAt = DateTime.UtcNow;

                    await _subscriptionService.ChangeUserPlanAsync(latestOrder.UserId, latestOrder.Plan.Code, cancellationToken);
                    await _dbContext.SaveChangesAsync(cancellationToken);
                }

                return new VerifyPaymentResponseDto
                {
                    Status = "paid",
                    PlanCode = paymentOrder.Plan.Code
                };
            }
            else if (payOsStatus is "CANCELLED" or "EXPIRED")
            {
                var latestOrder = await _dbContext.PaymentOrders
                    .FirstOrDefaultAsync(x => x.Id == paymentOrder.Id, cancellationToken);
                
                if (latestOrder != null && latestOrder.Status == "pending")
                {
                    latestOrder.Status = "cancelled";
                    await _dbContext.SaveChangesAsync(cancellationToken);
                }

                return new VerifyPaymentResponseDto
                {
                    Status = "cancelled",
                    PlanCode = paymentOrder.Plan.Code
                };
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Lỗi kiểm tra thông tin thanh toán trực tiếp từ PayOS cho orderCode {OrderCode}", orderCode);
        }

        return new VerifyPaymentResponseDto
        {
            Status = paymentOrder.Status,
            PlanCode = paymentOrder.Plan.Code
        };
    }
}
