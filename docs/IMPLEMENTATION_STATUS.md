# Implementation status

## Implemented in repository
- Flutter application foundation and responsive dark pharmacy dashboard.
- Desktop sidebar and mobile bottom navigation.
- Medicine search by name or barcode in the app bar and sales center.
- Quick-sale cart with quantity controls and live TZS totals.
- Sales screen now submits sale lines to the SQLite repository.
- SQLite sale posting checks stock and deducts inventory atomically in one transaction.
- Sale-time purchase-cost snapshots preserve historical gross-profit calculations.
- Inventory list reads from SQLite; admin UI has add/edit medicine forms.
- New local database is initialized with demo catalogue data only when empty.
- GitHub Actions workflow added for formatting, static analysis and Flutter tests.
- Basic accounting unit tests added.

## Important limitations — not production-ready
- Current role selector is a development/demo switch, not authentication. Do not deploy with real worker accounts until secure registration, login, session handling and authorization are implemented.
- Admin-only controls are currently UI-gated, not protected by a verified identity boundary.
- The current seed medicines are demonstration data and must be removed/replaced before store onboarding.
- Dashboard KPIs and reports still contain sample figures; daily reports are not yet connected to real sales.
- Daily closing, schedule recovery, email delivery, weekly reorder email and store hours are not implemented.
- No multi-device cloud service exists yet. Multiple devices cannot share live data until a backend, device identity, authenticated sync API, conflict handling and encrypted transport are implemented.
- No password-protected owner approval flow or worker invitation system yet.
- Batch/lot/expiry/FEFO, supplier records, returns, expenses, audit UI and export/restore are incomplete.
- No Android APK or Windows build has been produced or tested in this environment.
- Before real pharmacy operations, complete security, data-protection, regulatory, accounting and operational testing.

## Smoke-test checklist
- [ ] Flutter format
- [ ] Flutter analyze
- [ ] Flutter tests
- [ ] Android debug/release build
- [ ] Windows desktop build
- [ ] Install and launch on Android
- [ ] Create store, admin and worker identities
- [ ] Confirm role access boundaries
- [ ] Add medicine, restart app, verify persistence
- [ ] Sell medicine offline and verify stock decrement
- [ ] Attempt oversell and verify full rollback
- [ ] Verify daily close and report totals
- [ ] Verify offline queue and online multi-device sync
