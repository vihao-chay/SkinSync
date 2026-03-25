# SkinSync API Contract (FE <-> BE)

This document summarizes the current API contract used by the frontend.

## Base URL

- Local: `/api`
- Production: configured by `VITE_API_BASE_URL`

## Authentication

- Auth uses JWT Bearer token in `Authorization: Bearer <accessToken>`.
- User identity is resolved from JWT claims (`sub`) on backend.
- Do not send custom user id headers.
- Refresh token flow:
  1. Frontend calls protected API with access token.
  2. If `401`, frontend calls `POST /auth/refresh`.
  3. If refresh succeeds, retry original request once.
  4. If refresh fails, clear auth session and return to login.

## Standard Response Envelope

Most endpoints return:

```json
{
  "success": true,
  "statusCode": 200,
  "message": "...",
  "content": {}
}
```

## Auth Endpoints

- `POST /auth/register` (public)
- `POST /auth/login` (public)
- `POST /auth/google` (public)
- `POST /auth/refresh` (public)
- `POST /auth/forgot-password` (public)
- `POST /auth/reset-password` (public)
- `GET /auth/me` (authenticated)
- `POST /auth/logout` (authenticated)
- `PATCH /auth/change-password` (authenticated)
- `PATCH /auth/profile` (authenticated)
- `PATCH /auth/avatar` (authenticated)

## User-Facing Domain Endpoints

### Survey

- `PUT /users/survey` (authenticated)
- `GET /users/survey` (authenticated)

### Analysis

- `POST /analysis/scan` (authenticated)
- `GET /analysis/history` (authenticated)
- `GET /analysis/{id}` (authenticated)
- `GET /analysis/latest` (authenticated)

### Regimen

- `GET /regimens/current` (authenticated)
- `PUT /regimens/current` (authenticated)

### Diary

- `PUT /diary/checkin` (authenticated)
- `GET /diary/today` (authenticated)
- `GET /diary/day?date=YYYY-MM-DD` (authenticated)
- `GET /diary/month?year=YYYY&month=MM` (authenticated)

### Progress

- `GET /progress/overview` (authenticated)
- `GET /progress/chart?days=28` (authenticated)
- `GET /progress/streak?days=90` (authenticated)

## Admin Endpoints

Admin APIs require role `admin`.

- `GET /admin/users`
- `GET /admin/users/{id}`
- `PATCH /admin/users/{id}/status`
- `PATCH /admin/users/{id}/role`
- `GET /admin/products`
- `POST /admin/products`
- `PUT /admin/products/{id}`
- `DELETE /admin/products/{id}`

## Frontend Integration Notes

- Frontend service modules map 1:1 with domain APIs:
  - `surveyService.ts`
  - `analysisService.ts`
  - `regimenService.ts`
  - `diaryService.ts`
  - `progressService.ts`
- Shared request handling is in `apiClient.ts`.
- Auth session storage and refresh logic is in `authService.ts`.
