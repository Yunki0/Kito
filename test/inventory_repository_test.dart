import 'package:flutter_test/flutter_test.dart';
import 'package:kito/core/database/app_database.dart';
import 'package:kito/features/inventory/data/inventory_repository_impl.dart';
import 'package:kito/features/inventory/domain/equipment_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late InventoryRepositoryImpl repository;

  setUp(() async {
    database = await AppDatabase.open(databasePath: inMemoryDatabasePath);
    repository = InventoryRepositoryImpl(database);
  });

  tearDown(() => database.close());

  test('persists an item and tracks partial and complete returns', () async {
    await repository.saveEquipment(_item());
    final savedItem = (await repository.getEquipment()).single;

    expect(savedItem.id, isNotEmpty);
    expect(savedItem.availableQuantity, 5);

    await repository.lendEquipment(
      item: savedItem,
      borrower: 'Camille',
      quantity: 2,
      dueAt: DateTime(2026, 10, 13),
    );
    var inventoryItem = (await repository.getEquipment()).single;
    expect(inventoryItem.borrowedQuantity, 2);
    expect(inventoryItem.availableQuantity, 3);

    var movement = (await repository.getMovements()).single;
    expect(movement.outstandingQuantity, 2);
    expect(movement.borrower, 'Camille');
    await repository.returnEquipment(movement: movement, quantity: 1);

    movement = (await repository.getMovements()).single;
    expect(movement.outstandingQuantity, 1);
    await repository.returnEquipment(movement: movement, quantity: 1);

    expect(await repository.getMovements(), isEmpty);
    inventoryItem = (await repository.getEquipment()).single;
    expect(inventoryItem.borrowedQuantity, 0);
    expect(inventoryItem.availableQuantity, 5);
    expect(await repository.getHistory(), hasLength(4));
  });

  test(
    'rejects stale oversubscription and deletion during an active loan',
    () async {
      await repository.saveEquipment(_item(quantity: 2));
      final staleItem = (await repository.getEquipment()).single;
      await repository.lendEquipment(
        item: staleItem,
        borrower: 'Alex',
        quantity: 2,
      );

      await expectLater(
        repository.lendEquipment(
          item: staleItem,
          borrower: 'Morgan',
          quantity: 1,
        ),
        throwsStateError,
      );
      await expectLater(
        repository.deleteEquipment(staleItem.id),
        throwsStateError,
      );
    },
  );
}

EquipmentItem _item({int quantity = 5}) => EquipmentItem(
  id: '',
  name: 'Tente',
  category: 'Camping',
  newQuantity: 1,
  goodQuantity: quantity - 1,
  repairQuantity: 1,
  unusableQuantity: 0,
  lowStockThreshold: 0,
  isConsumable: false,
);
