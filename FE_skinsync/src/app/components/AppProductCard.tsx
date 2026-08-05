import { Heart, ImageIcon, Star } from "lucide-react";
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
        <div className="flex h-full flex-col items-center justify-center gap-3 bg-[linear-gradient(135deg,rgba(255,253,248,0.95),rgba(243,231,214,0.95))] text-muted-foreground">
          <ImageIcon className="h-8 w-8" />
          <p className="text-sm">Image unavailable</p>
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
    <Card className="app-surface rounded-[28px] overflow-hidden">
      <CardContent className="space-y-4 pt-6">
        <div className="relative"><AppProductVisual product={product} /><button type="button" aria-label={`Save ${product.name}`} className="absolute right-3 top-3 flex h-9 w-9 items-center justify-center rounded-full border border-white/70 bg-white/85 text-[#977b56] shadow-sm transition hover:scale-105"><Heart className="h-4 w-4" /></button></div>
        <div className="space-y-2">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0">
              <p className="truncate text-base font-semibold text-foreground">{product.name}</p>
              <p className="text-sm text-muted-foreground">{product.brand || "Brand unavailable"}</p>
            </div>
            <span className="app-pill">{product.status?.toLowerCase() === "active" ? "Verified catalog" : "Limited"}</span>
          </div>
              <div className="flex items-center gap-2"><p className="text-sm font-medium text-foreground">{product.category || "Category unavailable"}</p>{product.rating ? <span className="inline-flex items-center gap-1 text-xs text-[#977b56]"><Star className="h-3 w-3 fill-current" />{product.rating}</span> : null}</div>
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
            {product.usageTime ? <span className="app-pill">{product.usageTime}</span> : null}
          </div>
        </div>
          <Button asChild className="w-full bg-primary text-primary-foreground hover:bg-primary/90">
          <Link to={`/app/products/${product.id}`}>Quick view</Link>
        </Button>
      </CardContent>
    </Card>
  );
}
