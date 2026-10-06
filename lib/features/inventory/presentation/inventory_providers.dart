import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/inventory_repository_impl.dart';
import '../domain/equipment_item.dart';
import '../domain/inventory_repository.dart';

final appDatabaseProvider = FutureProvider<AppDatabase>(
  (ref) => AppDatabase.open(),
);

final databaseReadyProvider = FutureProvider<void>((ref) async {
  await Future.wait([
    ref.watch(appDatabaseProvider.future),
    Future<void>.delayed(const Duration(milliseconds: 800)),
  ]);
});

final inventoryRepositoryProvider = FutureProvider<InventoryRepository>((ref) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return InventoryRepositoryImpl(database);
});

final equipmentProvider = FutureProvider<List<EquipmentItem>>((ref) async {
  return (await ref.watch(inventoryRepositoryProvider.future)).getEquipment();
});

final movementsProvider = FutureProvider<List<StockMovement>>((ref) async {
  return (await ref.watch(inventoryRepositoryProvider.future)).getMovements();
});

final historyProvider = FutureProvider<List<ActivityEntry>>((ref) async {
  return (await ref.watch(inventoryRepositoryProvider.future)).getHistory();
});
