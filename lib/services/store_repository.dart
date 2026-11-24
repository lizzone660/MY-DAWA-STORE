import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/medicine.dart';
import '../models/sale.dart';
import 'store_database.dart';

class StoreRepository {
  StoreRepository({StoreDatabase? database}) : _database = database ?? StoreDatabase.instance;
  final StoreDatabase _database;
  static const _uuid = Uuid();

  Future<List<Medicine>> medicines({String? search}) async {
    final db = await _database.database;
    final q = search?.trim();
    final rows = await db.query(
      'medicines',
      where: q == null || q.isEmpty ? null : 'name LIKE ? OR barcode LIKE ?',
      whereArgs: q == null || q.isEmpty ? null : ['%' + q + '%', '%' + q + '%'],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map((r) => Medicine(
      id: r['id'] as String,
      name: r['name'] as String,
      purchasePrice: r['purchase_price'] as int,
      sellingPrice: r['selling_price'] as int,
      quantity: r['quantity'] as int,
      barcode: r['barcode'] as String?,
      reorderLevel: r['reorder_level'] as int,
    )).toList();
  }

  Future<void> saveMedicine(Medicine medicine) async {
    final db = await _database.database;
    await db.insert('medicines', {
      'id': medicine.id,
      'name': medicine.name.trim(),
      'purchase_price': medicine.purchasePrice,
      'selling_price': medicine.sellingPrice,
      'quantity': medicine.quantity,
      'barcode': medicine.barcode,
      'reorder_level': medicine.reorderLevel,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Atomically verifies stock, writes immutable sale snapshots, and deducts stock.
  /// Any insufficient-stock line rolls back the entire sale.
  Future<void> recordSale({
    required List<Sale> lines,
    required String actorId,
  }) async {
    if (lines.isEmpty) throw ArgumentError('A sale must contain at least one line.');
    final db = await _database.database;
    await db.transaction((txn) async {
      for (final line in lines) {
        final rows = await txn.query('medicines', columns: ['quantity'], where: 'id = ?', whereArgs: [line.medicineId], limit: 1);
        if (rows.isEmpty) throw StateError('Medicine no longer exists: ' + line.medicineName);
        final available = rows.first['quantity'] as int;
        if (line.quantity <= 0 || line.quantity > available) {
          throw StateError('Insufficient stock for ' + line.medicineName + '. Available: ' + available.toString());
        }
      }
      for (final line in lines) {
        await txn.insert('sales', {
          'id': line.id,
          'medicine_id': line.medicineId,
          'medicine_name': line.medicineName,
          'quantity': line.quantity,
          'unit_selling_price': line.unitSellingPrice,
          'unit_cost_snapshot': line.unitCostSnapshot,
          'sold_at': line.soldAt.toIso8601String(),
          'worker_id': actorId,
          'sync_status': 'pending',
        });
        final changed = await txn.rawUpdate(
          'UPDATE medicines SET quantity = quantity - ?, updated_at = ? WHERE id = ? AND quantity >= ?',
          [line.quantity, DateTime.now().toIso8601String(), line.medicineId, line.quantity],
        );
        if (changed != 1) throw StateError('Stock changed during sale. Please retry.');
      }
      await txn.insert('audit_log', {
        'id': _uuid.v4(),
        'actor_id': actorId,
        'action': 'SALE_RECORDED',
        'entity_type': 'sale',
        'entity_id': lines.first.id,
        'details': 'Recorded ' + lines.length.toString() + ' sale line(s)',
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<Map<String, int>> dailyTotals(DateTime day) async {
    final db = await _database.database;
    final start = DateTime(day.year, day.month, day.day).toIso8601String();
    final end = DateTime(day.year, day.month, day.day).add(const Duration(days: 1)).toIso8601String();
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(quantity * unit_selling_price), 0) AS revenue, COALESCE(SUM(quantity * (unit_selling_price - unit_cost_snapshot)), 0) AS gross_profit, COALESCE(SUM(quantity), 0) AS units FROM sales WHERE sold_at >= ? AND sold_at < ?',
      [start, end],
    );
    final row = rows.first;
    return {
      'revenue': (row['revenue'] as num).toInt(),
      'grossProfit': (row['gross_profit'] as num).toInt(),
      'units': (row['units'] as num).toInt(),
    };
  }
}
