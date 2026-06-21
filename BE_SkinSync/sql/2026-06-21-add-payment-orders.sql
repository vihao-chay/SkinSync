BEGIN;

CREATE TABLE IF NOT EXISTS public.payment_orders (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "PlanId" uuid NOT NULL,
    "OrderCode" bigint NOT NULL,
    "Amount" numeric(12,2) NOT NULL,
    "Status" character varying(20) NOT NULL DEFAULT 'pending',
    "PayOsPaymentLinkId" character varying(255) NULL,
    "CheckoutUrl" character varying(1000) NULL,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT timezone('utc', now()),
    "PaidAt" timestamp with time zone NULL,
    CONSTRAINT "PK_payment_orders" PRIMARY KEY ("Id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_payment_orders_OrderCode"
ON public.payment_orders ("OrderCode");

CREATE INDEX IF NOT EXISTS "IX_payment_orders_UserId_Status"
ON public.payment_orders ("UserId", "Status");

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'FK_payment_orders_users_UserId'
          AND conrelid = 'public.payment_orders'::regclass
    ) THEN
        ALTER TABLE public.payment_orders
        ADD CONSTRAINT "FK_payment_orders_users_UserId"
        FOREIGN KEY ("UserId") REFERENCES public.users ("Id") ON DELETE CASCADE NOT VALID;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'FK_payment_orders_subscription_plans_PlanId'
          AND conrelid = 'public.payment_orders'::regclass
    ) THEN
        ALTER TABLE public.payment_orders
        ADD CONSTRAINT "FK_payment_orders_subscription_plans_PlanId"
        FOREIGN KEY ("PlanId") REFERENCES public.subscription_plans ("Id") ON DELETE RESTRICT NOT VALID;
    END IF;
END $$;

ALTER TABLE public.payment_orders
DROP CONSTRAINT IF EXISTS ck_payment_orders_status;

ALTER TABLE public.payment_orders
ADD CONSTRAINT ck_payment_orders_status
CHECK ("Status" IN ('pending', 'paid', 'cancelled'));

COMMIT;
