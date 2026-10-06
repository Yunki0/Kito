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
    final rows = await _db.rawQuery('''
      SELECT equipment.*,
        COALESCE((
          SELECT SUM(quantity - returned_quantity)
          FROM movements
          WHERE equipment_id = equipment.id
        ), 0) AS borrowed_quantity
      FROM equipment
      ORDER BY name COLLATE NOCASE
    ''');
    return rows.map(_equipmentFromRow).toList();
  }

  @override
  Future<List<StockMovement>> getMovements() async {
    final rows = await _db.rawQuery('''
      SELECT movements.*, equipment.name AS equipment_name
      FROM movements
      JOIN equipment ON equipment.id = movements.equipment_id
      WHERE movements.quantity > movements.returned_quantity
      ORDER BY movements.checked_out_at DESC
    ''');
    return rows.map(_movementFromRow).toList();
  }

  @override
  Future<List<ActivityEntry>> getHistory() async {
    final rows = await _db.query('activity', orderBy: 'created_at DESC');
    return rows
        .map(
          (row) => ActivityEntry(
            id: row['id']! as String,
            message: row['message']! as String,
            createdAt: DateTime.parse(row['created_at']! as String),
          ),
        )
        .toList();
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
      await _writeActivity(
        txn,
        '${isNew ? 'Matériel ajouté' : 'Matériel modifié'} : ${item.name.trim()}',
      );
    });
  }

  @override
  Future<void> deleteEquipment(String id) async {
    await _db.transaction((txn) async {
      final rows = await txn.query(
        'equipment',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows.isEmpty) return;
      final name = rows.first['name']! as String;
      final active = await txn.rawQuery(
        'SELECT COUNT(*) AS count FROM movements '
        'WHERE equipment_id = ? AND quantity > returned_quantity',
        [id],
      );
      if ((active.first['count']! as int) > 0) {
        throw StateError('Ce matériel est encore emprunté.');
      }
      await txn.delete('equipment', where: 'id = ?', whereArgs: [id]);
      await _writeActivity(txn, 'Matériel supprimé : $name');
    });
  }

  @override
  Future<void> lendEquipment({
    required EquipmentItem item,
    required String borrower,
    required int quantity,
    DateTime? dueAt,
  }) async {
    if (borrower.trim().isEmpty) {
      throw ArgumentError('Le nom de la personne est obligatoire.');
    }
    if (quantity < 1 || quantity > item.availableQuantity) {
      throw StateError('La quantité demandée n’est pas disponible.');
    }
    await _db.transaction((txn) async {
      final rows = await txn.rawQuery('''
        SELECT equipment.new_quantity + equipment.good_quantity -
          COALESCE((
            SELECT SUM(quantity - returned_quantity)
            FROM movements
            WHERE equipment_id = equipment.id
          ), 0) AS available
        FROM equipment
        WHERE equipment.id = ?
      ''', [item.id]);
      if (rows.isEmpty || quantity > (rows.first['available']! as int)) {
        throw StateError('Le stock disponible a changé. Actualisez l’inventaire.');
      }
      await txn.insert('movements', {
        'id': _uuid.v4(),
        'equipment_id': item.id,
        'borrower': borrower.trim(),
        'quantity': quantity,
        'returned_quantity': 0,
        'checked_out_at': DateTime.now().toIso8601String(),
        'due_at': dueAt?.toIso8601String(),
      });
      await _writeActivity(
        txn,
        '$quantity × ${item.name} prêté à ${borrower.trim()}',
      );
    });
  }

  @override
  Future<void> returnEquipment({
    required StockMovement movement,
    required int quantity,
  }) async {
    if (quantity < 1 || quantity > movement.outstandingQuantity) {
      throw StateError('La quantité à rendre n’est pas valide.');
    }
    await _db.transaction((txn) async {
      final updated = await txn.rawUpdate(
        'UPDATE movements SET returned_quantity = returned_quantity + ? '
        'WHERE id = ? AND quantity - returned_quantity >= ?',
        [quantity, movement.id, quantity],
      );
      if (updated == 0) {
        throw StateError('Cet emprunt a déjà été modifié. Actualisez la liste.');
      }
      await _writeActivity(
        txn,
        '$quantity × ${movement.equipmentName} rendu par ${movement.borrower}',
      );
    });
  }

  Future<void> _writeActivity(Transaction txn, String message) async {
    await txn.insert('activity', {
      'id': _uuid.v4(),
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

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
    borrowedQuantity: row['borrowed_quantity'] as int? ?? 0,
  );

  StockMovement _movementFromRow(Map<String, Object?> row) => StockMovement(
    id: row['id']! as String,
    equipmentId: row['equipment_id']! as String,
    equipmentName: row['equipment_name']! as String,
    borrower: row['borrower']! as String,
    quantity: row['quantity']! as int,
    returnedQuantity: row['returned_quantity']! as int,
    checkedOutAt: DateTime.parse(row['checked_out_at']! as String),
    dueAt: row['due_at'] == null
        ? null
        : DateTime.parse(row['due_at']! as String),
  );
}
