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
    <div className="rounded-[30px] border border-[color:rgba(184,92,80,0.22)] bg-[var(--ss-danger-bg)] p-6 shadow-[0_18px_44px_rgba(184,92,80,0.08)]">
      <h2 className="text-lg text-[var(--ss-danger)]">{title}</h2>
      <p className="mt-2 text-sm leading-6 text-[var(--ss-text-secondary)]">{message}</p>
      {action ? <div className="mt-4">{action}</div> : null}
    </div>
  );
}
