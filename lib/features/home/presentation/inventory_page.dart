import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/kito_brand.dart';
import '../../inventory/domain/equipment_item.dart';
import '../../inventory/presentation/inventory_providers.dart';
import 'inventory_actions.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({required this.onEdit, required this.onChanged, super.key});

  final ValueChanged<EquipmentItem> onEdit;
  final VoidCallback onChanged;

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  final _searchController = TextEditingController();
  String _category = 'Tout';
  bool _lowStockOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(equipmentProvider);
    return inventory.when(
      loading: () => const KitoLoadingView(message: 'Chargement du matériel…'),
      error: (error, _) => _ErrorState(
        error: error,
        onRetry: () => ref.invalidate(equipmentProvider),
      ),
      data: (items) {
        final categories = ['Tout', ...{for (final item in items) item.category}];
        final query = _searchController.text.trim().toLowerCase();
        final visible = items.where((item) {
          final matchesSearch =
              item.name.toLowerCase().contains(query) ||
              item.category.toLowerCase().contains(query);
          final matchesCategory = _category == 'Tout' || item.category == _category;
          return matchesSearch &&
              matchesCategory &&
              (!_lowStockOnly || item.isLowStock);
        }).toList();
        final available = items.fold<int>(
          0,
          (total, item) => total + item.availableQuantity,
        );
        final borrowed = items.fold<int>(
          0,
          (total, item) => total + item.borrowedQuantity,
        );
        final alerts = items.where((item) => item.isLowStock).length;

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(equipmentProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _WelcomeCard(
                itemCount: items.length,
                available: available,
                borrowed: borrowed,
                alerts: alerts,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Votre inventaire',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '${items.length} ${items.length == 1 ? 'fiche' : 'fiches'}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Rechercher un matériel…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Effacer la recherche',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _category == category,
                          onSelected: (_) => setState(() => _category = category),
                        ),
                      ),
                    ),
                    FilterChip(
                      avatar: const Icon(Icons.warning_amber_rounded, size: 18),
                      label: const Text('Stock bas'),
                      selected: _lowStockOnly,
                      onSelected: (value) =>
                          setState(() => _lowStockOnly = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                _EmptyState(
                  icon: Icons.backpack_outlined,
                  title: 'Votre inventaire commence ici',
                  message:
                      'Ajoutez les tentes, outils et consommables de votre unité pour suivre le stock et les emprunts.',
                  actionLabel: 'Ajouter du matériel',
                  onAction: () => widget.onEdit(
                    const EquipmentItem(
                      id: '',
                      name: '',
                      category: 'Camping',
                      newQuantity: 0,
                      goodQuantity: 0,
                      repairQuantity: 0,
                      unusableQuantity: 0,
                      lowStockThreshold: 0,
                      isConsumable: false,
                    ),
                  ),
                )
              else if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Center(child: Text('Aucun matériel ne correspond.')),
                )
              else
                ...visible.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _EquipmentCard(
                      item: item,
                      onEdit: () => widget.onEdit(item),
                      onLend: () => showLendDialog(
                        context: context,
                        ref: ref,
                        item: item,
                        onChanged: widget.onChanged,
                      ),
                      onDelete: () => confirmDeleteEquipment(
                        context: context,
                        ref: ref,
                        item: item,
                        onChanged: widget.onChanged,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.itemCount,
    required this.available,
    required this.borrowed,
    required this.alerts,
  });

  final int itemCount;
  final int available;
  final int borrowed;
  final int alerts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [KitoBrand.forest, Color(0xFF256444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prêts pour\nla prochaine aventure ?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _Stat(label: 'Références', value: '$itemCount'),
              _Stat(label: 'Disponibles', value: '$available'),
              _Stat(label: 'Empruntés', value: '$borrowed'),
            ],
          ),
          if (alerts > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '⚠  $alerts ${alerts == 1 ? 'stock à surveiller' : 'stocks à surveiller'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFD9E8DF), fontSize: 11),
        ),
      ],
    ),
  );
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.item,
    required this.onEdit,
    required this.onLend,
    required this.onDelete,
  });

  final EquipmentItem item;
  final VoidCallback onEdit;
  final VoidCallback onLend;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final canLend = item.availableQuantity > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 12, 8, 14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: KitoBrand.paleSage,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _categoryIcon(item.category),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        item.category,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Options',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _Quantity(label: 'Disponible', value: item.availableQuantity),
                _Quantity(label: 'Emprunté', value: item.borrowedQuantity),
                _Quantity(label: 'À réparer', value: item.repairQuantity),
                _Quantity(label: 'Total', value: item.physicalQuantity),
              ],
            ),
            if (item.isLowStock || item.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (item.isLowStock)
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFB26A14),
                      size: 17,
                    ),
                  if (item.isLowStock) const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.isLowStock
                          ? 'Stock bas · seuil ${item.lowStockThreshold}'
                          : item.notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: item.isLowStock
                            ? const Color(0xFF9A5A0B)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: canLend ? onLend : null,
                icon: const Icon(Icons.north_east, size: 17),
                label: Text(canLend ? 'Enregistrer une sortie' : 'Aucun stock disponible'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) => switch (category.toLowerCase()) {
    'camping' => Icons.terrain,
    'cuisine' => Icons.soup_kitchen_outlined,
    'pharmacie' => Icons.medical_services_outlined,
    'outillage' => Icons.handyman_outlined,
    'consommables' => Icons.inventory_outlined,
    _ => Icons.backpack_outlined,
  };
}

class _Quantity extends StatelessWidget {
  const _Quantity({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 8),
    child: Column(
      children: [
        Icon(icon, size: 54, color: KitoBrand.mutedInk),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add),
          label: Text(actionLabel),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 44, color: Colors.redAccent),
          const SizedBox(height: 12),
          const Text(
            'Impossible de charger l’inventaire',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );
}
