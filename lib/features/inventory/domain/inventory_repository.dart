import 'equipment_item.dart';

abstract interface class InventoryRepository {
  Future<List<EquipmentItem>> getEquipment();
  Future<List<StockMovement>> getMovements();
  Future<List<ActivityEntry>> getHistory();
  Future<void> saveEquipment(EquipmentItem item);
  Future<void> deleteEquipment(String id);
  Future<void> lendEquipment({
    required EquipmentItem item,
    required String borrower,
    required int quantity,
    DateTime? dueAt,
  });
  Future<void> returnEquipment({
    required StockMovement movement,
    required int quantity,
  });
}
