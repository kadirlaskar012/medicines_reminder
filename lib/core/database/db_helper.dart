import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../models/user_profile.dart';
import '../../models/medicine.dart';
import '../../models/reminder_time.dart';
import '../../models/intake_record.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mediremind.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE profiles ADD COLUMN age INTEGER');
      } catch (e) {
        // Ignored if column already exists
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE medicines ADD COLUMN durationDays INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE medicines ADD COLUMN startDate TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE medicines ADD COLUMN endDate TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE medicines ADD COLUMN expiryDate TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE medicines ADD COLUMN photoPath TEXT');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute("ALTER TABLE medicines ADD COLUMN unit TEXT DEFAULT ''");
      } catch (_) {}
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Profiles Table
    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        relation TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        avatarEmoji TEXT NOT NULL,
        age INTEGER
      )
    ''');

    // 2. Medicines Table
    await db.execute('''
      CREATE TABLE medicines (
        id TEXT PRIMARY KEY,
        profileId TEXT NOT NULL,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        type TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        instruction TEXT NOT NULL,
        currentStock INTEGER NOT NULL,
        refillThreshold INTEGER NOT NULL,
        isActive INTEGER NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        durationDays INTEGER DEFAULT 0,
        startDate TEXT,
        endDate TEXT,
        expiryDate TEXT,
        photoPath TEXT,
        unit TEXT DEFAULT ''
      )
    ''');

    // 3. Reminder Times Table
    await db.execute('''
      CREATE TABLE reminder_times (
        id TEXT PRIMARY KEY,
        medicineId TEXT NOT NULL,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        daysOfWeek TEXT NOT NULL,
        isAlarm INTEGER NOT NULL,
        notificationId INTEGER NOT NULL,
        FOREIGN KEY (medicineId) REFERENCES medicines (id) ON DELETE CASCADE
      )
    ''');

    // 4. Intake Records Table
    await db.execute('''
      CREATE TABLE intake_records (
        id TEXT PRIMARY KEY,
        medicineId TEXT NOT NULL,
        reminderTimeId TEXT NOT NULL,
        scheduledDate TEXT NOT NULL,
        scheduledHour INTEGER NOT NULL,
        scheduledMinute INTEGER NOT NULL,
        status TEXT NOT NULL,
        recordedAt TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Insert Default Profile
    await db.insert('profiles', UserProfile.defaultProfile.toMap());
  }

  // ==================== PROFILES ====================
  Future<List<UserProfile>> getAllProfiles() async {
    final db = await database;
    final res = await db.query('profiles');
    return res.map((m) => UserProfile.fromMap(m)).toList();
  }

  Future<int> insertProfile(UserProfile profile) async {
    final db = await database;
    return await db.insert('profiles', profile.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteProfile(String id) async {
    if (id == 'default_me') return 0; // Prevent deleting default profile
    final db = await database;
    return await db.delete('profiles', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== MEDICINES ====================
  Future<List<Medicine>> getAllMedicines({String? profileId}) async {
    final db = await database;
    final List<Map<String, dynamic>> res;
    if (profileId != null && profileId.isNotEmpty && profileId != 'all') {
      res = await db.query('medicines', where: 'profileId = ?', whereArgs: [profileId], orderBy: 'createdAt DESC');
    } else {
      res = await db.query('medicines', orderBy: 'createdAt DESC');
    }
    return res.map((m) => Medicine.fromMap(m)).toList();
  }

  Future<Medicine?> getMedicineById(String id) async {
    final db = await database;
    final res = await db.query('medicines', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      return Medicine.fromMap(res.first);
    }
    return null;
  }

  Future<void> insertMedicine(Medicine medicine, List<ReminderTime> reminders) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('medicines', medicine.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      for (final r in reminders) {
        await txn.insert('reminder_times', r.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> updateMedicine(Medicine medicine, List<ReminderTime> reminders) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('medicines', medicine.toMap(), where: 'id = ?', whereArgs: [medicine.id]);
      await txn.delete('reminder_times', where: 'medicineId = ?', whereArgs: [medicine.id]);
      for (final r in reminders) {
        await txn.insert('reminder_times', r.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> deleteMedicine(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('reminder_times', where: 'medicineId = ?', whereArgs: [id]);
      await txn.delete('intake_records', where: 'medicineId = ?', whereArgs: [id]);
      await txn.delete('medicines', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> updateStock(String medicineId, int newStock) async {
    final db = await database;
    await db.update('medicines', {'currentStock': newStock}, where: 'id = ?', whereArgs: [medicineId]);
  }

  // ==================== REMINDERS ====================
  Future<List<ReminderTime>> getRemindersForMedicine(String medicineId) async {
    final db = await database;
    final res = await db.query('reminder_times', where: 'medicineId = ?', whereArgs: [medicineId]);
    return res.map((m) => ReminderTime.fromMap(m)).toList();
  }

  Future<List<ReminderTime>> getAllReminders() async {
    final db = await database;
    final res = await db.query('reminder_times');
    return res.map((m) => ReminderTime.fromMap(m)).toList();
  }

  // ==================== INTAKE RECORDS ====================
  Future<List<IntakeRecord>> getRecordsForDate(String dateStr) async {
    final db = await database;
    final res = await db.query('intake_records', where: 'scheduledDate = ?', whereArgs: [dateStr]);
    return res.map((m) => IntakeRecord.fromMap(m)).toList();
  }

  Future<List<IntakeRecord>> getAllRecords({int limit = 100}) async {
    final db = await database;
    final res = await db.query('intake_records', orderBy: 'recordedAt DESC', limit: limit);
    return res.map((m) => IntakeRecord.fromMap(m)).toList();
  }

  Future<void> recordIntake(IntakeRecord record) async {
    final db = await database;
    await db.transaction((txn) async {
      // Check if existing record for this scheduled dose
      final existing = await txn.query(
        'intake_records',
        where: 'medicineId = ? AND reminderTimeId = ? AND scheduledDate = ?',
        whereArgs: [record.medicineId, record.reminderTimeId, record.scheduledDate],
      );

      if (existing.isNotEmpty) {
        await txn.update(
          'intake_records',
          record.toMap(),
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      } else {
        await txn.insert('intake_records', record.toMap());
      }

      // If status is taken, decrement medicine stock if stock > 0
      if (record.status == IntakeStatus.taken) {
        final medRes = await txn.query('medicines', where: 'id = ?', whereArgs: [record.medicineId]);
        if (medRes.isNotEmpty) {
          final currentStock = medRes.first['currentStock'] as int? ?? 0;
          if (currentStock > 0) {
            await txn.update(
              'medicines',
              {'currentStock': currentStock - 1},
              where: 'id = ?',
              whereArgs: [record.medicineId],
            );
          }
        }
      }
    });
  }

  Future<void> clearAllHistory() async {
    final db = await database;
    await db.delete('intake_records');
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('intake_records');
      await txn.delete('reminder_times');
      await txn.delete('medicines');
      await txn.delete('profiles', where: 'id != ?', whereArgs: ['default_me']);
    });
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
