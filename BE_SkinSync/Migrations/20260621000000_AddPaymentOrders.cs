using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SkinSync.Migrations
{
    public partial class AddPaymentOrders : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
CREATE TABLE IF NOT EXISTS payment_orders (
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
ON payment_orders ("OrderCode");

CREATE INDEX IF NOT EXISTS "IX_payment_orders_UserId_Status"
ON payment_orders ("UserId", "Status");

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'FK_payment_orders_users_UserId'
          AND conrelid = 'payment_orders'::regclass
    ) THEN
        ALTER TABLE payment_orders
        ADD CONSTRAINT "FK_payment_orders_users_UserId"
        FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE NOT VALID;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'FK_payment_orders_subscription_plans_PlanId'
          AND conrelid = 'payment_orders'::regclass
    ) THEN
        ALTER TABLE payment_orders
        ADD CONSTRAINT "FK_payment_orders_subscription_plans_PlanId"
        FOREIGN KEY ("PlanId") REFERENCES subscription_plans ("Id") ON DELETE RESTRICT NOT VALID;
    END IF;
END $$;

ALTER TABLE payment_orders
DROP CONSTRAINT IF EXISTS ck_payment_orders_status;

ALTER TABLE payment_orders
ADD CONSTRAINT ck_payment_orders_status
CHECK ("Status" IN ('pending', 'paid', 'cancelled'));
""");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
DROP TABLE IF EXISTS payment_orders;
""");
        }
    }
}
