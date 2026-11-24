import 'package:flutter/material.dart';

class ModuleHubPage extends StatelessWidget {
  const ModuleHubPage({super.key});

  static const _groups = <_ModuleGroup>[
    _ModuleGroup('DAILY OPERATIONS', Icons.storefront_outlined, [
      _Module('Customers / Patients', Icons.people_alt_outlined, 'Customer profiles, contact details, purchase history, balances, prescription links and customer search.', ['Register and edit customer profiles', 'Search by name or phone number', 'View purchase history and receipts', 'Track customer balances and payments', 'Restrict access to sensitive patient information'], 'Inahitaji customer database na payment ledger.'),
      _Module('Suppliers', Icons.local_shipping_outlined, 'Supplier directory and supplier account history.', ['Register supplier contacts and business details', 'Maintain supplier medicine catalogue', 'View purchase history by supplier', 'Track supplier balances and payments', 'Attach supplier documents'], 'Inahitaji supplier records na account ledger.'),
      _Module('Purchases / Receiving', Icons.add_shopping_cart, 'Purchase orders, receiving and stock intake.', ['Create purchase orders', 'Record supplier invoice and payment terms', 'Receive actual quantities against an order', 'Capture batch, cost and expiry per received line', 'Post verified receipts into stock'], 'Inahitaji purchase orders, batches na receiving workflow.'),
      _Module('Prescription Management', Icons.receipt_long_outlined, 'Prescription records linked to customers and dispensing.', ['Capture prescription image', 'Record prescriber and date', 'Review medicine, strength and dosage instructions', 'Record quantity dispensed and refills', 'Require pharmacist review before dispensing'], 'Inahitaji prescription data model; OCR lazima ithibitishwe na pharmacist.'),
    ]),
    _ModuleGroup('STOCK CONTROL', Icons.inventory_2_outlined, [
      _Module('Batch & Expiry Control', Icons.event_busy_outlined, 'Track stock by batch and expiry date, not only by medicine total.', ['Record batch / lot number and expiry date', 'Expiry alerts for 7, 30, 60 and 90 days', 'Quarantine expired stock', 'Return-to-supplier tracking', 'FEFO batch selection during sale'], 'Inahitaji batch-level inventory migration na FEFO integration.'),
      _Module('Stock Adjustments & Transfers', Icons.swap_horiz, 'Controlled stock movement with reasons and audit history.', ['Stock counts and reconciliation', 'Damaged, lost and returned stock', 'Inter-branch transfer requests', 'Adjustment approval and reason codes', 'Movement history by medicine and user'], 'Inahitaji stock movement ledger na branch model.'),
    ]),
    _ModuleGroup('FINANCE & REPORTING', Icons.account_balance_wallet_outlined, [
      _Module('Expenses', Icons.payments_outlined, 'Operating expenses separate from medicine purchases.', ['Record rent, salaries, utilities and transport', 'Categorise expenses and attach receipts', 'Filter expenses by date and category', 'Monthly expense summaries', 'Include expenses in net-profit reporting'], 'Inahitaji expenses table na net-profit calculation.'),
      _Module('Daily Closing', Icons.lock_clock_outlined, 'End-of-day cash reconciliation and close controls.', ['Cash, mobile money and bank totals', 'Expected versus counted cash', 'Refund and discount totals', 'Record cash variance and explanation', 'Lock closed business day with authorised reopen'], 'Closing service exists; payment-method reconciliation needs extension.'),
      _Module('Reports & Analytics', Icons.query_stats, 'Operational, inventory and financial reporting.', ['Daily, weekly, monthly and annual sales', 'Gross profit and net profit', 'Stock valuation and movement', 'Expiry, purchase, supplier and customer reports', 'Export PDF / Excel and print'], 'Sales report foundation exists; other report sources and exports need integration.'),
    ]),
    _ModuleGroup('PEOPLE & SECURITY', Icons.admin_panel_settings_outlined, [
      _Module('Employees & Permissions', Icons.badge_outlined, 'Staff accounts, roles and fine-grained permissions.', ['Create and deactivate staff accounts', 'Owner, admin, pharmacist, cashier and storekeeper roles', 'Permission checks for sensitive actions', 'Login history and password management', 'Require approval for refunds and stock adjustments'], 'Local admin/worker accounts exist; granular role permissions need implementation.'),
      _Module('Audit Trail', Icons.history, 'Traceability for important changes and transactions.', ['Who changed medicine prices or quantities', 'Who recorded, refunded or voided a sale', 'Before-and-after values and timestamps', 'Filter activity by staff and date', 'Protect audit records from ordinary users'], 'Basic audit log exists; full event coverage and viewer need extension.'),
    ]),
    _ModuleGroup('SYSTEM & CONNECTIVITY', Icons.settings_outlined, [
      _Module('Notifications', Icons.notifications_active_outlined, 'One inbox for stock, expiry, payment and system alerts.', ['Low-stock and reorder alerts', 'Expired and soon-to-expire medicine alerts', 'Supplier and customer due-payment alerts', 'Backup and sync failure alerts', 'Read, dismiss and notification preferences'], 'Notification inbox and delivery channels need implementation.'),
      _Module('Backup & Cloud Sync', Icons.cloud_sync_outlined, 'Protect local data and synchronise authorised devices.', ['Create and verify local backups', 'Restore from a selected backup', 'Export database securely', 'Show sync queue and retry errors', 'Synchronise branches and devices through a secured backend'], 'App is local-first; cloud backend and multi-device sync are not connected.'),
      _Module('Settings & Store Profile', Icons.tune, 'Store identity, operational preferences and device configuration.', ['Store name, address and contacts', 'TZS currency and tax settings', 'Receipt and printer settings', 'Language, theme and business hours', 'Camera, security and backup preferences'], 'Store profile foundation exists; remaining settings require persistence.'),
      _Module('Camera & Document Capture', Icons.document_scanner_outlined, 'Camera-assisted capture for medicine labels and business documents.', ['Barcode and QR scanning', 'OCR medicine name and strength', 'OCR batch number and expiry date', 'Capture supplier invoices and expense receipts', 'Capture prescriptions for pharmacist review'], 'Camera, barcode and OCR packages are not yet integrated.'),
    ]),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('All pharmacy modules', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      const Text('Module directory and implementation status. Open a module to review its intended functions and dependencies.', style: TextStyle(color: Color(0xFF929BB9), fontSize: 12)),
      const SizedBox(height: 18),
      for (final group in _groups) ...[
        Row(children: [Icon(group.icon, color: const Color(0xFFB69AFF), size: 18), const SizedBox(width: 8), Text(group.title, style: const TextStyle(fontSize: 11, letterSpacing: 1.3, fontWeight: FontWeight.bold, color: Color(0xFFA9B1D0)))]),
        const SizedBox(height: 9),
        ...group.modules.map((module) => Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: const Color(0xFF292044), child: Icon(module.icon, color: const Color(0xFFB69AFF))),
            title: Text(module.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(module.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF929BB9))),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showModalBottomSheet<void>(
              context: context, isScrollControlled: true, backgroundColor: const Color(0xFF15182A),
              builder: (ctx) => SafeArea(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [Icon(module.icon, color: const Color(0xFFB69AFF)), const SizedBox(width: 10), Expanded(child: Text(module.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)))]),
                  const SizedBox(height: 8), Text(module.summary, style: const TextStyle(color: Color(0xFFB7BED5))),
                  const SizedBox(height: 16), const Text('FUNCTIONS', style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.bold, color: Color(0xFFA9B1D0))),
                  const SizedBox(height: 8), for (final item in module.functions) Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline, size: 17, color: Color(0xFF42C99A)), const SizedBox(width: 9), Expanded(child: Text(item, style: const TextStyle(fontSize: 13)))])),
                  const SizedBox(height: 16), Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF292044), borderRadius: BorderRadius.circular(12)), child: Text(module.status, style: const TextStyle(fontSize: 12, color: Color(0xFFD6C9FF)))),
                  const SizedBox(height: 12), Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))),
                ])),
              )),
            ),
          ),
        )),
        const SizedBox(height: 14),
      ],
    ],
  );
}

class _ModuleGroup {
  const _ModuleGroup(this.title, this.icon, this.modules);
  final String title;
  final IconData icon;
  final List<_Module> modules;
}
class _Module {
  const _Module(this.title, this.icon, this.summary, this.functions, this.status);
  final String title;
  final IconData icon;
  final String summary;
  final List<String> functions;
  final String status;
}
