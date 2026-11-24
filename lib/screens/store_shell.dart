import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/store_repository.dart';
import 'sales_page.dart';

class StoreShell extends StatefulWidget {
  const StoreShell({super.key});
  @override
  State<StoreShell> createState() => _StoreShellState();
}

class _StoreShellState extends State<StoreShell> {
  int _index = 0;
  final _repository = StoreRepository();
  String _actorId = 'local-admin';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocalStore();
  }

  Future<void> _initializeLocalStore() async {
    final existing = await _repository.medicines();
    if (existing.isEmpty) {
      for (final medicine in _medicines) { await _repository.saveMedicine(medicine); }
    }
    await _refreshMedicines();
  }

  Future<void> _refreshMedicines() async {
    final rows = await _repository.medicines();
    if (!mounted) return;
    setState(() { _medicines = rows; _loading = false; });
  }
  bool _isAdmin = true;
  List<Medicine> _medicines = [
    const Medicine(id:'m1', name:'Paracetamol 500mg', purchasePrice:300, sellingPrice:500, quantity:120),
    const Medicine(id:'m2', name:'Amoxicillin 500mg', purchasePrice:1200, sellingPrice:1800, quantity:42),
    const Medicine(id:'m3', name:'ORS Sachets', purchasePrice:450, sellingPrice:700, quantity:68),
    const Medicine(id:'m4', name:'Cetirizine 10mg', purchasePrice:250, sellingPrice:500, quantity:18),
    const Medicine(id:'m5', name:'Vitamin C 1000mg', purchasePrice:900, sellingPrice:1400, quantity:7),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [_dashboard(), SalesPage(medicines: _medicines, isAdmin: _isAdmin, actorId: _actorId, onSaleRecorded: _refreshMedicines), _inventory(), _reports()];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('MY DAWA STORE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.4, fontSize: 16)),
          Text('BIOHAVEN PHARMACY  •  ' + (_isAdmin ? 'ADMIN' : 'WORKER'), style: const TextStyle(fontSize: 10, color: Color(0xFF9DA6C7), letterSpacing: 1.1)),
        ]),
        actions: [
          IconButton(tooltip: 'Search medicine', onPressed: () => showSearch(context: context, delegate: MedicineSearchDelegate(_medicines)), icon: const Icon(Icons.search, size: 27)),
          IconButton(tooltip: 'Notifications', onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (v) => setState(() => _isAdmin = v == 'admin'),
            itemBuilder: (_) => const [PopupMenuItem(value:'admin', child: Text('Admin workspace')), PopupMenuItem(value:'worker', child: Text('Worker workspace'))],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Row(children: [
        if (MediaQuery.sizeOf(context).width >= 760) _sidebar(),
        Expanded(child: IndexedStack(index: _index, children: pages)),
      ]),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 760
          ? NavigationBar(selectedIndex: _index, onDestinationSelected: (v) => setState(() => _index = v), destinations: const [
              NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Sell'),
              NavigationDestination(icon: Icon(Icons.medication_outlined), label: 'Stock'),
              NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Reports'),
            ]) : null,
    );
  }

  Widget _sidebar() => Container(width: 220, decoration: const BoxDecoration(color: Color(0xFF101323), border: Border(right: BorderSide(color: Color(0xFF292D45)))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const SizedBox(height: 22),
    const Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: Text('WORKSPACE', style: TextStyle(color: Color(0xFF77809F), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold))),
    const SizedBox(height: 12),
    _nav(Icons.dashboard_outlined, 'Dashboard', 0), _nav(Icons.point_of_sale, 'Sales center', 1), _nav(Icons.medication_outlined, 'Medicine stock', 2), _nav(Icons.bar_chart_rounded, 'Reports', 3),
    if (_isAdmin) ...[
      const Padding(padding: EdgeInsets.fromLTRB(18, 24, 18, 10), child: Text('ADMINISTRATION', style: TextStyle(color: Color(0xFF77809F), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold))),
      _nav(Icons.people_outline, 'Workers', 4, enabled: false), _nav(Icons.settings_outlined, 'Store settings', 5, enabled: false),
    ],
    const Spacer(),
    const Padding(padding: EdgeInsets.all(16), child: Text('OFFLINE MODE READY\nLocal-first workspace', style: TextStyle(color: Color(0xFF7D87A8), fontSize: 11, height: 1.6))),
  ]));

  Widget _nav(IconData icon, String label, int index, {bool enabled = true}) => ListTile(dense: true, enabled: enabled, selected: _index == index, selectedTileColor: const Color(0xFF292044), leading: Icon(icon, size: 19, color: _index == index ? const Color(0xFFB69AFF) : const Color(0xFF8992B2)), title: Text(label, style: const TextStyle(fontSize: 13)), onTap: enabled ? () => setState(() => _index = index) : null);

  Widget _dashboard() => LayoutBuilder(builder: (context, constraints) {
    final wide = constraints.maxWidth > 850;
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Pharmacy overview', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
      const SizedBox(height: 5), const Text('Your store at a glance • Offline data', style: TextStyle(color: Color(0xFF929BB9))),
      const SizedBox(height: 20),
      Wrap(spacing: 12, runSpacing: 12, children: [
        _metric('TODAY’S SALES', 'TZS 536,000', Icons.trending_up, const Color(0xFF28C6D5), constraints.maxWidth),
        if (_isAdmin) _metric('TODAY’S PROFIT', 'TZS 124,500', Icons.account_balance_wallet_outlined, const Color(0xFF9B72F5), constraints.maxWidth),
        _metric('TOTAL STOCK', '255 units', Icons.inventory_2_outlined, const Color(0xFF42C99A), constraints.maxWidth),
        _metric('RUNNING OUT', '02 items', Icons.warning_amber_rounded, const Color(0xFFFFB547), constraints.maxWidth),
      ]),
      const SizedBox(height: 18),
      if (wide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: _salesHighlights()), const SizedBox(width: 14), Expanded(flex: 2, child: _stockAlerts())])
      else ...[_salesHighlights(), const SizedBox(height: 14), _stockAlerts()],
      const SizedBox(height: 16),
      _sectionCard('QUICK ACTIONS', Wrap(spacing: 10, runSpacing: 10, children: [
        FilledButton.icon(onPressed: () => setState(() => _index = 1), icon: const Icon(Icons.search), label: const Text('Find & sell medicine')),
        if (_isAdmin) OutlinedButton.icon(onPressed: () => setState(() => _index = 2), icon: const Icon(Icons.add_box_outlined), label: const Text('Add new stock')),
      ])),
    ]));
  });

  Widget _metric(String label, String value, IconData icon, Color color, double width) => SizedBox(width: width > 1100 ? (width - 60) / 4 : width > 650 ? (width - 36) / 2 : width - 40, child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
    Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color)),
    const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9DA6C7), letterSpacing: 1)), const SizedBox(height: 7), Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)])),
  ]))));

  Widget _salesHighlights() => _sectionCard('TOP SELLING MEDICINES', Column(children: _medicines.take(4).map((m) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
    const Icon(Icons.medication, color: Color(0xFF9C7BFA), size: 19), const SizedBox(width: 10), Expanded(child: Text(m.name, style: const TextStyle(fontSize: 13))), Text(m.quantity.toString() + ' left', style: const TextStyle(color: Color(0xFF9DA6C7), fontSize: 12)),
  ])).toList()));

  Widget _stockAlerts() => _sectionCard('RUNNING OUT', Column(children: _medicines.where((m) => m.quantity <= m.reorderLevel + 3).map((m) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB547)), title: Text(m.name, style: const TextStyle(fontSize: 12)), subtitle: Text(m.quantity.toString() + ' units remaining', style: const TextStyle(fontSize: 11))).toList()));

  Widget _inventory() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Medicine inventory', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)), const SizedBox(height: 16),
    ..._medicines.map((m) => Card(child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFF292044), child: Icon(Icons.medication, color: Color(0xFFB69AFF))), title: Text(m.name), subtitle: Text('Selling: TZS ' + m.sellingPrice.toString() + '  •  Stock: ' + m.quantity.toString()), trailing: _isAdmin ? IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}) : const Icon(Icons.lock_outline))),
  ]);

  Widget _reports() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Sales reports', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)), const SizedBox(height: 10),
    Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Today’s activity'), const SizedBox(height: 12), const Text('TZS 536,000', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const Text('Total recorded sales', style: TextStyle(color: Color(0xFF9DA6C7))),
      if (_isAdmin) const Padding(padding: EdgeInsets.only(top: 18), child: Text('Gross profit  •  TZS 124,500', style: TextStyle(color: Color(0xFF45D6A1)))),
    ]))),
  ]);

  Widget _sectionCard(String title, Widget child) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 11, letterSpacing: 1.4, color: Color(0xFFA9B1D0), fontWeight: FontWeight.bold)), const SizedBox(height: 12), child])));
}

class MedicineSearchDelegate extends SearchDelegate<Medicine?> {
  MedicineSearchDelegate(this.items);
  final List<Medicine> items;
  @override String get searchFieldLabel => 'Search medicine name or barcode';
  @override List<Widget>? buildActions(BuildContext context) => [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];
  @override Widget? buildLeading(BuildContext context) => IconButton(onPressed: () => close(context, null), icon: const Icon(Icons.arrow_back));
  @override Widget buildResults(BuildContext context) => _results(context);
  @override Widget buildSuggestions(BuildContext context) => _results(context);
  Widget _results(BuildContext context) {
    final matches = items.where((m) => m.name.toLowerCase().contains(query.toLowerCase()) || (m.barcode ?? '').contains(query)).toList();
    return ListView(children: matches.map((m) => ListTile(leading: const Icon(Icons.medication_outlined), title: Text(m.name), subtitle: Text('TZS ' + m.sellingPrice.toString() + ' • ' + m.quantity.toString() + ' in stock'), onTap: () => close(context, m)).toList());
  }
}
