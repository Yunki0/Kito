enum EquipmentCondition { newItem, good, repair, unusable }

class EquipmentItem {
  const EquipmentItem({
    required this.id,
    required this.name,
    required this.category,
    required this.newQuantity,
    required this.goodQuantity,
    required this.repairQuantity,
    required this.unusableQuantity,
    required this.lowStockThreshold,
    required this.isConsumable,
    this.notes = '',
    this.borrowedQuantity = 0,
  });

  final String id;
  final String name;
  final String category;
  final int newQuantity;
  final int goodQuantity;
  final int repairQuantity;
  final int unusableQuantity;
  final int lowStockThreshold;
  final bool isConsumable;
  final String notes;
  final int borrowedQuantity;

  int get physicalQuantity =>
      newQuantity + goodQuantity + repairQuantity + unusableQuantity;

  int get availableQuantity =>
      newQuantity + goodQuantity - borrowedQuantity;

  bool get isLowStock =>
      isConsumable &&
      lowStockThreshold > 0 &&
      availableQuantity <= lowStockThreshold;

  int quantityFor(EquipmentCondition condition) => switch (condition) {
    EquipmentCondition.newItem => newQuantity,
    EquipmentCondition.good => goodQuantity,
    EquipmentCondition.repair => repairQuantity,
    EquipmentCondition.unusable => unusableQuantity,
  };
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.borrower,
    required this.quantity,
    required this.returnedQuantity,
    required this.checkedOutAt,
    this.dueAt,
  });

  final String id;
  final String equipmentId;
  final String equipmentName;
  final String borrower;
  final int quantity;
  final int returnedQuantity;
  final DateTime checkedOutAt;
  final DateTime? dueAt;

  int get outstandingQuantity => quantity - returnedQuantity;
}

class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String message;
  final DateTime createdAt;
}
