# Product specification

## Visual direction
Follow the supplied references: premium dark graphite/navy pharmacy identity, metallic silver typography, cyan-blue medical emblem glow, and a high-density desktop dashboard. MY DAWA STORE adds controlled violet/purple LED accents. Maintain strong contrast and readable typography. Mobile uses bottom navigation; desktop uses a persistent left sidebar.

## Sales search requirement (admin and worker)
Both roles must have a visible search icon in the app bar and searchable medicine field in Sales Center. Search by medicine name or barcode. Selecting a result adds it to the current sale. The operator can change quantity and unit selling price, see line totals and grand total immediately, then confirm. Show available stock and block overselling. Admin can see margin estimates; workers cannot see purchase cost or profit.

## Roles
- Owner/admin: manage medicine catalogue, purchase and selling prices, stock receipts, workers, settings, reports, daily closing and audit trail.
- Worker: search catalogue, create sales, view selling price and available stock, see current shift sales and stock intelligence. No purchase cost, margin, profit, settings or staff administration.
- Owner-authorized one-time approval: privileged corrections are separately audited and do not elevate worker to admin.

## Accounting invariants
- Store money as integer TZS whole shillings; never use floating point for money.
- Store purchase-cost snapshot per sale line.
- Record immutable sale and return events; corrections use reversal/adjustment events.
- Daily gross profit = sum(quantity × (sale unit price − cost snapshot)); net profit additionally subtracts recorded expenses and applicable adjustments.
- Prevent sale quantity from exceeding available stock inside one database transaction.

## Offline and sync
Local SQLite is authoritative while offline. Every write gets UUID, device ID, actor ID, local timestamp and sync status. Server sync is idempotent. Conflicts are explicit and audited; do not silently overwrite stock movements. Daily closing is idempotent per store business date and recovers after app restart. Email is queued locally and delivered when connectivity returns.

## Pharmacy safeguards
Support batch/lot, expiry, FEFO alerts, supplier traceability and recall reporting. Expired/recalled stock must be blocked from sale. Do not provide diagnosis or treatment recommendations. Configure applicable Tanzania pharmacy and data-protection requirements before commercial deployment.
