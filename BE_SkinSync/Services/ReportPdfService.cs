using System.Text;
using SkinSync.Models.Dtos.AI;

namespace SkinSync.Services;

public interface IReportPdfService
{
    byte[] BuildSkinProgressReportPdf(SkinProgressReportResponseDto report);
}

public class ReportPdfService : IReportPdfService
{
    public byte[] BuildSkinProgressReportPdf(SkinProgressReportResponseDto report)
    {
        var lines = BuildLines(report)
            .SelectMany(x => Wrap(Sanitize(x), 92))
            .ToList();
        var pages = lines.Chunk(36).Select(x => x.ToList()).ToList();
        if (pages.Count == 0)
        {
            pages.Add(["No report content."]);
        }

        var fontObjectId = 3 + pages.Count * 2;
        var kids = string.Join(" ", Enumerable.Range(0, pages.Count).Select(i => $"{3 + i * 2} 0 R"));
        var objects = new List<string>
        {
            "<< /Type /Catalog /Pages 2 0 R >>",
            $"<< /Type /Pages /Kids [{kids}] /Count {pages.Count} >>"
        };

        for (var i = 0; i < pages.Count; i++)
        {
            var pageObjectId = 3 + i * 2;
            var contentObjectId = pageObjectId + 1;
            var content = BuildPageContent(pages[i]);
            var contentLength = Encoding.ASCII.GetByteCount(content);

            objects.Add($"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 {fontObjectId} 0 R >> >> /Contents {contentObjectId} 0 R >>");
            objects.Add($"<< /Length {contentLength} >>\nstream\n{content}\nendstream");
        }

        objects.Add("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>");

        var builder = new StringBuilder();
        var offsets = new List<int> { 0 };
        builder.Append("%PDF-1.4\n");
        for (var i = 0; i < objects.Count; i++)
        {
            offsets.Add(Encoding.ASCII.GetByteCount(builder.ToString()));
            builder.Append(i + 1).Append(" 0 obj\n");
            builder.Append(objects[i]).Append("\n");
            builder.Append("endobj\n");
        }

        var xrefOffset = Encoding.ASCII.GetByteCount(builder.ToString());
        builder.Append("xref\n");
        builder.Append("0 ").Append(objects.Count + 1).Append('\n');
        builder.Append("0000000000 65535 f \n");
        foreach (var offset in offsets.Skip(1))
        {
            builder.Append(offset.ToString("D10")).Append(" 00000 n \n");
        }

        builder.Append("trailer\n");
        builder.Append("<< /Size ").Append(objects.Count + 1).Append(" /Root 1 0 R >>\n");
        builder.Append("startxref\n");
        builder.Append(xrefOffset).Append('\n');
        builder.Append("%%EOF");

        return Encoding.ASCII.GetBytes(builder.ToString());
    }

    private static IEnumerable<string> BuildLines(SkinProgressReportResponseDto report)
    {
        yield return "SkinSync Progress Report";
        yield return $"Report: {report.ReportCategory} / {report.PeriodType ?? "custom"}";
        if (report.PeriodStart.HasValue || report.PeriodEnd.HasValue)
        {
            yield return $"Period: {report.PeriodStart:yyyy-MM-dd} to {report.PeriodEnd:yyyy-MM-dd}";
        }
        yield return $"Status: {report.ProgressStatus}";
        yield return $"Created: {report.CreatedAt:yyyy-MM-dd HH:mm} UTC";
        yield return "";
        yield return "Summary";
        yield return report.Summary;

        if (report.MainFindings.Count > 0)
        {
            yield return "";
            yield return "Main Findings";
            foreach (var item in report.MainFindings)
            {
                yield return $"- {item}";
            }
        }

        if (!string.IsNullOrWhiteSpace(report.RoutineFeedback))
        {
            yield return "";
            yield return "Routine Feedback";
            yield return report.RoutineFeedback!;
        }

        if (!string.IsNullOrWhiteSpace(report.ProductFeedback))
        {
            yield return "";
            yield return "Product Feedback";
            yield return report.ProductFeedback!;
        }

        if (report.NextSuggestions.Count > 0)
        {
            yield return "";
            yield return "Next Suggestions";
            foreach (var item in report.NextSuggestions)
            {
                yield return $"- {item}";
            }
        }
    }

    private static string BuildPageContent(IReadOnlyCollection<string> lines)
    {
        var builder = new StringBuilder();
        builder.Append("BT\n");
        builder.Append("/F1 12 Tf\n");
        builder.Append("50 760 Td\n");
        builder.Append("16 TL\n");

        var index = 0;
        foreach (var line in lines)
        {
            if (index == 0)
            {
                builder.Append('(').Append(EscapePdf(line)).Append(") Tj\n");
            }
            else
            {
                builder.Append("T*\n");
                builder.Append('(').Append(EscapePdf(line)).Append(") Tj\n");
            }

            index++;
        }

        builder.Append("ET");
        return builder.ToString();
    }

    private static IEnumerable<string> Wrap(string value, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            yield return "";
            yield break;
        }

        var words = value.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        var line = new StringBuilder();
        foreach (var word in words)
        {
            if (line.Length > 0 && line.Length + word.Length + 1 > maxLength)
            {
                yield return line.ToString();
                line.Clear();
            }

            if (line.Length > 0)
            {
                line.Append(' ');
            }

            line.Append(word);
        }

        if (line.Length > 0)
        {
            yield return line.ToString();
        }
    }

    private static string Sanitize(string value)
    {
        var builder = new StringBuilder(value.Length);
        foreach (var ch in value)
        {
            builder.Append(ch is >= ' ' and <= '~' ? ch : '?');
        }

        return builder.ToString();
    }

    private static string EscapePdf(string value) =>
        value.Replace("\\", "\\\\").Replace("(", "\\(").Replace(")", "\\)");
}
