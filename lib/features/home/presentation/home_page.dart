import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/kito_brand.dart';
import '../../inventory/domain/equipment_item.dart';
import '../../inventory/presentation/equipment_form_page.dart';
import '../../inventory/presentation/inventory_providers.dart';
import 'history_page.dart';
import 'inventory_page.dart';
import 'movements_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  static const _titles = ['Mon matériel', 'Emprunts', 'Historique'];

  void _refreshData() {
    ref
      ..invalidate(equipmentProvider)
      ..invalidate(movementsProvider)
      ..invalidate(historyProvider);
  }

  Future<void> _openEquipmentForm([EquipmentItem? item]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EquipmentFormPage(item: item)),
    );
    if (result == true) _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final startup = ref.watch(databaseReadyProvider);
    return startup.when(
      loading: () => const Scaffold(
        body: KitoLoadingView(message: 'Ouverture de votre matériel…'),
      ),
      error: (error, _) => Scaffold(
        body: _StartupError(
          error: error,
          onRetry: () => ref.invalidate(appDatabaseProvider),
        ),
      ),
      data: (_) => _buildHome(context),
    );
  }

  Widget _buildHome(BuildContext context) {
    final pages = [
      InventoryPage(onEdit: _openEquipmentForm, onChanged: _refreshData),
      MovementsPage(onChanged: _refreshData),
      const HistoryPage(),
    ];
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
                  _titles[_selectedIndex],
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
          if (_selectedIndex == 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton.filledTonal(
                tooltip: 'Ajouter du matériel',
                onPressed: _openEquipmentForm,
                icon: const Icon(Icons.add),
              ),
            ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Matériel',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            label: 'Emprunts',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Journal',
          ),
        ],
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: KitoBrand.cream,
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
                style: const TextStyle(color: KitoBrand.mutedInk),
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
