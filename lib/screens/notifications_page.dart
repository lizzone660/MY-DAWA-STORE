import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/store_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _repository = StoreRepository();
  late Future<List<Medicine>> _future;
  @override
  void initState() {
    super.initState();
    _future = _repository.medicines();
  }
  Future<void> _refresh() async {
    setState(() => _future = _repository.medicines());
    await _future;
  }
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _refresh,
    child: FutureBuilder<List<Medicine>>(
      future: _future,
      builder: (context, snapshot) {
        final medicines = snapshot.data ?? const <Medicine>[];
        final low = medicines.where((m) => m.quantity <= m.reorderLevel).toList();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Notifications & alerts', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            const Text('Live alerts calculated from this device’s medicine inventory.', style: TextStyle(color: Color(0xFF929BB9), fontSize: 12)),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (snapshot.hasError)
              Card(child: ListTile(leading: const Icon(Icons.error_outline, color: Colors.orange), title: const Text('Could not load inventory alerts'), subtitle: Text(snapshot.error.toString()), trailing: IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))))
            else ...[
              Card(child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined, color: Color(0xFFFFB547)),
                title: const Text('Low-stock medicines'),
                subtitle: Text('${low.length} medicine(s) at or below reorder level'),
                trailing: IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
              )),
              if (low.isEmpty)
                const Card(child: ListTile(leading: Icon(Icons.check_circle_outline, color: Color(0xFF42C99A)), title: Text('No low-stock alerts'), subtitle: Text('All recorded medicines are above their reorder levels.')))
              else
                ...low.map((m) => Card(child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB547)),
                  title: Text(m.name),
                  subtitle: Text('Available: ${m.quantity} • Reorder level: ${m.reorderLevel}'),
                ))),
              const SizedBox(height: 12),
              const Card(child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Expiry and payment alerts'),
                subtitle: Text('These alerts will appear after batch expiry dates and customer/supplier payment records are implemented. No expiry or debt status is being guessed.'),
              )),
            ],
          ],
        );
      },
    ),
  );
}
