using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace SkinSync.Helpers;

public class SwaggerIdHeaderOperationFilter : IOperationFilter
{
    public void Apply(OpenApiOperation operation, OperationFilterContext context)
    {
        // User identity is resolved from JWT subject claim; no custom Id header is required.
    }
}
