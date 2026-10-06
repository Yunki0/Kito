import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/inventory/domain/equipment_item.dart';

class InventoryExportService {
  const InventoryExportService();

  Uint8List createCsv(List<EquipmentItem> equipment) {
    final rows = <List<String>>[
      [
        'Matériel',
        'Catégorie',
        'Neuf',
        'Bon état',
        'À réparer',
        'Hors service',
        'Disponible',
        'Stock physique',
        'Seuil d’alerte',
        'Consommable',
        'Notes',
      ],
      for (final item in equipment)
        [
          item.name,
          item.category,
          '${item.newQuantity}',
          '${item.goodQuantity}',
          '${item.repairQuantity}',
          '${item.unusableQuantity}',
          '${item.availableQuantity}',
          '${item.physicalQuantity}',
          item.lowStockThreshold > 0 ? '${item.lowStockThreshold}' : '',
          item.isConsumable ? 'Oui' : 'Non',
          item.notes,
        ],
    ];
    final csv = rows
        .map((row) => row.map(_escapeCsvCell).join(';'))
        .join('\r\n');
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
  }

  Future<Uint8List> createPdf(List<EquipmentItem> equipment) async {
    final document = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.ttf(
          await rootBundle.load('assets/fonts/LiberationSans-Regular.ttf'),
        ),
        bold: pw.Font.ttf(
          await rootBundle.load('assets/fonts/LiberationSans-Bold.ttf'),
        ),
      ),
    );
    final totalPhysical = equipment.fold<int>(
      0,
      (total, item) => total + item.physicalQuantity,
    );
    final totalAvailable = equipment.fold<int>(
      0,
      (total, item) => total + item.availableQuantity,
    );
    final totalRepair = equipment.fold<int>(
      0,
      (total, item) => total + item.repairQuantity,
    );
    final lowStockCount = equipment.where((item) => item.isLowStock).length;
    final generatedAt = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(DateTime.now());

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 30),
        header: (context) => _header(generatedAt),
        footer: (context) => _footer(context),
        build: (context) => [
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              _summaryCard('RÉFÉRENCES', '${equipment.length}'),
              _summaryCard('STOCK PHYSIQUE', '$totalPhysical'),
              _summaryCard('DISPONIBLE', '$totalAvailable'),
              _summaryCard('À RÉPARER', '$totalRepair'),
              _summaryCard('ALERTES', '$lowStockCount'),
            ],
          ),
          pw.SizedBox(height: 18),
          if (equipment.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(24),
              decoration: pw.BoxDecoration(
                color: const PdfColor(0.95, 0.96, 0.93),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'Aucun matériel n’est enregistré dans l’inventaire.',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: _forest,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(
                  color: const PdfColor(0.88, 0.90, 0.86),
                  width: 0.5,
                ),
                bottom: pw.BorderSide(
                  color: const PdfColor(0.78, 0.82, 0.76),
                  width: 0.8,
                ),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.5),
                1: pw.FlexColumnWidth(1.6),
                2: pw.FlexColumnWidth(0.55),
                3: pw.FlexColumnWidth(0.7),
                4: pw.FlexColumnWidth(0.8),
                5: pw.FlexColumnWidth(0.8),
                6: pw.FlexColumnWidth(0.75),
                7: pw.FlexColumnWidth(0.8),
                8: pw.FlexColumnWidth(0.7),
                9: pw.FlexColumnWidth(2.5),
              },
              children: [
                _tableRow(
                  const [
                    'MATÉRIEL',
                    'CATÉGORIE',
                    'NEUF',
                    'BON',
                    'RÉPAR.',
                    'H.S.',
                    'DISPO.',
                    'TOTAL',
                    'SEUIL',
                    'NOTES',
                  ],
                  header: true,
                ),
                for (var index = 0; index < equipment.length; index++)
                  _tableRow(
                    _equipmentCells(equipment[index]),
                    shaded: index.isOdd,
                    alert: equipment[index].isLowStock,
                  ),
              ],
            ),
        ],
      ),
    );
    return document.save();
  }

  static const _forest = PdfColor(0.06, 0.32, 0.20);
  static const _muted = PdfColor(0.39, 0.44, 0.41);

  pw.Widget _header(String generatedAt) => pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 10),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColor(0.84, 0.87, 0.82), width: 0.8),
      ),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'KITO',
              style: pw.TextStyle(
                color: _forest,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Inventaire du matériel',
              style: pw.TextStyle(
                color: _forest,
                fontSize: 21,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.Text(
          'Généré le $generatedAt',
          style: const pw.TextStyle(color: _muted, fontSize: 9),
        ),
      ],
    ),
  );

  pw.Widget _footer(pw.Context context) => pw.Container(
    alignment: pw.Alignment.centerRight,
    margin: const pw.EdgeInsets.only(top: 10),
    padding: const pw.EdgeInsets.only(top: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        top: pw.BorderSide(color: PdfColor(0.84, 0.87, 0.82), width: 0.6),
      ),
    ),
    child: pw.Text(
      'Kito • Inventaire  |  Page ${context.pageNumber} sur ${context.pagesCount}',
      style: const pw.TextStyle(color: _muted, fontSize: 8),
    ),
  );

  pw.Widget _summaryCard(String label, String value) => pw.Expanded(
    child: pw.Container(
      margin: const pw.EdgeInsets.only(right: 8),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: pw.BoxDecoration(
        color: const PdfColor(0.94, 0.96, 0.92),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(color: _muted, fontSize: 7),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: _forest,
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );

  pw.TableRow _tableRow(
    List<String> cells, {
    bool header = false,
    bool shaded = false,
    bool alert = false,
  }) => pw.TableRow(
    decoration: header
        ? const pw.BoxDecoration(color: _forest)
        : pw.BoxDecoration(
            color: alert
                ? const PdfColor(1.0, 0.97, 0.89)
                : shaded
                ? const PdfColor(0.97, 0.98, 0.96)
                : PdfColors.white,
          ),
    children: [
      for (var index = 0; index < cells.length; index++)
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
          child: pw.Text(
            cells[index].isEmpty ? '—' : cells[index],
            maxLines: index == 9 || index == 0 ? 2 : 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              color: header ? PdfColors.white : PdfColors.grey900,
              fontSize: header ? 6.3 : 7.2,
              fontWeight: header || (alert && index == 6)
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
        ),
    ],
  );

  List<String> _equipmentCells(EquipmentItem item) => [
    item.name,
    item.category,
    '${item.newQuantity}',
    '${item.goodQuantity}',
    '${item.repairQuantity}',
    '${item.unusableQuantity}',
    '${item.availableQuantity}',
    '${item.physicalQuantity}',
    item.lowStockThreshold > 0 ? '${item.lowStockThreshold}' : '—',
    item.notes.isEmpty ? '—' : item.notes,
  ];

  String _escapeCsvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
