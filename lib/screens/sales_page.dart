import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/medicine.dart';
import '../models/sale.dart';
import '../services/store_repository.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key, required this.medicines, required this.isAdmin, required this.actorId, required this.onSaleRecorded});
  final List<Medicine> medicines;
  final bool isAdmin;
  final String actorId;
  final VoidCallback onSaleRecorded;
  @override State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final List<_CartLine> _cart = [];
  final _repository = StoreRepository();
  static const _uuid = Uuid();
  String _money(int value) => 'TZS ' + value.toString();

  List<Medicine> get _matches {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return widget.medicines;
    return widget.medicines.where((m) => m.name.toLowerCase().contains(q) || (m.barcode ?? '').contains(q)).toList();
  }

  void _add(Medicine medicine) {
    if (medicine.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No stock available for this medicine.')));
      return;
    }
    final existing = _cart.indexWhere((e) => e.medicine.id == medicine.id);
    setState(() {
      if (existing >= 0) { if (_cart[existing].quantity < medicine.quantity) _cart[existing].quantity++; }
      else { _cart.add(_CartLine(medicine: medicine)); }
    });
  }

  int get _total => _cart.fold(0, (sum, line) => sum + line.quantity * line.unitPrice);
  int get _profit => _cart.fold(0, (sum, line) => sum + line.quantity * (line.unitPrice - line.medicine.purchasePrice));
  @override void dispose() { _search.dispose(); _searchFocus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    final wide = box.maxWidth > 900;
    return Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Sales center', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)), Text('Search, add quantities and record a sale quickly', style: TextStyle(color: Color(0xFF929BB9), fontSize: 12))])),
        IconButton.filledTonal(onPressed: () => _searchFocus.requestFocus(), icon: const Icon(Icons.search), tooltip: 'Search medicine'),
      ]),
      const SizedBox(height: 16),
      Expanded(child: wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: _catalog()), const SizedBox(width: 14), Expanded(flex: 2, child: _checkout())]) : Column(children: [Expanded(flex: 3, child: _catalog()), const SizedBox(height: 12), Expanded(flex: 2, child: _checkout())])),
    ]));
  });

  Widget _catalog() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
    TextField(focusNode: _searchFocus, controller: _search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Type medicine name or scan barcode...', suffixIcon: Icon(Icons.qr_code_scanner))),
    const SizedBox(height: 10),
    Expanded(child: _matches.isEmpty ? const Center(child: Text('No medicine found. Check spelling or ask admin to add stock.')) : ListView.separated(
      itemCount: _matches.length, separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF292D45)),
      itemBuilder: (context, index) {
        final m = _matches[index];
        return ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 4), leading: const CircleAvatar(backgroundColor: Color(0xFF292044), child: Icon(Icons.medication_outlined, color: Color(0xFFB69AFF))), title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), subtitle: Text('Stock ' + m.quantity.toString() + ' • ' + _money(m.sellingPrice), style: const TextStyle(fontSize: 11)), trailing: IconButton.filledTonal(onPressed: m.quantity > 0 ? () => _add(m) : null, icon: const Icon(Icons.add)));
      },
    )),
  ])));

  Widget _checkout() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const Expanded(child: Text('CURRENT SALE', style: TextStyle(letterSpacing: 1.4, fontWeight: FontWeight.bold, fontSize: 11))), Text(_cart.length.toString() + ' items', style: const TextStyle(color: Color(0xFF9DA6C7), fontSize: 11))]),
    const Divider(height: 20),
    Expanded(child: _cart.isEmpty ? const Center(child: Text('Search for a medicine and tap + to add it.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF929BB9)))) : ListView(children: _cart.map(_cartLine).toList())),
    const Divider(height: 20),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL', style: TextStyle(color: Color(0xFF9DA6C7), letterSpacing: 1.2)), Text(_money(_total), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900))]),
    if (widget.isAdmin) Padding(padding: const EdgeInsets.only(top: 5), child: Text('Estimated gross profit: ' + _money(_profit), style: const TextStyle(color: Color(0xFF45D6A1), fontSize: 12))),
    const SizedBox(height: 12),
    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _cart.isEmpty ? null : _confirmSale, icon: const Icon(Icons.check_circle_outline), label: const Text('CONFIRM SALE'))),
  ])));

  Widget _cartLine(_CartLine line) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(line.medicine.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), Text(_money(line.unitPrice), style: const TextStyle(fontSize: 11, color: Color(0xFF929BB9)))])),
    IconButton(onPressed: line.quantity > 1 ? () => setState(() => line.quantity--) : null, icon: const Icon(Icons.remove_circle_outline, size: 19)),
    Text(line.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
    IconButton(onPressed: () => setState(() { if (line.quantity < line.medicine.quantity) line.quantity++; }), icon: const Icon(Icons.add_circle_outline, size: 19)),
    IconButton(onPressed: () => setState(() => _cart.remove(line)), icon: const Icon(Icons.close, size: 17)),
  ]));

  Future<void> _confirmSale() async {
    final invalid = _cart.any((line) => line.quantity > line.medicine.quantity || line.unitPrice < 0);
    if (invalid) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale cannot be completed: check stock and price.'))); return; }
    final total = _total;
    final count = _cart.length;
    final now = DateTime.now();
    final saleLines = _cart.map((line) => Sale(
      id: _uuid.v4(),
      medicineId: line.medicine.id,
      medicineName: line.medicine.name,
      quantity: line.quantity,
      unitSellingPrice: line.unitPrice,
      unitCostSnapshot: line.medicine.purchasePrice,
      soldAt: now,
      workerId: widget.actorId,
    )).toList();
    try {
      await _repository.recordSale(lines: saleLines, actorId: widget.actorId);
      if (!mounted) return;
      setState(() => _cart.clear());
      widget.onSaleRecorded();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sale saved offline: ' + count.toString() + ' medicine types • ' + _money(total))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sale not saved: ' + error.toString())));
    }
  }
}

class _CartLine {
  _CartLine({required this.medicine}) : unitPrice = medicine.sellingPrice;
  final Medicine medicine;
  int quantity = 1;
  int unitPrice;
}
