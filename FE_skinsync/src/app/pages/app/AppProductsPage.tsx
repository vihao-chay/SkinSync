import { Filter, Search } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { AppEmptyState } from "../../components/AppEmptyState";
import { AppField } from "../../components/AppField";
import { AppPageHeader } from "../../components/AppPageHeader";
import { AppProductCard } from "../../components/AppProductCard";
import { AppSection } from "../../components/AppSection";
import { LoadingState } from "../../components/LoadingState";
import { getProductsApi, type ProductDetail } from "../../services/productService";

export function AppProductsPage() {
  const [loading, setLoading] = useState(true);
  const [products, setProducts] = useState<ProductDetail[]>([]);
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("all");
  const [skinType, setSkinType] = useState("all");
  const [concern, setConcern] = useState("all");
  const [sort, setSort] = useState("name");

  useEffect(() => {
    let active = true;
    void getProductsApi().then((result) => {
      if (!active) return;
      setProducts((result.content ?? []).filter((item) => item.status?.toLowerCase() === "active"));
      setLoading(false);
    });
    return () => {
      active = false;
    };
  }, []);

  const categories = useMemo(
    () => ["all", ...new Set(products.map((item) => item.category).filter(Boolean))],
    [products]
  );
  const skinTypes = useMemo(
    () => ["all", ...new Set(products.flatMap((item) => item.suitableSkinTypes || []).filter(Boolean))],
    [products]
  );
  const concerns = useMemo(
    () => ["all", ...new Set(products.flatMap((item) => item.skinConcerns || []).filter(Boolean))],
    [products]
  );

  const filteredProducts = useMemo(() => {
    const normalizedSearch = search.trim().toLowerCase();
    const items = products.filter((product) => {
      const searchMatch =
        !normalizedSearch ||
        product.name.toLowerCase().includes(normalizedSearch) ||
        product.brand?.toLowerCase().includes(normalizedSearch);
      const categoryMatch = category === "all" || product.category === category;
      const skinTypeMatch = skinType === "all" || product.suitableSkinTypes?.includes(skinType);
      const concernMatch = concern === "all" || product.skinConcerns?.includes(concern);
      return searchMatch && categoryMatch && skinTypeMatch && concernMatch;
    });

    return [...items].sort((a, b) => {
      if (sort === "brand") return (a.brand || "").localeCompare(b.brand || "");
      if (sort === "category") return (a.category || "").localeCompare(b.category || "");
      return a.name.localeCompare(b.name);
    });
  }, [category, concern, products, search, skinType, sort]);

  if (loading) {
    return <LoadingState label="Loading product catalog..." />;
  }

  return (
    <div className="space-y-6">
      <AppPageHeader
        eyebrow="Catalog"
        title="Products"
        description="Browse the backend product catalog. Products are only described as recommendations if recommendation data is actually returned."
      />

      <AppSection title="Search and filter" description="Filter by current backend product fields without inventing personalization.">
        <div className="grid gap-4 lg:grid-cols-5">
          <AppField label="Search">
            <div className="relative">
              <Search className="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <input
                className="app-input pl-10"
                placeholder="Search by name or brand"
                value={search}
                onChange={(event) => setSearch(event.target.value)}
              />
            </div>
          </AppField>
          <SelectField label="Category" value={category} options={categories} onChange={setCategory} />
          <SelectField label="Skin type" value={skinType} options={skinTypes} onChange={setSkinType} />
          <SelectField label="Concern" value={concern} options={concerns} onChange={setConcern} />
          <SelectField label="Sort" value={sort} options={["name", "brand", "category"]} onChange={setSort} />
        </div>
        <div className="mt-4 flex items-center gap-2 text-sm text-muted-foreground">
          <Filter className="h-4 w-4" />
          Showing active catalog products only.
        </div>
      </AppSection>

      <AppSection
        title="Product catalog"
        description={filteredProducts.length ? `${filteredProducts.length} products found` : "No products match the current filters."}
      >
        {filteredProducts.length ? (
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {filteredProducts.map((product) => (
              <AppProductCard key={product.id} product={product} />
            ))}
          </div>
        ) : (
          <AppEmptyState
            title="No matching products"
            description="Try adjusting the search term or filters. SkinSync keeps the empty state explicit instead of filling the grid with fake items."
          />
        )}
      </AppSection>
    </div>
  );
}

function SelectField({
  label,
  value,
  options,
  onChange,
}: {
  label: string;
  value: string;
  options: string[];
  onChange: (value: string) => void;
}) {
  return (
    <AppField label={label}>
      <select className="app-input" value={value} onChange={(event) => onChange(event.target.value)}>
        {options.map((option) => (
          <option key={option} value={option}>
            {option === "all" ? "All" : option}
          </option>
        ))}
      </select>
    </AppField>
  );
}
