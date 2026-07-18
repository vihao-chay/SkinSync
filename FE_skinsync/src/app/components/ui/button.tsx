import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";

import { cn } from "./utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4 shrink-0 [&_svg]:shrink-0 outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-[var(--ss-gold-hover)] active:bg-[var(--ss-gold-pressed)]",
        premium: "bg-[var(--ss-primary-gradient)] text-primary-foreground shadow-[0_18px_30px_rgba(194,166,125,0.22)] hover:brightness-[0.99] active:brightness-95",
        destructive:
          "border border-[color:rgba(184,92,80,0.22)] bg-[var(--ss-danger-bg)] text-[var(--ss-danger)] hover:bg-[color:rgba(252,236,234,0.8)] focus-visible:ring-destructive/20 dark:focus-visible:ring-destructive/40",
        outline:
          "border border-border bg-card text-foreground hover:bg-[var(--ss-gold-pale)] hover:border-[var(--ss-border-medium)]",
        secondary:
          "border border-border bg-secondary text-secondary-foreground hover:bg-accent",
        ghost:
          "text-muted-foreground hover:bg-[var(--ss-gold-pale)] hover:text-foreground",
        link: "text-primary underline-offset-4 hover:underline",
        iconButton: "border border-border bg-card text-muted-foreground hover:bg-[var(--ss-gold-pale)] hover:text-foreground",
      },
      size: {
        default: "h-9 px-4 py-2 has-[>svg]:px-3",
        sm: "h-8 rounded-md gap-1.5 px-3 has-[>svg]:px-2.5",
        lg: "h-10 rounded-md px-6 has-[>svg]:px-4",
        icon: "size-9 rounded-md",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  },
);

function Button({
  className,
  variant,
  size,
  asChild = false,
  ...props
}: React.ComponentProps<"button"> &
  VariantProps<typeof buttonVariants> & {
    asChild?: boolean;
  }) {
  const Comp = asChild ? Slot : "button";

  return (
    <Comp
      data-slot="button"
      className={cn(buttonVariants({ variant, size, className }))}
      {...props}
    />
  );
}

export { Button, buttonVariants };
