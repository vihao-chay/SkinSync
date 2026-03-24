using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace SkinAsync.Helpers;

public class SwaggerIdHeaderOperationFilter : IOperationFilter
{
    public void Apply(OpenApiOperation operation, OperationFilterContext context)
    {
        var relativePath = context.ApiDescription.RelativePath ?? string.Empty;
        if (relativePath.StartsWith("api/auth", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        operation.Parameters ??= new List<OpenApiParameter>();
        var hasIdHeader = operation.Parameters.Any(p =>
            p.In == ParameterLocation.Header &&
            p.Name.Equals("Id", StringComparison.OrdinalIgnoreCase));

        if (hasIdHeader)
        {
            return;
        }

        operation.Parameters.Add(new OpenApiParameter
        {
            Name = "Id",
            In = ParameterLocation.Header,
            Description = "Current user Id (GUID)",
            Required = false,
            Schema = new OpenApiSchema
            {
                Type = "string",
                Format = "uuid"
            }
        });
    }
}
