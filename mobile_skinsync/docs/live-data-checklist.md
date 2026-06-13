# SkinSync Live Data Checklist

Use this checklist when validating that the user-facing app only shows real account data or legitimate empty states.

## Mobile app

- `LandingPage` does not show sample analysis images, fake scores, or mock routine metrics.
- `Dashboard` only reads backend state or shows empty states such as no routine, no analysis, or no diary yet.
- `Routine` only renders active regimen data from backend or an empty routine state.
- `Products` only shows recommendation results from `/api/ai/products/recommend` or a search empty state.
- `Progress` only shows uploaded progress photos, analysis entries, and generated reports, or empty states when data is absent.
- `Today Check-up` only reflects routine tracking and daily log data for the signed-in user.
- `Profile` only shows authenticated user profile and subscription data from backend.
- No user-facing screen imports `MockSkinData` or `mock_skin_data.dart`.

## Backend

- Startup does not create demo users, demo products, or demo daily logs unless `Startup:SeedDemoData` is explicitly enabled.
- Database migration/setup can still run without injecting sample records.
- Authenticated endpoints return data for the current user only.
- AI endpoints are backed by real services and fail clearly when required data is missing instead of returning sample content.

## Source audit

- `rg "MockSkinData|mock_skin_data"` only returns archived or intentionally unused code paths that are outside the current user flow.
- `rg "demo@skinsync.local|Demo User"` only returns the optional demo seeding path.
- `Landing` and `Admin` do not contain hardcoded user counts, skin scores, routine metrics, or recent activity numbers.
