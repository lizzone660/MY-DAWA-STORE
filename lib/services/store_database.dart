import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class StoreDatabase {
  StoreDatabase._();
  static final StoreDatabase instance = StoreDatabase._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      p.join(dir.path, 'my_dawa_store.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE medicines(
            id TEXT PRIMARY KEY, name TEXT NOT NULL COLLATE NOCASE,
            purchase_price INTEGER NOT NULL CHECK(purchase_price >= 0),
            selling_price INTEGER NOT NULL CHECK(selling_price >= 0),
            quantity INTEGER NOT NULL CHECK(quantity >= 0),
            barcode TEXT, reorder_level INTEGER NOT NULL DEFAULT 5,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sales(
            id TEXT PRIMARY KEY, medicine_id TEXT NOT NULL,
            medicine_name TEXT NOT NULL, quantity INTEGER NOT NULL CHECK(quantity > 0),
            unit_selling_price INTEGER NOT NULL, unit_cost_snapshot INTEGER NOT NULL,
            sold_at TEXT NOT NULL, worker_id TEXT NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending'
          )
        ''');
        await db.execute('''
          CREATE TABLE audit_log(
            id TEXT PRIMARY KEY, actor_id TEXT NOT NULL, action TEXT NOT NULL,
            entity_type TEXT NOT NULL, entity_id TEXT NOT NULL,
            details TEXT NOT NULL, created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE daily_closings(
            business_date TEXT PRIMARY KEY, total_sales INTEGER NOT NULL,
            gross_profit INTEGER NOT NULL, units_sold INTEGER NOT NULL,
            closed_at TEXT NOT NULL, email_status TEXT NOT NULL DEFAULT 'pending'
          )
        ''');
        await db.execute('CREATE INDEX medicine_name_idx ON medicines(name)');
        await db.execute('CREATE INDEX sales_date_idx ON sales(sold_at)');
      },
    );
    return _db!;
  }
}
