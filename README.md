# MY DAWA STORE

Offline-first pharmacy management for Tanzanian medicine shops. Built around local-first sales, inventory, role-based access, and eventual synchronization.

## Product direction
- Android APK and Windows desktop from one Flutter codebase.
- Local database is the source of truth while offline.
- Admin and worker workspaces with permission boundaries.
- Fast medicine search in the sales workflow for both roles.
- Search a medicine, enter quantity and selling price, confirm sale, and calculate totals immediately.
- Cloud synchronization and email reports run only when connectivity is available.

## Current status
This repository contains the initial application foundation and product specification. It is not yet a production-ready pharmacy system. Authentication, encrypted backups, cloud sync, email delivery, background closing, regulatory workflows, and full automated testing must be completed and audited before real pharmacy use.

## Run
Install Flutter stable, then:

```bash
flutter pub get
flutter run
```

For Android: `flutter build apk --release`
For Windows: `flutter build windows --release`

## Important accounting rule
Each sale stores the unit cost snapshot used for that sale. Historical profit must never be recalculated using a later-edited purchase price. Returns, discounts, expenses, stock adjustments, and batch/expiry tracking must be recorded as auditable transactions.

## Safety
This is business inventory/POS software, not a clinical decision system. It must not recommend treatments or substitute for a licensed pharmacist.