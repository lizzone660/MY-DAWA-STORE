# MY DAWA STORE — module implementation plan

This repository remains the source of truth for the Android application. Changes committed here trigger the signed Android APK workflow; the APK is a build output, not a live-updating binary. Users must install a newer APK to receive code changes. Existing local database records must be preserved by versioned migrations.

## Navigation foundation
- Desktop sidebar and mobile bottom navigation expose Dashboard, Sales, Stock, Reports and All Modules.
- The All Modules directory documents Customers/Patients, Suppliers, Purchases/Receiving, Prescriptions, Batch/Expiry, Stock Adjustments/Transfers, Expenses, Daily Closing, Reports, Employees/Permissions, Audit Trail, Notifications, Backup/Cloud Sync, Settings and Camera/Document Capture.
- Each directory entry describes functions and explicitly states dependencies that are not yet implemented.

## Existing capabilities
- Flutter app with SQLite local-first storage.
- Medicine catalogue, POS sales, transactional stock deduction, sale cost snapshots, local sales history, basic admin/worker accounts, basic audit log, daily closing service and sales reporting.

## Not yet production-complete
- Batch-level stock and FEFO, supplier/customer ledgers, purchase orders/receiving, prescription workflow, expenses, payment-method reconciliation, granular role permissions, notification inbox, robust backup/restore, cloud sync, camera barcode/OCR, PDF/Excel exports and comprehensive audit viewer.
- A successful CI build is not a substitute for device testing, pharmacy workflow validation, security review or regulatory review.

## Release policy
1. Commit source and documentation to GitHub.
2. Wait for CI tests, signed APK build, signature verification and artifact upload.
3. Download and install the new APK; it does not patch an already installed APK in place.
4. Run Android device smoke tests and preserve the previous release for rollback.
5. Do not claim modules are operational until their database, service, UI, permissions and tests are implemented.
