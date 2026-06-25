using System;
using System.Threading;
using System.Threading.Tasks;
using SkinSync.Models.Dtos.Payment;
using Net.payOS.Types;

namespace SkinSync.Services;

public interface IPayOsPaymentService
{
    Task<PaymentLinkResponseDto> CreatePaymentLinkAsync(Guid userId, string planCode, CancellationToken cancellationToken);
    Task<bool> HandleWebhookAsync(WebhookType webhookData, CancellationToken cancellationToken);
    Task<VerifyPaymentResponseDto> VerifyPaymentAsync(long orderCode, CancellationToken cancellationToken);
}
