import { ArrowRight, Filter, Search, Sparkles } from "lucide-react";
import { Link } from "react-router";
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
        title="Explore Products"
        description="Discover considered skincare essentials and learn which ingredients support your skin goals."
      />

      <section className="rounded-[28px] border border-[#ded3c3] bg-[linear-gradient(120deg,#222,#4a4034_58%,#9a7b55)] p-6 text-white shadow-[0_18px_40px_rgba(70,55,39,0.16)] sm:p-8">
        <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between"><div><p className="flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.2em] text-[#e8d5b7]"><Sparkles className="h-4 w-4" />Curated for your journey</p><h2 className="mt-2 text-3xl font-semibold tracking-[-0.04em] text-white">Recommended For You</h2><p className="mt-2 max-w-xl text-sm leading-6 text-white/70">Start with a few essentials selected from the SkinSync catalog. Explore, compare, and build a routine that feels effortless.</p></div><Link to="/app/recommendations" className="inline-flex items-center gap-2 text-sm font-semibold text-[#f1d49f]">See AI recommendations<ArrowRight className="h-4 w-4" /></Link></div>
        {products.length ? <div className="mt-6 grid gap-3 md:grid-cols-3">{products.slice(0, 3).map((product) => <Link key={product.id} to={`/app/products/${product.id}`} className="group flex items-center gap-3 rounded-2xl border border-white/15 bg-white/10 p-3 backdrop-blur-sm transition hover:-translate-y-1 hover:bg-white/15"><div className="h-16 w-16 shrink-0 overflow-hidden rounded-xl bg-white/15">{product.imageUrl ? <img src={product.imageUrl} alt={product.name} className="h-full w-full object-cover" /> : <div className="flex h-full items-center justify-center"><Sparkles className="h-5 w-5 text-[#e8d5b7]" /></div>}</div><div className="min-w-0"><p className="truncate text-sm font-semibold text-white">{product.name}</p><p className="mt-1 text-xs text-white/60">{product.brand || product.category}</p></div></Link>)}</div> : null}
      </section>

      <AppSection title="Find your next essential" description="Search by product name, brand, or skin concern.">
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
