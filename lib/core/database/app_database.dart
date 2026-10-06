import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'database_factory.dart';

class AppDatabase {
  AppDatabase._(this.database);

  final Database database;

  static Future<AppDatabase> open({String? databasePath}) async {
    await configureDatabaseFactory();
    final resolvedPath =
        databasePath ?? path.join(await getDatabasesPath(), 'kito.db');
    final database = await openDatabase(
      resolvedPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE equipment (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            new_quantity INTEGER NOT NULL DEFAULT 0,
            good_quantity INTEGER NOT NULL DEFAULT 0,
            repair_quantity INTEGER NOT NULL DEFAULT 0,
            unusable_quantity INTEGER NOT NULL DEFAULT 0,
            low_stock_threshold INTEGER NOT NULL DEFAULT 0,
            is_consumable INTEGER NOT NULL DEFAULT 0,
            notes TEXT NOT NULL DEFAULT ''
          )
        ''');
        await db.execute('''
          CREATE TABLE movements (
            id TEXT PRIMARY KEY,
            equipment_id TEXT NOT NULL,
            borrower TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            returned_quantity INTEGER NOT NULL DEFAULT 0,
            checked_out_at TEXT NOT NULL,
            due_at TEXT,
            FOREIGN KEY (equipment_id) REFERENCES equipment(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE activity (
            id TEXT PRIMARY KEY,
            message TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    return AppDatabase._(database);
  }

  Future<void> close() => database.close();
}
