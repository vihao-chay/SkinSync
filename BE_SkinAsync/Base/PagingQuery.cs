namespace SkinAsync.Base;

public class PagingQuery
{
    private const int DefaultPageSize = 10;
    private const int MaxPageSize = 100;

    private int _pageIndex = 1;
    private int _pageSize = DefaultPageSize;

    public string? Search { get; set; }
    public string? SortBy { get; set; }
    public string SortDirection { get; set; } = "desc";

    public int PageIndex
    {
        get => _pageIndex;
        set => _pageIndex = value < 1 ? 1 : value;
    }

    public int PageSize
    {
        get => _pageSize;
        set => _pageSize = value <= 0 ? DefaultPageSize : Math.Min(value, MaxPageSize);
    }
}
