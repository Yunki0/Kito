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

  test(
    'persists inventory and recalculates available stock from condition counts',
    () async {
      await repository.saveEquipment(_item());
      final savedItem = (await repository.getEquipment()).single;

      expect(savedItem.id, isNotEmpty);
      expect(savedItem.physicalQuantity, 6);
      expect(savedItem.availableQuantity, 5);
      expect(savedItem.repairQuantity, 1);
    },
  );

  test('deletes equipment without requiring an activity log', () async {
    await repository.saveEquipment(_item());
    final savedItem = (await repository.getEquipment()).single;

    await repository.deleteEquipment(savedItem.id);

    expect(await repository.getEquipment(), isEmpty);
  });
}

EquipmentItem _item() => const EquipmentItem(
  id: '',
  name: 'Tente',
  category: 'Camping',
  newQuantity: 1,
  goodQuantity: 4,
  repairQuantity: 1,
  unusableQuantity: 0,
  lowStockThreshold: 0,
  isConsumable: false,
);
