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
    public async Task<IActionResult> PayOsWebhook([FromBody] WebhookType? webhookData, CancellationToken cancellationToken)
    {
        if (webhookData == null)
        {
            return Ok(new
            {
                error = 0,
                message = "Ok",
                data = (object?)null
            });
        }

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

    [HttpGet("payos-webhook")]
    [AllowAnonymous]
    public IActionResult PayOsWebhookProbe()
    {
        return Ok(new
        {
            error = 0,
            message = "Ok",
            data = (object?)null
        });
    }

    [HttpGet("payos-return")]
    [AllowAnonymous]
    public ContentResult PayOsReturn()
    {
        return PaymentBrowserResult(
            "Thanh toán thành công",
            "SkinSync đã nhận giao dịch. Hãy quay lại ứng dụng để xem trạng thái gói của bạn.",
            "#566b2f",
            "skinsync://payment/success");
    }

    [HttpGet("payos-cancel")]
    [AllowAnonymous]
    public ContentResult PayOsCancel()
    {
        return PaymentBrowserResult(
            "Thanh toán đã hủy",
            "Bạn có thể quay lại SkinSync và chọn lại gói khi sẵn sàng.",
            "#9b6a45",
            "skinsync://payment/cancel");
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

    private static ContentResult PaymentBrowserResult(string title, string message, string accentColor, string mobileDeepLink)
    {
        var html = $$"""
            <!doctype html>
            <html lang="vi">
            <head>
              <meta charset="utf-8" />
              <meta name="viewport" content="width=device-width,initial-scale=1" />
              <title>{{title}}</title>
              <style>
                :root { color-scheme: light; }
                * { box-sizing: border-box; }
                body {
                  margin: 0;
                  min-height: 100vh;
                  display: grid;
                  place-items: center;
                  padding: 28px;
                  background: #f8f4ee;
                  color: #211d1a;
                  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
                }
                main {
                  width: min(420px, 100%);
                  padding: 28px 24px;
                  border-radius: 24px;
                  background: #fffdf9;
                  box-shadow: 0 20px 50px rgba(69, 54, 38, .12);
                  text-align: center;
                }
                .mark {
                  width: 64px;
                  height: 64px;
                  display: inline-grid;
                  place-items: center;
                  border-radius: 999px;
                  margin-bottom: 18px;
                  background: color-mix(in srgb, {{accentColor}} 18%, white);
                  color: {{accentColor}};
                  font-size: 34px;
                  font-weight: 800;
                }
                h1 {
                  margin: 0 0 10px;
                  font-size: 26px;
                  line-height: 1.15;
                }
                p {
                  margin: 0;
                  color: #6f7481;
                  font-size: 16px;
                  line-height: 1.5;
                }
                a {
                  display: inline-flex;
                  align-items: center;
                  justify-content: center;
                  min-height: 48px;
                  margin-top: 22px;
                  padding: 0 22px;
                  border-radius: 999px;
                  background: {{accentColor}};
                  color: #fff;
                  text-decoration: none;
                  font-weight: 800;
                }
              </style>
            </head>
            <body>
              <main>
                <div class="mark">✓</div>
                <h1>{{title}}</h1>
                <p>{{message}}</p>
                <a id="openApp" href="{{mobileDeepLink}}">Mở lại SkinSync</a>
              </main>
              <script>
                const deepLink = "{{mobileDeepLink}}";
                const query = window.location.search || "";
                const target = deepLink + query;
                document.getElementById("openApp").href = target;
                window.setTimeout(() => {
                  window.location.href = target;
                }, 600);
              </script>
            </body>
            </html>
            """;

        return new ContentResult
        {
            Content = html,
            ContentType = "text/html; charset=utf-8",
            StatusCode = 200
        };
    }
}
