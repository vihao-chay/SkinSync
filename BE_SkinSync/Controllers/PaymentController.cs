using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Net.payOS.Types;
using SkinSync.Base;
using SkinSync.Helpers;
using SkinSync.Models.Dtos.Payment;
using SkinSync.Services;
using SkinSync.Services.AIPlatform;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/payment")]
public class PaymentController : ControllerBase
{
    private readonly IPayOsPaymentService _paymentService;

    public PaymentController(IPayOsPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    [HttpPost("create-payment-link")]
    [Authorize]
    public async Task<ResponseEntity<PaymentLinkResponseDto>> CreatePaymentLink(
        [FromBody] CreatePaymentLinkRequestDto request,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<PaymentLinkResponseDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var result = await _paymentService.CreatePaymentLinkAsync(userId, request.PlanCode, cancellationToken);
            return ResponseEntity<PaymentLinkResponseDto>.Ok(result, "Tạo liên kết thanh toán thành công.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<PaymentLinkResponseDto>.Fail(ex.Message, ex.StatusCode);
        }
        catch (Exception ex)
        {
            return ResponseEntity<PaymentLinkResponseDto>.Fail(ex.Message, 500);
        }
    }

    [HttpPost("payos-webhook")]
    [AllowAnonymous]
    public async Task<IActionResult> PayOsWebhook([FromBody] WebhookType webhookData, CancellationToken cancellationToken)
    {
        var success = await _paymentService.HandleWebhookAsync(webhookData, cancellationToken);
        if (success)
        {
            return Ok(new
            {
                error = 0,
                message = "Ok",
                data = (object?)null
            });
        }
        
        return BadRequest(new
        {
            error = -1,
            message = "Failed to process webhook"
        });
    }

    [HttpGet("verify/{orderCode}")]
    [Authorize]
    public async Task<ResponseEntity<VerifyPaymentResponseDto>> VerifyPayment(
        [FromRoute] long orderCode,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await _paymentService.VerifyPaymentAsync(orderCode, cancellationToken);
            return ResponseEntity<VerifyPaymentResponseDto>.Ok(result, "Kiểm tra trạng thái đơn hàng thành công.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<VerifyPaymentResponseDto>.Fail(ex.Message, ex.StatusCode);
        }
        catch (Exception ex)
        {
            return ResponseEntity<VerifyPaymentResponseDto>.Fail(ex.Message, 500);
        }
    }
}
