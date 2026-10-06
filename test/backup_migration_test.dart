import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kito/core/database/app_database.dart';
import 'package:kito/core/database/inventory_backup_service.dart';
import 'package:kito/features/inventory/data/inventory_repository_impl.dart';
import 'package:kito/features/inventory/domain/equipment_item.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late InventoryRepositoryImpl repository;

  setUp(() async {
    database = await AppDatabase.open(databasePath: inMemoryDatabasePath);
    repository = InventoryRepositoryImpl(database);
  });

  tearDown(() => database.close());

  test('backup restores inventory and activity as a replacement', () async {
    await repository.saveEquipment(_item('Tente'));
    final backup = await InventoryBackupService(database).createBackup();

    await repository.saveEquipment(_item('Réchaud'));
    expect(await repository.getEquipment(), hasLength(2));

    final restoredCount = await InventoryBackupService(
      database,
    ).restoreBackup(backup);

    expect(restoredCount, 1);
    expect((await repository.getEquipment()).single.name, 'Tente');
    expect(await repository.getHistory(), hasLength(1));
  });

  test('invalid backup does not replace existing data', () async {
    await repository.saveEquipment(_item('Tente'));
    final invalid = utf8.encode(
      '{"format":"kito-backup","version":1,"equipment":[],"activity":[{"id":"bad"}]}',
    );

    await expectLater(
      InventoryBackupService(
        database,
      ).restoreBackup(Uint8List.fromList(invalid)),
      throwsFormatException,
    );
    expect((await repository.getEquipment()).single.name, 'Tente');
  });

  test('upgrading an old database removes active loans as returned', () async {
    final directory = await Directory.systemTemp.createTemp('kito-migration-');
    final databasePath = path.join(directory.path, 'legacy.db');
    final legacy = await databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE equipment (
              id TEXT PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL,
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
              id TEXT PRIMARY KEY, equipment_id TEXT NOT NULL,
              borrower TEXT NOT NULL, quantity INTEGER NOT NULL,
              returned_quantity INTEGER NOT NULL DEFAULT 0,
              checked_out_at TEXT NOT NULL, due_at TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE activity (
              id TEXT PRIMARY KEY, message TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
          await db.insert('equipment', {
            'id': 'tent',
            'name': 'Tente',
            'category': 'Camping',
            'new_quantity': 1,
            'good_quantity': 4,
            'repair_quantity': 0,
            'unusable_quantity': 0,
            'low_stock_threshold': 0,
            'is_consumable': 0,
            'notes': '',
          });
          await db.insert('movements', {
            'id': 'loan',
            'equipment_id': 'tent',
            'borrower': 'Camille',
            'quantity': 2,
            'returned_quantity': 0,
            'checked_out_at': DateTime.now().toIso8601String(),
          });
          await db.insert('activity', {
            'id': 'loan-activity',
            'message': '2 × Tente prêté à Camille',
            'created_at': DateTime.now().toIso8601String(),
          });
        },
      ),
    );
    await legacy.close();

    final upgraded = await AppDatabase.open(databasePath: databasePath);
    final upgradedRepository = InventoryRepositoryImpl(upgraded);

    expect(
      (await upgradedRepository.getEquipment()).single.availableQuantity,
      5,
    );
    expect(
      (await upgradedRepository.getHistory()).single.message,
      '2 × Tente prêté à Camille',
    );
    expect(
      await upgraded.database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'movements'",
      ),
      isEmpty,
    );

    await upgraded.close();
    await directory.delete(recursive: true);
  });
}

EquipmentItem _item(String name) => EquipmentItem(
  id: '',
  name: name,
  category: 'Camping',
  newQuantity: 1,
  goodQuantity: 2,
  repairQuantity: 1,
  unusableQuantity: 0,
  lowStockThreshold: 0,
  isConsumable: false,
);
