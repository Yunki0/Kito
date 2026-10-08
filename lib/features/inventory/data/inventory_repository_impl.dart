import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/equipment_item.dart';
import '../domain/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl(this._appDatabase);

  final AppDatabase _appDatabase;
  static const _uuid = Uuid();
  Database get _db => _appDatabase.database;

  @override
  Future<List<EquipmentItem>> getEquipment() async {
    final rows = await _db.query('equipment', orderBy: 'name COLLATE NOCASE');
    return rows.map(_equipmentFromRow).toList();
  }

  @override
  Future<void> saveEquipment(EquipmentItem item) async {
    final isNew = item.id.isEmpty;
    final id = isNew ? _uuid.v4() : item.id;
    await _db.transaction((txn) async {
      final values = {
        'name': item.name.trim(),
        'category': item.category,
        'new_quantity': item.newQuantity,
        'good_quantity': item.goodQuantity,
        'repair_quantity': item.repairQuantity,
        'unusable_quantity': item.unusableQuantity,
        'low_stock_threshold': item.lowStockThreshold,
        'is_consumable': item.isConsumable ? 1 : 0,
        'notes': item.notes.trim(),
      };
      if (isNew) {
        await txn.insert('equipment', {'id': id, ...values});
      } else {
        final updated = await txn.update(
          'equipment',
          values,
          where: 'id = ?',
          whereArgs: [id],
        );
        if (updated == 0) throw StateError('Cette fiche n’existe plus.');
      }
    });
  }

  @override
  Future<void> deleteEquipment(String id) async =>
      _db.delete('equipment', where: 'id = ?', whereArgs: [id]);

  EquipmentItem _equipmentFromRow(Map<String, Object?> row) => EquipmentItem(
    id: row['id']! as String,
    name: row['name']! as String,
    category: row['category']! as String,
    newQuantity: row['new_quantity']! as int,
    goodQuantity: row['good_quantity']! as int,
    repairQuantity: row['repair_quantity']! as int,
    unusableQuantity: row['unusable_quantity']! as int,
    lowStockThreshold: row['low_stock_threshold']! as int,
    isConsumable: row['is_consumable']! as int == 1,
    notes: row['notes']! as String,
  );
}
