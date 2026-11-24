import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'store_database.dart';

class LocalUser {
  const LocalUser({required this.id, required this.name, required this.email, required this.role, required this.gender});
  final String id, name, email, role, gender;
  bool get isAdmin => role == 'admin';
}

class AuthRepository {
  AuthRepository({StoreDatabase? database}) : _database = database ?? StoreDatabase.instance;
  final StoreDatabase _database;
  static const _uuid = Uuid();
  static final _kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 120000, bits: 256);

  Future<String> _hash(String password, List<int> salt) async {
    final key = await _kdf.deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
    return base64Encode(await key.extractBytes());
  }

  Future<bool> needsSetup() async {
    final db = await _database.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM store_users');
    return (rows.first['n'] as int) == 0;
  }

  Future<void> createStore({
    required String storeName, required String ownerName, required String email,
    required String password, required String gender, required String reportEmail,
    required String openingTime, required String closingTime,
  }) async {
    if (storeName.trim().isEmpty || ownerName.trim().isEmpty || !_validEmail(email) || password.length < 10 ||
        !_validTime(openingTime) || !_validTime(closingTime) ||
        (reportEmail.trim().isNotEmpty && !_validEmail(reportEmail))) {
      throw ArgumentError('Provide valid store/owner details, email, password (10+ characters), and HH:mm opening/closing times.');
    }
    final db = await _database.database;
    await db.transaction((txn) async {
      final count = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM store_users')) ?? 0;
      if (count > 0) throw StateError('Store setup has already been completed.');
      final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
      await txn.insert('store_profile', {
        'id': 1, 'store_name': storeName.trim(), 'report_email': reportEmail.trim(),
        'opening_time': openingTime, 'closing_time': closingTime,
        'timezone': 'Africa/Dar_es_Salaam', 'created_at': DateTime.now().toIso8601String(),
      });
      await txn.insert('store_users', {
        'id': _uuid.v4(), 'display_name': ownerName.trim(), 'email': email.trim().toLowerCase(),
        'gender': gender, 'role': 'admin', 'password_salt': base64Encode(salt),
        'password_hash': await _hash(password, salt), 'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<LocalUser?> signIn(String email, String password) async {
    final db = await _database.database;
    final rows = await db.query('store_users', where: 'email = ? AND is_active = 1', whereArgs: [email.trim().toLowerCase()], limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final salt = base64Decode(row['password_salt'] as String);
    final candidate = await _hash(password, salt);
    if (candidate != row['password_hash']) return null;
    return LocalUser(id: row['id'] as String, name: row['display_name'] as String,
      email: row['email'] as String, role: row['role'] as String, gender: row['gender'] as String);
  }

  Future<void> addWorker({required String name, required String email, required String password, required String actorId}) async {
    if (name.trim().isEmpty || !_validEmail(email) || password.length < 10) {
      throw ArgumentError('Enter a worker name, valid email and password of at least 10 characters.');
    }
    final db = await _database.database;
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    await db.transaction((txn) async {
      final actor = await txn.query('store_users', columns: ['role','is_active'], where: 'id = ?', whereArgs: [actorId], limit: 1);
      if (actor.isEmpty || actor.first['role'] != 'admin' || actor.first['is_active'] != 1) {
        throw StateError('Only an active administrator can create worker accounts.');
      }
      await txn.insert('store_users', {
        'id': _uuid.v4(), 'display_name': name.trim(), 'email': email.trim().toLowerCase(),
        'gender': 'unspecified', 'role': 'worker', 'password_salt': base64Encode(salt),
        'password_hash': await _hash(password, salt), 'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
      await txn.insert('audit_log', {
        'id': _uuid.v4(), 'actor_id': actorId, 'action': 'WORKER_CREATED',
        'entity_type': 'user', 'entity_id': email.trim().toLowerCase(),
        'details': 'Created worker account', 'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<bool> verifyAdmin(String email, String password) async {
    final user = await signIn(email, password);
    return user?.isAdmin ?? false;
  }

  Future<Map<String, String>> storeProfile() async {
    final db = await _database.database;
    final rows = await db.query('store_profile', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return {};
    return rows.first.map((key, value) => MapEntry(key, value?.toString() ?? ''));
  }

  bool _validEmail(String value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+
}
).hasMatch(value.trim());
  bool _validTime(String value) => RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d
}
).hasMatch(value.trim());
}
