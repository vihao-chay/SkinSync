export function ErrorState({
  title = "Something went wrong",
  message,
  action,
}: {
  title?: string;
  message: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="rounded-[30px] border border-[color:rgba(183,110,100,0.25)] bg-[linear-gradient(135deg,rgba(255,248,246,0.95),rgba(249,235,232,0.95))] p-6 shadow-[0_18px_44px_rgba(183,110,100,0.08)]">
      <h2 className="text-lg text-[var(--ss-danger)]">{title}</h2>
      <p className="mt-2 text-sm leading-6 text-[color:rgba(120,77,71,0.95)]">{message}</p>
      {action ? <div className="mt-4">{action}</div> : null}
    </div>
  );
}
