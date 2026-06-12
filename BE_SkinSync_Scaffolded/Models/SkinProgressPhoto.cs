using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class SkinProgressPhoto
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public string ImageUrl { get; set; } = null!;

    public string? ThumbnailUrl { get; set; }

    public DateOnly PhotoDate { get; set; }

    public string TimeOfDay { get; set; } = null!;

    public string LightingCondition { get; set; } = null!;

    public string FaceAngle { get; set; } = null!;

    public string? Note { get; set; }

    public DateTime CreatedAt { get; set; }

    public string Source { get; set; } = null!;

    public string? ImageMetadataJson { get; set; }

    public virtual ICollection<SkinPhotoComparison> SkinPhotoComparisonAfterPhotos { get; set; } = new List<SkinPhotoComparison>();

    public virtual ICollection<SkinPhotoComparison> SkinPhotoComparisonBeforePhotos { get; set; } = new List<SkinPhotoComparison>();

    public virtual SkinProgressAnalysis? SkinProgressAnalysis { get; set; }

    public virtual User1 User { get; set; } = null!;
}
