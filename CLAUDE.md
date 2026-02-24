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

**Stack:** Flutter + Firebase (Firestore, Auth, Storage, Functions) + GoRouter + Provider

**Layer structure:**
- `lib/models/` — Data models with `toMap()`, `fromMap()`, `copyWith()`. Enums for constrained values (UserRole, EventStatus, InvitationStatus).
- `lib/services/` — One service class per domain (EventService, RegistrationService, InvitationService, FeedbackService, CguService, LocationService). Each service owns its Firestore collection and exposes both `Future` and `Stream` variants. `AuthService` is the only service injected via Provider.
- `lib/pages/` — Full-screen pages. Services are instantiated directly inside pages (not via dependency injection).
- `lib/widgets/` — Reusable widgets, dialogs, and section components.
- `lib/router_utils.dart` — Contains `computeRedirect()` logic, tested in `test/router_utils_test.dart`.
- `lib/main.dart` — App entry point, GoRouter configuration, `GoRouterRefreshStream` to bridge auth state to router.

**State management:** Provider is used exclusively for `AuthService`. All other state is local `setState()` or passed directly.

**Navigation:** GoRouter v17. Routes defined in `main.dart`. `GoRouterRefreshStream` listens to `authService.authStateChanges` and triggers redirect evaluation. Redirect logic lives in `router_utils.dart`.

**Authentication flow:** Firebase Auth → `AuthService.authStateChanges` stream → GoRouter redirect → `/login` if not signed in, `/home` if signed in.

**User roles:** `admin`, `adherent`, `invite`. Role stored in Firestore `users/` collection and loaded into `AuthService`.

**CGU (Terms & Conditions):** Tracked via `cgu_acceptances/` collection with version numbers. Handled by `CguService` and shown via `CguAcceptanceDialog`.

**Event lifecycle:** `pending` → `started` → `finished`. Events have registration capacity, attendance confirmation, and a post-event feedback system.

## Key Conventions

- All UI text and error messages are in **French**.
- Firebase exceptions in `AuthService._handleAuthException()` are mapped to French messages.
- Service method naming: `create*`, `update*`, `delete*`, `get*`, `getAll*`, `get*Stream`.
- Theme: Material 3, seed color `#2E6AE6`, Google Fonts Inter, light + dark themes.
- Firebase project ID: `coentrepreneurs-7b291`.

## Firestore Collections

| Collection | Purpose |
|---|---|
| `users/` | User profiles and roles |
| `events/` | Event data |
| `registrations/` | Event registrations |
| `invitations/` | Event invitations |
| `feedbacks/` | Post-event feedback |
| `cgu_acceptances/` | Terms acceptance records |
