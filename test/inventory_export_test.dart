import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kito/core/export/inventory_export_service.dart';
import 'package:kito/features/inventory/domain/equipment_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = InventoryExportService();

  test('CSV export includes inventory quantities and escapes cells', () {
    const equipment = [
      EquipmentItem(
        id: 'tent',
        name: 'Tente "A"',
        category: 'Camping',
        newQuantity: 1,
        goodQuantity: 2,
        repairQuantity: 1,
        unusableQuantity: 0,
        lowStockThreshold: 2,
        isConsumable: true,
        notes: 'À vérifier; avant le camp',
      ),
    ];

    final csv = utf8.decode(service.createCsv(equipment));
    final rows = const LineSplitter().convert(csv);

    expect(
      rows.first,
      contains(
        '"Matériel";"Catégorie";"Neuf";"Bon état";"À réparer";"Hors service"',
      ),
    );
    expect(rows[1], contains('"Tente ""A"""'));
    expect(rows[1], contains('"À vérifier; avant le camp"'));
    expect(rows[1], contains(';"3";"4";"2";"Oui";'));
  });

  test('PDF export produces a readable PDF document', () async {
    const equipment = [
      EquipmentItem(
        id: 'tent',
        name: 'Tente familiale',
        category: 'Camping',
        newQuantity: 1,
        goodQuantity: 2,
        repairQuantity: 1,
        unusableQuantity: 0,
        lowStockThreshold: 0,
        isConsumable: false,
        notes: 'Bon état général',
      ),
    ];

    final pdf = await service.createPdf(equipment);

    expect(pdf, isNotEmpty);
    expect(utf8.decode(pdf.take(8).toList()), startsWith('%PDF-'));
  });
}
