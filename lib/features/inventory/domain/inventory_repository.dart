import 'equipment_item.dart';

abstract interface class InventoryRepository {
  Future<List<EquipmentItem>> getEquipment();
  Future<void> saveEquipment(EquipmentItem item);
  Future<void> deleteEquipment(String id);
}
