export function EmptyState({
  title,
  description,
  action,
}: {
  title: string;
  description: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="rounded-3xl border border-dashed border-[#e8d5b7] bg-white/80 p-8 text-center shadow-sm">
      <h2 className="text-xl text-[#2c2a28]">{title}</h2>
      <p className="mx-auto mt-2 max-w-xl text-sm text-[#78716c]">{description}</p>
      {action ? <div className="mt-5 flex justify-center">{action}</div> : null}
    </div>
  );
}
