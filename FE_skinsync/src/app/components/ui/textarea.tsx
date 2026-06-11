import * as React from "react";

import { cn } from "./utils";

function Textarea({ className, ...props }: React.ComponentProps<"textarea">) {
  return (
    <textarea
      data-slot="textarea"
      className={cn(
        "resize-none flex field-sizing-content min-h-16 w-full rounded-2xl border border-skin-border bg-skin-surface px-3 py-2 text-base text-skin-textMain placeholder:text-skin-textMuted transition-[color,box-shadow] outline-none focus-visible:border-skin-gold focus-visible:ring-2 focus-visible:ring-skin-gold/20 disabled:cursor-not-allowed disabled:opacity-50 md:text-sm",
        className,
      )}
      {...props}
    />
  );
}

export { Textarea };
