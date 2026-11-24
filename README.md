# MY DAWA STORE

Offline-first pharmacy inventory and point-of-sale application for Tanzanian medicine shops.

## Current capabilities
- Flutter foundation targeting Android and desktop from one codebase.
- Dark navy, metallic and violet pharmacy dashboard.
- Local SQLite medicine catalogue.
- Medicine search by name/barcode and quick-sale cart.
- Sale posting with atomic stock deduction and purchase-cost snapshots.
- Admin inventory add/edit prototype.
- GitHub Actions formatting, analysis and unit-test workflow.

## Run locally
Install Flutter stable, then:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Build commands:
- Android: `flutter build apk --release`
- Windows: `flutter build windows --release`

## Status
This is an active development prototype, not a production-ready pharmacy POS. Authentication and server-enforced roles, cloud sync, daily closing, email delivery, reports connected to live sales, batch/expiry controls, backups and security/regulatory reviews remain incomplete. Do not use it for live pharmacy accounting until those controls are completed and verified.

## Accounting
All monetary amounts are whole TZS integers. Each sale line stores the purchase cost at the time of sale so later price edits do not rewrite historical gross profit. Sale lines and stock deduction are committed in a single SQLite transaction.
