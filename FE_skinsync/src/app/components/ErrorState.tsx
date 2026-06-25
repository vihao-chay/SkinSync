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
    <div className="rounded-3xl border border-red-100 bg-red-50/80 p-6">
      <h2 className="text-lg text-red-700">{title}</h2>
      <p className="mt-2 text-sm text-red-600">{message}</p>
      {action ? <div className="mt-4">{action}</div> : null}
    </div>
  );
}
