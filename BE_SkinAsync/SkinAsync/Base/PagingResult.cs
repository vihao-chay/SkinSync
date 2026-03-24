using System;
using System.Collections.Generic;

namespace SkinAsync.Base;

public class PagingResult<T>
{
    public IReadOnlyCollection<T> Items { get; set; } = Array.Empty<T>();
    public string? Search { get; set; }
    public string SortBy { get; set; } = string.Empty;
    public string SortDirection { get; set; } = string.Empty;
    public Dictionary<string, string?> Filters { get; set; } = new();
    public int PageSize { get; set; }
    public int PageIndex { get; set; }
    public int TotalRow { get; set; }
    public int TotalPages => PageSize > 0 ? (int)Math.Ceiling((double)TotalRow / PageSize) : 0;
}