using System.Data;
using System.IO;
using System.Net.Sockets;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using SkinSync.Data;
using SkinSync.Models.Dtos.Health;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/health")]
public class HealthController : ControllerBase
{
    private const string ProviderName = "PostgreSQL";
    private static readonly TimeSpan DatabaseHealthTimeout = TimeSpan.FromSeconds(5);

    private readonly AppDbContext _dbContext;
    private readonly ILogger<HealthController> _logger;

    public HealthController(AppDbContext dbContext, ILogger<HealthController> logger)
    {
        _dbContext = dbContext;
        _logger = logger;
    }

    [AllowAnonymous]
    [HttpGet]
    [ProducesResponseType(typeof(HealthStatusResponseDto), StatusCodes.Status200OK)]
    public IActionResult ServiceHealth()
    {
        return Ok(new HealthStatusResponseDto
        {
            Status = "Healthy",
            Service = "SkinSync Backend",
            Timestamp = DateTime.UtcNow
        });
    }

    [AllowAnonymous]
    [HttpGet("database")]
    [ProducesResponseType(typeof(HealthStatusResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(HealthStatusResponseDto), StatusCodes.Status503ServiceUnavailable)]
    public async Task<IActionResult> DatabaseHealth(CancellationToken cancellationToken)
    {
        using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeoutCts.CancelAfter(DatabaseHealthTimeout);

        try
        {
            await _dbContext.Database.OpenConnectionAsync(timeoutCts.Token);
            try
            {
                var connection = _dbContext.Database.GetDbConnection();
                await using var command = connection.CreateCommand();
                command.CommandText = "SELECT 1";
                command.CommandType = CommandType.Text;
                await command.ExecuteScalarAsync(timeoutCts.Token);
            }
            finally
            {
                await _dbContext.Database.CloseConnectionAsync();
            }

            return Ok(BuildDatabaseResponse(
                status: "Healthy",
                database: "Connected"));
        }
        catch (OperationCanceledException ex) when (!cancellationToken.IsCancellationRequested)
        {
            _logger.LogWarning(ex, "Database health check timed out.");
            return StatusCode(StatusCodes.Status503ServiceUnavailable, BuildDatabaseResponse(
                status: "Unhealthy",
                database: "Disconnected",
                error: "Database timeout"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Database health check failed.");
            return StatusCode(StatusCodes.Status503ServiceUnavailable, BuildDatabaseResponse(
                status: "Unhealthy",
                database: "Disconnected",
                error: MapDatabaseError(ex)));
        }
    }

    private static HealthStatusResponseDto BuildDatabaseResponse(string status, string database, string? error = null)
    {
        return new HealthStatusResponseDto
        {
            Status = status,
            Database = database,
            Provider = ProviderName,
            Error = error,
            Timestamp = DateTime.UtcNow
        };
    }

    private static string MapDatabaseError(Exception exception)
    {
        for (Exception? current = exception; current is not null; current = current.InnerException)
        {
            if (IsPoolExhausted(current))
            {
                return "Database pool exhausted";
            }

            if (current is TimeoutException || current is OperationCanceledException)
            {
                return "Database timeout";
            }

            if (current is SocketException || current is IOException)
            {
                return "Database unavailable";
            }

            if (current is PostgresException postgresException)
            {
                if (postgresException.SqlState == PostgresErrorCodes.ConnectionException ||
                    postgresException.SqlState == PostgresErrorCodes.ConnectionDoesNotExist ||
                    postgresException.SqlState == PostgresErrorCodes.SqlClientUnableToEstablishSqlConnection ||
                    postgresException.SqlState == PostgresErrorCodes.SqlServerRejectedEstablishmentOfSqlConnection)
                {
                    return "Database unavailable";
                }

                return "Database connection failed";
            }

            if (current is NpgsqlException || current is DbUpdateException)
            {
                return "Database connection failed";
            }
        }

        return "Database unavailable";
    }

    private static bool IsPoolExhausted(Exception exception)
    {
        if (exception is not PostgresException and not NpgsqlException)
        {
            return false;
        }

        var message = exception.Message;
        return message.Contains("ECHECKOUTTIMEOUT", StringComparison.OrdinalIgnoreCase) ||
               message.Contains("unable to check out connection from the pool", StringComparison.OrdinalIgnoreCase) ||
               message.Contains("pool exhausted", StringComparison.OrdinalIgnoreCase);
    }
}
