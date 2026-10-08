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

  int get physicalQuantity =>
      newQuantity + goodQuantity + repairQuantity + unusableQuantity;

  int get availableQuantity => newQuantity + goodQuantity;

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
