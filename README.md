# MY DAWA STORE

Offline-first pharmacy inventory and point-of-sale application for Tanzanian medicine shops. Currency: whole TZS shillings.

## Implemented foundation

- Flutter application targeting Android and desktop.
- Dark pharmacy dashboard and responsive navigation.
- Local SQLite medicine catalogue and local owner/worker accounts.
- Medicine search by name or barcode text.
- Quick-sale cart and sale posting with transactional stock deduction.
- Sale-time purchase-cost snapshots for historical gross-profit calculations.
- Local sales list and daily totals derived from stored transactions.
- GitHub Actions formatting, analysis, unit tests and Android release APK build.

A clean install starts with no medicine catalogue or sales seeded by the application. The first owner creates a store profile; the owner must enter their own catalogue and opening stock. Dashboard totals should therefore begin at zero. Existing installations retain their local database unless the user clears app storage or uninstalls the app.

## Run locally

Install Flutter stable, then:

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter create --platforms=android --org com.mydawastore .
flutter build apk --release
flutter run
```

The repository does not currently contain checked-in Android platform scaffolding. The CI workflow generates the standard Android project before building the release APK.

## Current release status

This repository remains a development prototype and is not approved for live pharmacy operations. The following are not yet implemented or verified end-to-end:

- Batch/lot inventory, expiry dates, FEFO allocation and expired-stock sale blocking.
- Camera barcode scanning and medicine-label/expiry OCR.
- A deployed authenticated cloud backend, multi-device synchronization, conflict resolution and recovery.
- Outbound email delivery and verified daily/weekly report delivery.
- Full Android device smoke testing, including camera permissions, real scanning, sale flow, restart persistence and backup/restore.
- Production security, role-boundary, privacy, regulatory and accounting review.

GitHub Actions builds an APK as a workflow artifact when the pipeline succeeds. A successful CI build is not the same as installing and testing the APK on a physical Android device.

## Accounting invariants

Money is stored as whole TZS integers. Each sale line stores its purchase cost at the time of sale. Sale lines and stock deduction are committed in one SQLite transaction; insufficient stock should reject the transaction.
