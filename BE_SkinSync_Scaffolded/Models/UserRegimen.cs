using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class UserRegimen
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public DateOnly StartDate { get; set; }

    public DateOnly? EndDate { get; set; }

    public bool IsActive { get; set; }

    public bool IsCustom { get; set; }

    public string Name { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public string Source { get; set; } = null!;

    public DateTime? UpdatedAt { get; set; }

    public Guid? SourceAnalysisId { get; set; }

    public virtual ICollection<RegimenItem> RegimenItems { get; set; } = new List<RegimenItem>();

    public virtual SkinProgressAnalysis? SourceAnalysis { get; set; }

    public virtual User1 User { get; set; } = null!;
}
