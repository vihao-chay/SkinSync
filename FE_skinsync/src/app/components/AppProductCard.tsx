import { ImageIcon } from "lucide-react";
import { Link } from "react-router";
import { Button } from "./ui/button";
import { Card, CardContent } from "./ui/card";
import type { ProductDetail } from "../services/productService";

export function AppProductVisual({ product, large = false }: { product: ProductDetail; large?: boolean }) {
  return (
    <div className={`overflow-hidden rounded-[28px] border border-border/60 bg-muted ${large ? "h-[320px]" : "h-52"}`}>
      {product.imageUrl ? (
        <img src={product.imageUrl} alt={product.name} className="h-full w-full object-cover" />
      ) : (
        <div className="flex h-full flex-col items-center justify-center gap-3 text-muted-foreground">
          <ImageIcon className="h-8 w-8" />
          <p className="text-sm">No image</p>
        </div>
      )}
    </div>
  );
}

export function AppProductCard({
  product,
  compact = false,
}: {
  product: ProductDetail;
  compact?: boolean;
}) {
  return (
    <Card className="app-surface rounded-[28px]">
      <CardContent className="space-y-4 pt-6">
        <AppProductVisual product={product} />
        <div className="space-y-2">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0">
              <p className="truncate text-base font-medium text-foreground">{product.name}</p>
              <p className="text-sm text-muted-foreground">{product.brand || "Brand unavailable"}</p>
            </div>
            {product.status?.toLowerCase() === "active" ? (
              <span className="app-pill">Active</span>
            ) : null}
          </div>
          <p className="text-sm text-foreground">{product.category || "Category unavailable"}</p>
          {!compact ? (
            <p className="line-clamp-3 text-sm leading-6 text-muted-foreground">
              {product.description || "Description unavailable."}
            </p>
          ) : null}
          <div className="flex flex-wrap gap-2">
            {(product.suitableSkinTypes || []).slice(0, 2).map((item) => (
              <span key={item} className="app-pill">
                {item}
              </span>
            ))}
            {(product.skinConcerns || []).slice(0, 2).map((item) => (
              <span key={item} className="app-pill">
                {item}
              </span>
            ))}
            {product.rating ? <span className="app-pill">Rating {product.rating}</span> : null}
          </div>
        </div>
        <Button asChild className="w-full bg-primary text-primary-foreground hover:bg-primary/90">
          <Link to={`/app/products/${product.id}`}>View details</Link>
        </Button>
      </CardContent>
    </Card>
  );
}
