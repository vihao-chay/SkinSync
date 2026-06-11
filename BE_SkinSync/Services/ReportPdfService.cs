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
        var lines = BuildLines(report).Take(52).ToList();
        var content = BuildContentStream(lines);
        var objects = new List<string>
        {
            "<< /Type /Catalog /Pages 2 0 R >>",
            "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
            "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
            "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
            $"<< /Length {Encoding.ASCII.GetByteCount(content)} >>\nstream\n{content}\nendstream"
        };

        return BuildPdf(objects);
    }

    private static IEnumerable<string> BuildLines(SkinProgressReportResponseDto report)
    {
        yield return "SkinSync Progress Report";
        yield return $"Type: {report.PeriodType}";
        yield return $"Period: {report.PeriodStart:yyyy-MM-dd} to {report.PeriodEnd:yyyy-MM-dd}";
        yield return $"Status: {report.ProgressStatus}";
        yield return $"Created: {report.CreatedAt:yyyy-MM-dd HH:mm} UTC";
        yield return string.Empty;
        yield return "Summary";
        foreach (var line in Wrap(report.Summary, 88))
        {
            yield return line;
        }

        yield return string.Empty;
        yield return "Score Changes";
        yield return $"Acne: {report.ScoreChanges.AcneScoreChange}, Redness: {report.ScoreChanges.RednessScoreChange}, Dark spots: {report.ScoreChanges.DarkSpotScoreChange}";
        yield return $"Oiliness: {report.ScoreChanges.OilinessScoreChange}, Dryness: {report.ScoreChanges.DrynessScoreChange}, Texture: {report.ScoreChanges.TextureScoreChange}";
        yield return $"Sensitivity: {report.ScoreChanges.SensitivityScoreChange}, Overall: {report.ScoreChanges.OverallScoreChange}";

        yield return string.Empty;
        yield return "Main Findings";
        foreach (var item in report.MainFindings.SelectMany(x => Wrap($"- {x}", 88)))
        {
            yield return item;
        }

        if (!string.IsNullOrWhiteSpace(report.RoutineFeedback))
        {
            yield return string.Empty;
            yield return "Routine Feedback";
            foreach (var line in Wrap(report.RoutineFeedback, 88))
            {
                yield return line;
            }
        }

        yield return string.Empty;
        yield return "Next Suggestions";
        foreach (var item in report.NextSuggestions.SelectMany(x => Wrap($"- {x}", 88)))
        {
            yield return item;
        }
    }

    private static IEnumerable<string> Wrap(string? text, int width)
    {
        var normalized = Sanitize(text);
        if (string.IsNullOrWhiteSpace(normalized))
        {
            yield break;
        }

        var words = normalized.Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        var line = new StringBuilder();
        foreach (var word in words)
        {
            if (line.Length > 0 && line.Length + word.Length + 1 > width)
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

    private static string BuildContentStream(IReadOnlyCollection<string> lines)
    {
        var builder = new StringBuilder();
        var y = 752;
        foreach (var line in lines)
        {
            var fontSize = line == "SkinSync Progress Report" ? 18 : 10;
            builder.Append("BT /F1 ");
            builder.Append(fontSize);
            builder.Append(" Tf 50 ");
            builder.Append(y);
            builder.Append(" Td (");
            builder.Append(EscapePdfString(line));
            builder.AppendLine(") Tj ET");
            y -= line == string.Empty ? 10 : 14;
        }

        return builder.ToString();
    }

    private static byte[] BuildPdf(IReadOnlyList<string> objects)
    {
        var builder = new StringBuilder();
        builder.AppendLine("%PDF-1.4");
        var offsets = new List<int> { 0 };
        foreach (var (value, index) in objects.Select((value, index) => (value, index)))
        {
            offsets.Add(Encoding.ASCII.GetByteCount(builder.ToString()));
            builder.Append(index + 1);
            builder.AppendLine(" 0 obj");
            builder.AppendLine(value);
            builder.AppendLine("endobj");
        }

        var xrefOffset = Encoding.ASCII.GetByteCount(builder.ToString());
        builder.AppendLine("xref");
        builder.Append("0 ");
        builder.AppendLine((objects.Count + 1).ToString());
        builder.AppendLine("0000000000 65535 f ");
        foreach (var offset in offsets.Skip(1))
        {
            builder.Append(offset.ToString("D10"));
            builder.AppendLine(" 00000 n ");
        }

        builder.AppendLine("trailer");
        builder.Append("<< /Size ");
        builder.Append(objects.Count + 1);
        builder.AppendLine(" /Root 1 0 R >>");
        builder.AppendLine("startxref");
        builder.AppendLine(xrefOffset.ToString());
        builder.AppendLine("%%EOF");

        return Encoding.ASCII.GetBytes(builder.ToString());
    }

    private static string Sanitize(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var builder = new StringBuilder(value.Length);
        foreach (var ch in value.ReplaceLineEndings(" "))
        {
            builder.Append(ch is >= ' ' and <= '~' ? ch : '?');
        }

        return builder.ToString();
    }

    private static string EscapePdfString(string value)
    {
        return Sanitize(value)
            .Replace("\\", "\\\\", StringComparison.Ordinal)
            .Replace("(", "\\(", StringComparison.Ordinal)
            .Replace(")", "\\)", StringComparison.Ordinal);
    }
}
