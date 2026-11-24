import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'store_database.dart';
import 'store_repository.dart';

class DailyClosingService {
  DailyClosingService({StoreDatabase? database, StoreRepository? repository})
      : _database = database ?? StoreDatabase.instance,
        _repository = repository ?? StoreRepository();
  final StoreDatabase _database;
  final StoreRepository _repository;
  static const _uuid = Uuid();

  Future<bool> closeIfDue({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final db = await _database.database;
    final profile = await db.query('store_profile', where: 'id = 1', limit: 1);
    if (profile.isEmpty) return false;
    final closing = (profile.first['closing_time'] as String).split(':');
    final hour = int.tryParse(closing.first) ?? 20;
    final minute = closing.length > 1 ? int.tryParse(closing[1]) ?? 0 : 0;
    final due = current.hour > hour || (current.hour == hour && current.minute >= minute);
    if (!due) return false;
    return closeDate(DateTime(current.year, current.month, current.day));
  }

  Future<bool> closePreviousDay({DateTime? now}) async {
    final current = now ?? DateTime.now();
    return closeDate(DateTime(current.year, current.month, current.day).subtract(const Duration(days: 1)));
  }

  Future<bool> closeDate(DateTime day) async {
    final db = await _database.database;
    final dateKey = _dateKey(day);
    final existing = await db.query('daily_closings', where: 'business_date = ?', whereArgs: [dateKey], limit: 1);
    if (existing.isNotEmpty) return false;
    final totals = await _repository.dailyTotals(day);
    final profile = await db.query('store_profile', where: 'id = 1', limit: 1);
    final closedAt = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      final duplicate = await txn.query('daily_closings', where: 'business_date = ?', whereArgs: [dateKey], limit: 1);
      if (duplicate.isNotEmpty) return;
      await txn.insert('daily_closings', {
        'business_date': dateKey,
        'total_sales': totals['revenue'] ?? 0,
        'gross_profit': totals['grossProfit'] ?? 0,
        'units_sold': totals['units'] ?? 0,
        'closed_at': closedAt,
        'email_status': 'pending',
      });
      await txn.insert('sync_outbox', {
        'id': _uuid.v4(),
        'entity_type': 'daily_report_email',
        'entity_id': dateKey,
        'payload': jsonEncode({
          'date': dateKey,
          'revenue': totals['revenue'] ?? 0,
          'grossProfit': totals['grossProfit'] ?? 0,
          'unitsSold': totals['units'] ?? 0,
          'reportEmail': (profile.first['report_email'] as String?) ?? '',
          'storeName': (profile.first['store_name'] as String?) ?? 'MY DAWA STORE',
        }),
        'created_at': closedAt,
      });
      await txn.insert('audit_log', {
        'id': _uuid.v4(), 'actor_id': 'system', 'action': 'DAILY_CLOSE',
        'entity_type': 'daily_closing', 'entity_id': dateKey,
        'details': 'Closed daily totals; email queued pending connectivity service',
        'created_at': closedAt,
      });
    });
    return true;
  }

  Future<List<Map<String, Object?>>> recentClosings({int limit = 30}) async {
    final db = await _database.database;
    return db.query('daily_closings', orderBy: 'business_date DESC', limit: limit);
  }

  String _dateKey(DateTime date) => date.year.toString().padLeft(4, '0') + '-' +
      date.month.toString().padLeft(2, '0') + '-' + date.day.toString().padLeft(2, '0');
}
