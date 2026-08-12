interface PageHeaderProps {
  eyebrow?: string;
  title: string;
  description?: string;
  actions?: React.ReactNode;
}

export function PageHeader({ eyebrow, title, description, actions }: PageHeaderProps) {
  return (
    <div className="flex flex-col gap-4 border-b border-[#e8d5b7]/60 pb-5 md:flex-row md:items-end md:justify-between">
      <div>
        {eyebrow ? (
          <div className="mb-2 inline-flex rounded-full bg-[#e8d5b7]/50 px-3 py-1 text-xs text-[#8c6e52]">
            {eyebrow}
          </div>
        ) : null}
        <h1 className="text-3xl text-[#2c2a28]">{title}</h1>
        {description ? <p className="mt-2 max-w-3xl text-sm text-[#78716c]">{description}</p> : null}
      </div>
      {actions ? <div className="flex flex-wrap gap-3">{actions}</div> : null}
    </div>
  );
}
