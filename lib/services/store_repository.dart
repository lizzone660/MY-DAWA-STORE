import 'dart:convert';
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
    final rows = await db.query('medicines',
      where: q == null || q.isEmpty ? null : 'name LIKE ? OR barcode LIKE ?',
      whereArgs: q == null || q.isEmpty ? null : ['%' + q + '%', '%' + q + '%'],
      orderBy: 'name COLLATE NOCASE');
    return rows.map((r) => Medicine(
      id: r['id'] as String, name: r['name'] as String,
      purchasePrice: r['purchase_price'] as int, sellingPrice: r['selling_price'] as int,
      quantity: r['quantity'] as int, barcode: r['barcode'] as String?,
      reorderLevel: r['reorder_level'] as int)).toList();
  }

  Future<void> saveMedicine(Medicine medicine, {required String actorId}) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await _requireAdmin(txn, actorId);
      await txn.insert('medicines', {
        'id': medicine.id, 'name': medicine.name.trim(),
        'purchase_price': medicine.purchasePrice, 'selling_price': medicine.sellingPrice,
        'quantity': medicine.quantity, 'barcode': medicine.barcode,
        'reorder_level': medicine.reorderLevel, 'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('audit_log', {
        'id': _uuid.v4(), 'actor_id': actorId, 'action': 'MEDICINE_SAVED',
        'entity_type': 'medicine', 'entity_id': medicine.id,
        'details': 'Saved inventory item: ' + medicine.name,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> _requireAdmin(DatabaseExecutor db, String actorId) async {
    final users = await db.query('store_users', columns: ['role','is_active'],
      where: 'id = ?', whereArgs: [actorId], limit: 1);
    if (users.isEmpty || users.first['is_active'] != 1 || users.first['role'] != 'admin') {
      throw StateError('Sorry, you are not an active administrator.');
    }
  }

  Future<void> recordSale({required List<Sale> lines, required String actorId}) async {
    if (lines.isEmpty) throw ArgumentError('A sale must contain at least one line.');
    final db = await _database.database;
    await db.transaction((txn) async {
      final actor = await txn.query('store_users', columns: ['is_active','role'],
        where: 'id = ?', whereArgs: [actorId], limit: 1);
      if (actor.isEmpty || actor.first['is_active'] != 1 ||
          !['admin','worker'].contains(actor.first['role'])) {
        throw StateError('A valid signed-in staff account is required.');
      }
      for (final line in lines) {
        if (line.quantity <= 0 || line.unitSellingPrice < 0 || line.unitCostSnapshot < 0) {
          throw ArgumentError('Sale quantity and prices must be valid non-negative values.');
        }
        final rows = await txn.query('medicines', columns: ['quantity'],
          where: 'id = ?', whereArgs: [line.medicineId], limit: 1);
        if (rows.isEmpty) throw StateError('Medicine no longer exists: ' + line.medicineName);
        final available = rows.first['quantity'] as int;
        if (line.quantity > available) {
          throw StateError('Insufficient stock for ' + line.medicineName + '. Available: ' + available.toString());
        }
      }
      for (final line in lines) {
        await txn.insert('sales', {
          'id': line.id, 'medicine_id': line.medicineId, 'medicine_name': line.medicineName,
          'quantity': line.quantity, 'unit_selling_price': line.unitSellingPrice,
          'unit_cost_snapshot': line.unitCostSnapshot, 'sold_at': line.soldAt.toIso8601String(),
          'worker_id': actorId, 'sync_status': 'pending',
        });
        final changed = await txn.rawUpdate(
          'UPDATE medicines SET quantity = quantity - ?, updated_at = ? WHERE id = ? AND quantity >= ?',
          [line.quantity, DateTime.now().toIso8601String(), line.medicineId, line.quantity]);
        if (changed != 1) throw StateError('Stock changed during sale. Please retry.');
        await txn.insert('sync_outbox', {
          'id': _uuid.v4(), 'entity_type': 'sale', 'entity_id': line.id,
          'payload': jsonEncode({'id':line.id,'medicineId':line.medicineId,'medicineName':line.medicineName,
            'quantity':line.quantity,'unitSellingPrice':line.unitSellingPrice,
            'unitCostSnapshot':line.unitCostSnapshot,'soldAt':line.soldAt.toIso8601String(),'workerId':actorId}),
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      await txn.insert('audit_log', {
        'id': _uuid.v4(), 'actor_id': actorId, 'action': 'SALE_RECORDED',
        'entity_type': 'sale', 'entity_id': lines.first.id,
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
      'SELECT COALESCE(SUM(quantity * unit_selling_price),0) revenue, '
      'COALESCE(SUM(quantity * (unit_selling_price-unit_cost_snapshot)),0) gross_profit, '
      'COALESCE(SUM(quantity),0) units FROM sales WHERE sold_at >= ? AND sold_at < ?',[start,end]);
    final row = rows.first;
    return {'revenue':(row['revenue'] as num).toInt(),
      'grossProfit':(row['gross_profit'] as num).toInt(),'units':(row['units'] as num).toInt()};
  }

  Future<Map<String, Object>> dashboardMetrics({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final today = await dailyTotals(current);
    final db = await _database.database;
    final stock = await db.rawQuery('SELECT COUNT(*) medicine_count, COALESCE(SUM(quantity),0) stock_units FROM medicines');
    final items = await medicines();
    final low = items.where((m) => m.quantity <= m.reorderLevel).toList();
    final weekStart = DateTime(current.year,current.month,current.day).subtract(const Duration(days:6));
    final velocity = await db.rawQuery(
      'SELECT medicine_id, medicine_name, SUM(quantity) units, MAX(sold_at) last_sold '
      'FROM sales WHERE sold_at >= ? GROUP BY medicine_id, medicine_name ORDER BY units DESC',
      [weekStart.toIso8601String()]);
    final unitsById = <String,int>{};
    final lastById = <String,DateTime>{};
    for (final row in velocity) {
      unitsById[row['medicine_id'] as String] = (row['units'] as num).toInt();
      final raw = row['last_sold'] as String?;
      if (raw != null) lastById[row['medicine_id'] as String] = DateTime.tryParse(raw) ?? current;
    }
    final hot = <Medicine>[], medium = <Medicine>[], slow = <Medicine>[], dormant = <Medicine>[];
    for (final m in items) {
      final units = unitsById[m.id] ?? 0;
      final last = lastById[m.id];
      if (last == null || current.difference(last).inDays >= 30) {
        dormant.add(m);
      } else if (units >= 15) {
        hot.add(m);
      } else if (units >= 4) {
        medium.add(m);
      } else {
        slow.add(m);
      }
    }
    final s = stock.first;
    return {
      'revenue':today['revenue']!, 'profit':today['grossProfit']!, 'unitsSold':today['units']!,
      'medicineCount':(s['medicine_count'] as num).toInt(),
      'stockUnits':(s['stock_units'] as num).toInt(), 'lowStock':low,
      'hotSales':hot, 'mediumSales':medium, 'slowSales':slow, 'dormant':dormant,
    };
  }

  Future<List<Map<String,Object?>>> salesForDay(DateTime day) async {
    final db = await _database.database;
    final start = DateTime(day.year,day.month,day.day).toIso8601String();
    final end = DateTime(day.year,day.month,day.day).add(const Duration(days:1)).toIso8601String();
    return db.query('sales',where:'sold_at >= ? AND sold_at < ?',whereArgs:[start,end],orderBy:'sold_at DESC');
  }
}
