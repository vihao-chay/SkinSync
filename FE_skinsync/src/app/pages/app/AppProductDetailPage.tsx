import { useEffect, useState } from "react";
import { Link, useParams } from "react-router";
import { AppEmptyState } from "../../components/AppEmptyState";
import { AppPageHeader } from "../../components/AppPageHeader";
import { AppProductVisual } from "../../components/AppProductCard";
import { AppSection } from "../../components/AppSection";
import { Button } from "../../components/ui/button";
import { ErrorState } from "../../components/ErrorState";
import { LoadingState } from "../../components/LoadingState";
import { getProductDetailApi, type ProductDetail } from "../../services/productService";

export function AppProductDetailPage() {
  const { id } = useParams();
  const [loading, setLoading] = useState(true);
  const [product, setProduct] = useState<ProductDetail | null>(null);

  useEffect(() => {
    if (!id) return;
    let active = true;
    void getProductDetailApi(id).then((result) => {
      if (!active) return;
      setProduct(result.content ?? null);
      setLoading(false);
    });
    return () => {
      active = false;
    };
  }, [id]);

  if (loading) {
    return <LoadingState label="Loading product details..." />;
  }

  if (!product) {
    return <ErrorState message="Unable to load this product." />;
  }

  return (
    <div className="space-y-6">
      <AppPageHeader
        eyebrow="Product detail"
        title={product.name}
        description={`${product.brand || "Brand unavailable"} · ${product.category || "Category unavailable"}`}
        actions={
          <Button asChild variant="outline" className="border-border bg-card hover:bg-muted">
            <Link to="/app/products">Back to products</Link>
          </Button>
        }
      />

      <div className="grid gap-4 xl:grid-cols-[0.92fr_1.08fr]">
        <AppSection title="Overview" description="Product information returned by the backend catalog.">
          <AppProductVisual product={product} large />
        </AppSection>

        <AppSection title="Details" description="SkinSync keeps null backend fields explicit instead of leaving broken empty gaps.">
          <div className="grid gap-3">
            <DetailRow label="Description" value={product.description || "Description unavailable"} />
            <DetailRow label="Ingredients" value={product.ingredient || product.ingredients?.join(", ") || "Ingredients unavailable"} />
            <DetailRow label="How to use" value={product.howToUse || product.usageGuide || "How to use unavailable"} />
            <DetailRow label="Usage time" value={product.usageTime || "Usage time unavailable"} />
            <DetailRow label="Suitable for" value={product.suitableSkinTypes?.join(", ") || "Suitable skin types unavailable"} />
            <DetailRow label="Skin concerns" value={product.skinConcerns?.join(", ") || "Skin concerns unavailable"} />
            <DetailRow
              label="Price / source"
              value={product.price ? `${product.price} ${product.currency}` : "Price unavailable"}
            />
            <DetailRow label="Status" value={product.status || "Unavailable"} />
          </div>
        </AppSection>
      </div>

      <AppSection title="Safety and compatibility" description="Show available compatibility notes without generating unverified claims.">
        {product.cautions?.length || product.conflicts?.length || product.keyIngredients?.length ? (
          <div className="grid gap-3 md:grid-cols-3">
            <DetailRow label="Key ingredients" value={product.keyIngredients?.join(", ") || "Unavailable"} />
            <DetailRow label="Cautions" value={product.cautions?.join(", ") || "Unavailable"} />
            <DetailRow label="Conflicts" value={product.conflicts?.join(", ") || "Unavailable"} />
          </div>
        ) : (
          <AppEmptyState
            title="No additional compatibility data"
            description="This product does not currently expose extra ingredient conflict metadata from the backend."
          />
        )}
      </AppSection>
    </div>
  );
}

function DetailRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl border border-border/60 bg-muted/70 px-4 py-3">
      <p className="text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground">{label}</p>
      <p className="mt-1 text-sm leading-6 text-foreground">{value}</p>
    </div>
  );
}
