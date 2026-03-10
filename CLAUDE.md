# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run the app (select device)
flutter test             # Run all tests
flutter test test/router_utils_test.dart  # Run a single test file
flutter build apk        # Build Android release
flutter build web        # Build web release
flutter analyze          # Run static analysis
```

## Architecture

**Stack:** Flutter + Supabase (Auth, Postgres, Storage, Edge Functions, Realtime) + GoRouter + Provider

**Infrastructure:** Self-hosted Supabase on VPS `46.225.133.77`. Web app at `https://app.coentrepreneurs.fr`.

**Layer structure:**

- `lib/models/` — Data models with `toMap()`, `fromMap()`, `copyWith()`. Enums for constrained values (UserRole, EventStatus, InvitationStatus).
- `lib/services/` — One service class per domain (EventService, RegistrationService, InvitationService, FeedbackService, CguService, LocationService, NotificationService, BadgeService, StorageService). Each service owns its Supabase table and exposes both `Future` and `Stream` variants. `AuthService` is the only service injected via Provider.
- `lib/pages/` — Full-screen pages. Services are instantiated directly inside pages (not via dependency injection).
- `lib/widgets/` — Reusable widgets, dialogs, and section components.
- `lib/router_utils.dart` — Contains `computeRedirect()` logic, tested in `test/router_utils_test.dart`.
- `lib/main.dart` — App entry point, GoRouter configuration, `GoRouterRefreshStream` to bridge auth state to router.

**State management:** Provider is used exclusively for `AuthService`. All other state is local `setState()` or passed directly.

**Navigation:** GoRouter v17. Routes defined in `main.dart`. `GoRouterRefreshStream` listens to `authService.authStateChanges` and triggers redirect evaluation. Redirect logic lives in `router_utils.dart`.

**Authentication flow:** Supabase Auth → `AuthService.authStateChanges` stream → GoRouter redirect → `/login` if not signed in, `/home` if signed in.

**User roles:** `admin`, `adherent`, `invite`. Role stored in `public.users` table and loaded into `AuthService`.

**CGU (Terms & Conditions):** Tracked via `cgu_acceptances` table with version numbers. Handled by `CguService` and shown via `CguAcceptanceDialog`.

**Event lifecycle:** `pending` → `started` → `finished`. Events have registration capacity, attendance confirmation, and a post-event feedback system.

**Push notifications:** VAPID web push via Supabase Edge Functions. Subscriptions stored in `push_subscriptions` table. Webhooks trigger `send-push` function on user signup, approval, and event creation.

## Key Conventions

- All UI text and error messages are in **French**.
- Supabase Auth exceptions in `AuthService._handleAuthException()` are mapped to French messages.
- Service method naming: `create*`, `update*`, `delete*`, `get*`, `getAll*`, `get*Stream`.
- Theme: Material 3, seed color `#2E6AE6`, Google Fonts Inter, light + dark themes.
- Supabase URL: `https://app.coentrepreneurs.fr` (self-hosted, proxied via nginx).

## Supabase Tables

| Table | Purpose |
| --- | --- |
| `users` | User profiles and roles |
| `events` | Event data |
| `registrations` | Event registrations (status: registered/confirmed/declined) |
| `invitations` | Event invitations |
| `feedbacks` | Post-event feedback |
| `cgu_acceptances` | Terms acceptance records |
| `messages` | Contact form submissions |
| `push_subscriptions` | Browser push subscriptions (VAPID) |

## Supabase Edge Functions

| Function | Trigger | Purpose |
| --- | --- | --- |
| `send-push` | HTTP POST | Dispatch push notifications (by user_ids or role) |
| `webhook-user-signup` | DB webhook INSERT users | Notify admins of new signup request |
| `webhook-user-approved` | DB webhook UPDATE users | Notify user of approval/rejection |
| `webhook-event-created` | DB webhook INSERT events | Notify adherents of new event |

## Storage Buckets

| Bucket | Access | Purpose |
| --- | --- | --- |
| `events` | Public | Event images and files |
| `messages_attachments` | Private (signed URLs) | Attachments in messages |

## Migrations

| File | Description |
| --- | --- |
| `001_initial_schema.sql` | Full schema: 7 tables, RLS policies, triggers |
| `002_push_subscriptions.sql` | push_subscriptions table |
| `003_realtime_users.sql` | Realtime on users table |
| `004_member_since_passions.sql` | member_since + passions columns on users |
| `005_parrainage.sql` | parrain_id column on users (sponsorship) |
| `006_push_subscriptions_update_policy.sql` | UPDATE policy on push_subscriptions (upsert fix) |
