import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'store_database.dart';
import 'store_repository.dart';

class WeeklyStockAlertService {
  WeeklyStockAlertService({StoreDatabase? database, StoreRepository? repository})
      : _database = database ?? StoreDatabase.instance,
        _repository = repository ?? StoreRepository();
  final StoreDatabase _database;
  final StoreRepository _repository;
  static const _uuid = Uuid();

  Future<bool> queueIfDue({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final week = _isoWeekKey(current);
    final db = await _database.database;
    final prior = await db.query('sync_outbox', columns:['id'],
      where:'entity_type = ? AND entity_id = ?', whereArgs:['weekly_stock_alert',week], limit:1);
    if (prior.isNotEmpty) return false;
    final metrics = await _repository.dashboardMetrics(now:current);
    final low = (metrics['lowStock'] as List).map((m) => {'name':m.name,'quantity':m.quantity,'reorderLevel':m.reorderLevel}).toList();
    final fast = (metrics['hotSales'] as List).map((m) => {'name':m.name,'quantity':m.quantity}).toList();
    final slow = (metrics['slowSales'] as List).map((m) => {'name':m.name,'quantity':m.quantity}).toList();
    final dormant = (metrics['dormant'] as List).map((m) => {'name':m.name,'quantity':m.quantity}).toList();
    final profile = await db.query('store_profile',where:'id = 1',limit:1);
    final reportEmail = profile.isEmpty ? '' : (profile.first['report_email'] as String? ?? '');
    await db.insert('sync_outbox',{
      'id':_uuid.v4(),'entity_type':'weekly_stock_alert','entity_id':week,
      'payload':jsonEncode({'week':week,'reportEmail':reportEmail,'lowStock':low,
        'fastMoving':fast,'slowMoving':slow,'dormant':dormant}),
      'created_at':current.toIso8601String(),
    });
    return true;
  }

  String _isoWeekKey(DateTime date) {
    final utc = DateTime.utc(date.year,date.month,date.day);
    final weekday = utc.weekday;
    final thursday = utc.add(Duration(days:4-weekday));
    final firstThursday = DateTime.utc(thursday.year,1,4);
    final week = 1 + (thursday.difference(firstThursday).inDays ~/ 7);
    return '${thursday.year}-W${week.toString().padLeft(2,'0')}';
  }
}
