# Implementation status

## Verified in repository

- Flutter application foundation and responsive dark pharmacy dashboard.
- Local SQLite database and local owner/worker sign-in flow.
- Clean database creation does not insert demo medicines or demo sales.
- Medicine search by name or barcode text.
- Sales cart and sale persistence.
- Stock deduction and sale insertion run in one SQLite transaction.
- Sale-time purchase-cost snapshots support historical gross-profit calculations.
- Dashboard and daily sales list read local database totals.
- Daily closing and weekly alert services enqueue local outbox records; this is not proof of email delivery.
- GitHub Actions formats Dart sources, runs static analysis and unit tests, generates standard Android platform scaffolding, and attempts a release APK build.

## Not implemented or not verified

- Batch/lot records, expiry tracking, FEFO allocation, expiry notifications and expired/recalled stock blocking.
- Camera barcode scanning and OCR for medicine name, batch and expiry labels.
- Cloud backend deployment, authenticated device enrollment, bidirectional sync, idempotency, conflict handling and encrypted recovery.
- Email transport, SMTP/provider credentials, retries and delivery receipts. Existing report jobs only create local outbox records.
- Full Android physical-device smoke test.
- Verified backup/export/restore workflow.
- Production-grade authentication/session storage and server-enforced authorization. Local role checks are not a substitute for a trusted server boundary.
- Full regulatory, privacy, security and accounting review for commercial pharmacy use.

## Test coverage currently present

The existing unit-test file contains two accounting tests for revenue, cost snapshots and negative gross profit. These do not exercise SQLite persistence, user onboarding, stock deduction, expired stock, camera, cloud sync, email delivery or Android hardware.

## Required acceptance tests before live use

- [ ] Fresh install has zero medicines, batches and sales; all dashboard totals start at zero.
- [ ] Create owner account and configure the store.
- [ ] Add medicine and at least two batches with different expiry dates.
- [ ] Confirm FEFO selects the earliest valid expiry batch.
- [ ] Confirm expired stock is blocked and cannot be sold.
- [ ] Sell an item; verify batch quantity, total stock, sale history and profit.
- [ ] Attempt overselling; verify the entire transaction rolls back.
- [ ] Force-close/reopen app and verify persistence.
- [ ] Scan barcode and OCR a real medicine label; manually confirm extracted values before saving.
- [ ] Sync two enrolled Android devices, including offline edits and conflict handling.
- [ ] Send daily/weekly reports to controlled test mailboxes and inspect delivery/bounce results.
- [ ] Install release APK on physical Android device and test camera, storage, network loss and restore.

## External prerequisites

Cloud synchronization requires a configured backend project and credentials. Email delivery requires a configured provider and credentials. Hardware acceptance requires a physical Android device and user-granted camera permission. Do not place production secrets in source control.
