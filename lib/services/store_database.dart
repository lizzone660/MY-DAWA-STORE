import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class StoreDatabase {
  StoreDatabase._();
  static final StoreDatabase instance = StoreDatabase._();
  Database? _db;

  Future<void> _createCore(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE medicines(
      id TEXT PRIMARY KEY, name TEXT NOT NULL COLLATE NOCASE,
      purchase_price INTEGER NOT NULL CHECK(purchase_price >= 0),
      selling_price INTEGER NOT NULL CHECK(selling_price >= 0),
      quantity INTEGER NOT NULL CHECK(quantity >= 0), barcode TEXT,
      reorder_level INTEGER NOT NULL DEFAULT 5, updated_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE sales(
      id TEXT PRIMARY KEY, medicine_id TEXT NOT NULL, medicine_name TEXT NOT NULL,
      quantity INTEGER NOT NULL CHECK(quantity > 0), unit_selling_price INTEGER NOT NULL,
      unit_cost_snapshot INTEGER NOT NULL, sold_at TEXT NOT NULL, worker_id TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'pending')''');
    await db.execute('''CREATE TABLE audit_log(
      id TEXT PRIMARY KEY, actor_id TEXT NOT NULL, action TEXT NOT NULL,
      entity_type TEXT NOT NULL, entity_id TEXT NOT NULL, details TEXT NOT NULL,
      created_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE daily_closings(
      business_date TEXT PRIMARY KEY, total_sales INTEGER NOT NULL,
      gross_profit INTEGER NOT NULL, units_sold INTEGER NOT NULL,
      closed_at TEXT NOT NULL, email_status TEXT NOT NULL DEFAULT 'pending')''');
    await db.execute('''CREATE TABLE store_profile(
      id INTEGER PRIMARY KEY CHECK(id = 1), store_name TEXT NOT NULL,
      report_email TEXT NOT NULL DEFAULT '', opening_time TEXT NOT NULL DEFAULT '08:00',
      closing_time TEXT NOT NULL DEFAULT '20:00', timezone TEXT NOT NULL DEFAULT 'Africa/Dar_es_Salaam',
      created_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE store_users(
      id TEXT PRIMARY KEY, display_name TEXT NOT NULL, email TEXT NOT NULL COLLATE NOCASE UNIQUE,
      gender TEXT NOT NULL DEFAULT 'unspecified', role TEXT NOT NULL CHECK(role IN ('admin','worker')),
      password_salt TEXT NOT NULL, password_hash TEXT NOT NULL, is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE sync_outbox(
      id TEXT PRIMARY KEY, entity_type TEXT NOT NULL, entity_id TEXT NOT NULL,
      payload TEXT NOT NULL, created_at TEXT NOT NULL, attempts INTEGER NOT NULL DEFAULT 0,
      last_error TEXT)''');
    await db.execute('CREATE INDEX medicine_name_idx ON medicines(name)');
    await db.execute('CREATE INDEX sales_date_idx ON sales(sold_at)');
    await db.execute('CREATE INDEX users_email_idx ON store_users(email)');
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      p.join(dir.path, 'my_dawa_store.db'),
      version: 2,
      onCreate: (db, version) async => _createCore(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''CREATE TABLE store_profile(
            id INTEGER PRIMARY KEY CHECK(id = 1), store_name TEXT NOT NULL,
            report_email TEXT NOT NULL DEFAULT '', opening_time TEXT NOT NULL DEFAULT '08:00',
            closing_time TEXT NOT NULL DEFAULT '20:00', timezone TEXT NOT NULL DEFAULT 'Africa/Dar_es_Salaam',
            created_at TEXT NOT NULL)''');
          await db.execute('''CREATE TABLE store_users(
            id TEXT PRIMARY KEY, display_name TEXT NOT NULL, email TEXT NOT NULL COLLATE NOCASE UNIQUE,
            gender TEXT NOT NULL DEFAULT 'unspecified', role TEXT NOT NULL CHECK(role IN ('admin','worker')),
            password_salt TEXT NOT NULL, password_hash TEXT NOT NULL, is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL)''');
          await db.execute('''CREATE TABLE sync_outbox(
            id TEXT PRIMARY KEY, entity_type TEXT NOT NULL, entity_id TEXT NOT NULL,
            payload TEXT NOT NULL, created_at TEXT NOT NULL, attempts INTEGER NOT NULL DEFAULT 0,
            last_error TEXT)''');
          await db.execute('CREATE INDEX users_email_idx ON store_users(email)');
        }
      },
    );
    return _db!;
  }
}
