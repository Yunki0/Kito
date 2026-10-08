import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/branding/kito_brand.dart';
import '../../../core/database/inventory_backup_service.dart';
import '../../../core/export/inventory_export_service.dart';
import '../../inventory/domain/equipment_item.dart';
import '../../inventory/presentation/equipment_form_page.dart';
import '../../inventory/presentation/inventory_providers.dart';
import 'inventory_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  void _refreshData() => ref.invalidate(equipmentProvider);

  Future<void> _openEquipmentForm([EquipmentItem? item]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EquipmentFormPage(item: item)),
    );
    if (result == true) _refreshData();
  }

  Future<void> _createBackup() async {
    try {
      final database = await ref.read(appDatabaseProvider.future);
      final bytes = await InventoryBackupService(database).createBackup();
      final savedFile = await FilePicker.saveFile(
        fileName:
            'kito-sauvegarde-${DateTime.now().toIso8601String().substring(0, 10)}.json',
        bytes: bytes,
        mimeType: 'application/json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Enregistrer une sauvegarde Kito',
      );
      if (savedFile == null || !mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sauvegarde enregistrée.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Création de la sauvegarde impossible : $error'),
        ),
      );
    }
  }

  Future<void> _shareBackup() async {
    try {
      final database = await ref.read(appDatabaseProvider.future);
      final bytes = await InventoryBackupService(database).createBackup();
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final fileName = 'kito-sauvegarde-$date.json';

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
        final savedFile = await FilePicker.saveFile(
          fileName: fileName,
          bytes: bytes,
          mimeType: 'application/json',
          type: FileType.custom,
          allowedExtensions: ['json'],
          dialogTitle: 'Enregistrer la sauvegarde à partager',
        );
        if (savedFile == null || !mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sauvegarde enregistrée. Tu peux maintenant la partager.',
            ),
          ),
        );
        return;
      }

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes, mimeType: 'application/json', name: fileName),
          ],
          fileNameOverrides: [fileName],
          title: 'Partager la sauvegarde Kito',
          text: 'Sauvegarde Kito du $date',
        ),
      );
      if (!mounted || result.status == ShareResultStatus.dismissed) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Menu de partage ouvert.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Partage de la sauvegarde impossible : $error')),
      );
    }
  }

  Future<void> _exportInventory({required bool asPdf}) async {
    try {
      final equipment = await ref.read(equipmentProvider.future);
      final service = const InventoryExportService();
      final bytes = asPdf
          ? await service.createPdf(equipment)
          : service.createCsv(equipment);
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final extension = asPdf ? 'pdf' : 'csv';
      final savedFile = await FilePicker.saveFile(
        fileName: 'kito-inventaire-$date.$extension',
        bytes: bytes,
        mimeType: asPdf ? 'application/pdf' : 'text/csv',
        type: FileType.custom,
        allowedExtensions: [extension],
        dialogTitle: asPdf
            ? 'Exporter l’inventaire en PDF'
            : 'Exporter l’inventaire en CSV',
      );
      if (savedFile == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            asPdf ? 'Inventaire PDF exporté.' : 'Inventaire CSV exporté.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export de l’inventaire impossible : $error')),
      );
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final selection = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Choisir une sauvegarde Kito',
      );
      if (selection == null || !mounted) return;
      final bytes = await selection.readAsBytes();
      if (!mounted) return;
      final database = await ref.read(appDatabaseProvider.future);
      if (!mounted) return;
      final backupService = InventoryBackupService(database);
      final preview = backupService.previewBackup(bytes);
      final equipmentLabel = preview.equipmentCount == 1
          ? 'fiche matériel'
          : 'fiches matériel';
      final backupDate = preview.createdAt == null
          ? 'Date inconnue'
          : 'Créée le ${_formatBackupDate(preview.createdAt!)}';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Vérifier la sauvegarde'),
          content: Text(
            '$backupDate\n'
            '${preview.equipmentCount} $equipmentLabel.\n\n'
            'La restauration remplacera tout le matériel actuel. '
            'Avant de continuer, Kito te proposera d’enregistrer une copie de '
            'tes données actuelles. Aucune donnée ne sera remplacée si cette '
            'copie ne peut pas être enregistrée.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      final currentBackup = await backupService.createBackup();
      if (backupService.previewBackup(currentBackup).equipmentCount > 0) {
        final date = DateTime.now().toIso8601String().substring(0, 10);
        final savedFile = await FilePicker.saveFile(
          fileName: 'kito-avant-restauration-$date.json',
          bytes: currentBackup,
          mimeType: 'application/json',
          type: FileType.custom,
          allowedExtensions: ['json'],
          dialogTitle: 'Sauvegarder les données actuelles avant restauration',
        );
        if (savedFile == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Restauration annulée : la sauvegarde préalable n’a pas été enregistrée.',
                ),
              ),
            );
          }
          return;
        }
      }

      final count = await backupService.restoreBackup(bytes);
      _refreshData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sauvegarde restaurée : $count fiches.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restauration impossible : $error')),
      );
    }
  }

  String _formatBackupDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final startup = ref.watch(databaseReadyProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: startup.when(
        loading: () => const KitoSplashView(key: ValueKey('splash')),
        error: (error, _) => Scaffold(
          key: const ValueKey('error'),
          body: _StartupError(
            error: error,
            onRetry: () => ref.invalidate(appDatabaseProvider),
          ),
        ),
        data: (_) => KeyedSubtree(
          key: const ValueKey('home'),
          child: _buildHome(context),
        ),
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            const KitoMark(size: 42, padding: 4),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kito',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
                ),
                Text(
                  'Mon matériel',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              tooltip: 'Ajouter du matériel',
              onPressed: _openEquipmentForm,
              icon: const Icon(Icons.add),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Exports, sauvegarde et apparence',
            onSelected: (action) {
              if (action == 'backup') _createBackup();
              if (action == 'share_backup') _shareBackup();
              if (action == 'restore') _restoreBackup();
              if (action == 'export_pdf') _exportInventory(asPdf: true);
              if (action == 'export_csv') _exportInventory(asPdf: false);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'export_pdf',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf_outlined),
                  title: Text('Exporter en PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'export_csv',
                child: ListTile(
                  leading: Icon(Icons.table_chart_outlined),
                  title: Text('Exporter en CSV'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'backup',
                child: ListTile(
                  leading: Icon(Icons.backup_outlined),
                  title: Text('Créer une sauvegarde'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'share_backup',
                child: ListTile(
                  leading: Icon(Icons.share_outlined),
                  title: Text('Partager une sauvegarde'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'restore',
                child: ListTile(
                  leading: Icon(Icons.settings_backup_restore),
                  title: Text('Restaurer une sauvegarde'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem<String>(
                enabled: false,
                child: ListTile(
                  leading: Icon(Icons.brightness_6_outlined),
                  title: Text('Thème du système'),
                  subtitle: Text('Clair ou sombre automatiquement'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: InventoryPage(onEdit: _openEquipmentForm, onChanged: _refreshData),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const KitoMark(size: 82),
              const SizedBox(height: 24),
              const Text(
                'Kito n’a pas pu démarrer',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
