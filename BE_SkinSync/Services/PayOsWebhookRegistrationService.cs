using System.Reflection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Net.payOS;

namespace SkinSync.Services;

public class PayOsWebhookRegistrationService : BackgroundService
{
    private readonly PayOS _payOS;
    private readonly IConfiguration _configuration;
    private readonly ILogger<PayOsWebhookRegistrationService> _logger;

    public PayOsWebhookRegistrationService(
        PayOS payOS,
        IConfiguration configuration,
        ILogger<PayOsWebhookRegistrationService> logger)
    {
        _payOS = payOS;
        _configuration = configuration;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var webhookUrl = _configuration["PayOS:WebhookUrl"]?.Trim();
        if (string.IsNullOrWhiteSpace(webhookUrl))
        {
            return;
        }

        if (!Uri.TryCreate(webhookUrl, UriKind.Absolute, out var uri) ||
            (!string.Equals(uri.Scheme, Uri.UriSchemeHttp, StringComparison.OrdinalIgnoreCase) &&
             !string.Equals(uri.Scheme, Uri.UriSchemeHttps, StringComparison.OrdinalIgnoreCase)))
        {
            _logger.LogWarning("PayOS webhook URL must be an absolute HTTP or HTTPS URL. Current value was ignored.");
            return;
        }

        if (!string.Equals(uri.Scheme, Uri.UriSchemeHttps, StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogWarning("PayOS webhook URL is not HTTPS. Use a stable HTTPS URL for production if PayOS rejects this webhook.");
        }

        try
        {
            var method = _payOS.GetType().GetMethod(
                "confirmWebhook",
                BindingFlags.Instance | BindingFlags.Public,
                binder: null,
                types: [typeof(string)],
                modifiers: null);

            if (method == null)
            {
                _logger.LogWarning("PayOS package does not expose confirmWebhook(string). Configure the webhook URL manually in PayOS dashboard.");
                return;
            }

            var result = method.Invoke(_payOS, [webhookUrl]);
            if (result is Task task)
            {
                await task.WaitAsync(stoppingToken);
            }

            _logger.LogInformation("PayOS webhook URL confirmed successfully.");
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Application is shutting down.
        }
        catch (TargetInvocationException ex)
        {
            _logger.LogWarning(ex.InnerException ?? ex, "Could not confirm PayOS webhook URL automatically.");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not confirm PayOS webhook URL automatically.");
        }
    }
}
