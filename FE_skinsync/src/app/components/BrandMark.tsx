import logoImage from "../../img/logo.jpg";

interface BrandMarkProps {
  className?: string;
  imageClassName?: string;
  alt?: string;
}

export function BrandMark({
  className = "w-8 h-8 rounded-xl",
  imageClassName = "",
  alt = "SkinSync",
}: BrandMarkProps) {
  return (
    <span className={`inline-flex overflow-hidden bg-[#f7f1ea] shadow-sm ${className}`}>
      <img
        src={logoImage}
        alt={alt}
        className={`w-full h-full object-contain ${imageClassName}`}
      />
    </span>
  );
}
