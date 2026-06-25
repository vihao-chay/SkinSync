import { useEffect, useState } from "react";
import { Link } from "react-router";
import { AppEmptyState } from "../../components/AppEmptyState";
import { AppPageHeader } from "../../components/AppPageHeader";
import { AppProgressTimeline } from "../../components/AppProgressTimeline";
import { AppSection } from "../../components/AppSection";
import { AppStatCard } from "../../components/AppStatCard";
import { AppUploadZone } from "../../components/AppUploadZone";
import { Button } from "../../components/ui/button";
import { LoadingState } from "../../components/LoadingState";
import { IMAGE_TYPES, MAX_FILE_SIZE } from "../../constants/appShell";
import {
  getSkinProgressOverviewApi,
  getSkinProgressTimelineApi,
  uploadSkinProgressPhotoApi,
  type SkinProgressOverview,
  type SkinProgressTimelineEntry,
} from "../../services/skinProgressService";
import { formatDate } from "../../utils/appFormat";

export function AppProgressPage() {
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [feedback, setFeedback] = useState("");
  const [overview, setOverview] = useState<SkinProgressOverview | null>(null);
  const [timeline, setTimeline] = useState<SkinProgressTimelineEntry[]>([]);
  const [file, setFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);

  async function reload() {
    const [overviewResult, timelineResult] = await Promise.all([getSkinProgressOverviewApi(), getSkinProgressTimelineApi()]);
    setOverview(overviewResult.content ?? null);
    setTimeline(timelineResult.content ?? []);
    setLoading(false);
  }

  useEffect(() => {
    void reload();
  }, []);

  useEffect(() => {
    if (!file) {
      setPreviewUrl(null);
      return;
    }
    const url = URL.createObjectURL(file);
    setPreviewUrl(url);
    return () => URL.revokeObjectURL(url);
  }, [file]);

  if (loading) {
    return <LoadingState label="Loading your progress timeline..." />;
  }

  return (
    <div className="space-y-6">
      <AppPageHeader
        eyebrow="Progress"
        title="Visual timeline"
        description="Track changes over time with real uploaded photos and backend timeline entries, never fake before-and-after content."
      />

      <AppSection title="Upload progress photo" description="Add a new progress photo to extend your timeline.">
        <div className="space-y-4">
          <AppUploadZone
            title="Upload a progress photo"
            description="Choose a clear photo from the same angle when possible to make timeline review more meaningful."
            file={file}
            previewUrl={previewUrl}
            accept={IMAGE_TYPES.join(",")}
            helper="JPEG, PNG, WEBP · up to 5 MB"
            onPick={(nextFile) => {
              setFeedback("");
              if (!nextFile) {
                setFile(null);
                return;
              }
              if (!IMAGE_TYPES.includes(nextFile.type)) {
                setFeedback("Please choose a JPEG, PNG, or WEBP image.");
                return;
              }
              if (nextFile.size > MAX_FILE_SIZE) {
                setFeedback("Please choose an image smaller than 5 MB.");
                return;
              }
              setFile(nextFile);
            }}
          />
          <div className="flex flex-wrap gap-3">
            <Button
              className="bg-primary text-primary-foreground hover:bg-primary/90"
              disabled={!file || uploading}
              onClick={async () => {
                if (!file) return;
                setUploading(true);
                const result = await uploadSkinProgressPhotoApi(file);
                setUploading(false);
                setFeedback(result.message || (result.success ? "Progress photo uploaded." : "Unable to upload progress photo."));
                if (result.success) {
                  setFile(null);
                  await reload();
                }
              }}
            >
              {uploading ? "Uploading..." : "Upload progress photo"}
            </Button>
            {feedback ? <p className="self-center text-sm text-muted-foreground">{feedback}</p> : null}
          </div>
        </div>
      </AppSection>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <AppStatCard label="Total photos" value={`${overview?.totalEntries ?? 0}`} helper="Uploaded progress entries" />
        <AppStatCard label="Current streak" value={`${overview?.currentStreak ?? 0} days`} helper="Consistent tracking streak" />
        <AppStatCard label="Last upload" value={timeline[0] ? formatDate(timeline[0].createdAt) : "Not yet"} helper="Most recent progress entry" />
        <AppStatCard label="Latest report" value={timeline[0]?.status || "Unavailable"} helper={overview?.trendSummary || "Timeline summary unavailable"} />
      </div>

      <AppSection title="Progress timeline" description="Date-based entries with thumbnails, notes, and summary when available from the backend.">
        {timeline.length ? (
          <AppProgressTimeline entries={timeline} />
        ) : (
          <AppEmptyState
            title="No progress entries yet"
            description="Upload your first progress photo to start building a visible timeline."
            action={
              <Button asChild className="bg-primary text-primary-foreground hover:bg-primary/90">
                <Link to="/app/progress">Upload first photo</Link>
              </Button>
            }
          />
        )}
      </AppSection>
    </div>
  );
}
