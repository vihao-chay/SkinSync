import logoSrc from "../img/logo.jpg";

interface BrandLogoProps {
  className?: string;
  imageClassName?: string;
  alt?: string;
}

export function BrandLogo({
  className = "",
  imageClassName = "",
  alt = "SkinSync logo",
}: BrandLogoProps) {
  return (
    <span
      className={`inline-flex items-center justify-center overflow-hidden bg-[#fbf6ef] ${className}`}
      aria-hidden={alt ? undefined : true}
    >
      <img
        src={logoSrc}
        alt={alt}
        className={`w-full h-full object-cover ${imageClassName}`}
        draggable={false}
      />
    </span>
  );
}
