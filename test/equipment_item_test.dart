import 'package:flutter_test/flutter_test.dart';
import 'package:kito/features/inventory/domain/equipment_item.dart';

void main() {
  group('EquipmentItem', () {
    const item = EquipmentItem(
      id: 'tent',
      name: 'Tente',
      category: 'Camping',
      newQuantity: 1,
      goodQuantity: 3,
      repairQuantity: 1,
      unusableQuantity: 1,
      lowStockThreshold: 4,
      isConsumable: true,
    );

    test('calculates physical and available stock from condition counts', () {
      expect(item.physicalQuantity, 6);
      expect(item.availableQuantity, 4);
    });

    test('flags consumable stock at or below the alert threshold', () {
      expect(item.isLowStock, isTrue);
      expect(
        const EquipmentItem(
          id: 'rope',
          name: 'Corde',
          category: 'Camping',
          newQuantity: 1,
          goodQuantity: 3,
          repairQuantity: 0,
          unusableQuantity: 0,
          lowStockThreshold: 2,
          isConsumable: false,
        ).isLowStock,
        isFalse,
      );
    });
  });
}
