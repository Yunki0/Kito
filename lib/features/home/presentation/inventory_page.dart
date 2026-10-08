import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/kito_brand.dart';
import '../../../core/theme/kito_colors.dart';
import '../../inventory/domain/equipment_item.dart';
import '../../inventory/presentation/inventory_providers.dart';
import 'inventory_actions.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({
    required this.onEdit,
    required this.onChanged,
    super.key,
  });

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
        final categories = [
          'Tout',
          ...{for (final item in items) item.category},
        ];
        final query = _searchController.text.trim().toLowerCase();
        final visible = items.where((item) {
          final matchesSearch =
              item.name.toLowerCase().contains(query) ||
              item.category.toLowerCase().contains(query);
          final matchesCategory =
              _category == 'Tout' || item.category == _category;
          return matchesSearch &&
              matchesCategory &&
              (!_lowStockOnly || item.isLowStock);
        }).toList();
        final available = items.fold<int>(
          0,
          (total, item) => total + item.availableQuantity,
        );
        final repair = items.fold<int>(
          0,
          (total, item) => total + item.repairQuantity,
        );
        final unusable = items.fold<int>(
          0,
          (total, item) => total + item.unusableQuantity,
        );
        final alerts = items.where((item) => item.isLowStock).length;

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(equipmentProvider),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
              _WelcomeCard(
                itemCount: items.length,
                available: available,
                repair: repair,
                unusable: unusable,
                alerts: alerts,
                onShowAlerts: alerts == 0
                    ? null
                    : () => setState(() => _lowStockOnly = true),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Votre inventaire',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
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
                          onSelected: (_) =>
                              setState(() => _category = category),
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
                  message: 'Ajoutez les tentes, outils et consommables de votre unité pour suivre le stock.',
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 42),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_outlined,
                          size: 42,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Aucun matériel ne correspond',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _category = 'Tout';
                            _lowStockOnly = false;
                          }),
                          child: const Text('Effacer les filtres'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...visible.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _EquipmentCard(
                      item: item,
                      onEdit: () => widget.onEdit(item),
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
            ),
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
    required this.repair,
    required this.unusable,
    required this.alerts,
    required this.onShowAlerts,
  });

  final int itemCount;
  final int available;
  final int repair;
  final int unusable;
  final int alerts;
  final VoidCallback? onShowAlerts;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dark = colorScheme.brightness == Brightness.dark;
    final bannerText = dark ? KitoColors.darkBannerText : KitoColors.bannerText;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [KitoColors.forestDark, KitoColors.darkGradientGreen]
              : [KitoColors.primary, KitoColors.gradientGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tout est prêt\npour la prochaine aventure ?',
            style: TextStyle(
              color: bannerText,
              fontSize: 23,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 4 : 2;
              final spacing = 9.0;
              final tileWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _Stat(
                    label: 'Références',
                    value: '$itemCount',
                    color: bannerText,
                    icon: Icons.inventory_2_outlined,
                    width: tileWidth,
                  ),
                  _Stat(
                    label: 'Disponibles',
                    value: '$available',
                    color: bannerText,
                    icon: Icons.check_circle_outline,
                    width: tileWidth,
                  ),
                  _Stat(
                    label: 'À réparer',
                    value: '$repair',
                    color: bannerText,
                    icon: Icons.build_outlined,
                    width: tileWidth,
                  ),
                  _Stat(
                    label: 'Hors service',
                    value: '$unusable',
                    color: bannerText,
                    icon: Icons.do_not_disturb_alt_outlined,
                    width: tileWidth,
                  ),
                ],
              );
            },
          ),
          if (alerts > 0) ...[
            const SizedBox(height: 16),
            Material(
              color: bannerText.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onShowAlerts,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: bannerText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$alerts ${alerts == 1 ? 'stock à surveiller' : 'stocks à surveiller'}',
                          style: TextStyle(
                            color: bannerText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward, size: 17, color: bannerText),
                    ],
                  ),
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
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.width,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.9), size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.82),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final EquipmentItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
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
            Column(
              children: [
                Row(
                  children: [
                    _Quantity(
                      label: 'Disponible',
                      value: item.availableQuantity,
                    ),
                    _Quantity(label: 'Total', value: item.physicalQuantity),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Quantity(label: 'À réparer', value: item.repairQuantity),
                    _Quantity(
                      label: 'Hors service',
                      value: item.unusableQuantity,
                    ),
                  ],
                ),
              ],
            ),
            if (item.isLowStock || item.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (item.isLowStock)
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.tertiary,
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
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
    child: Row(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: label == 'À réparer' && value > 0
                ? Theme.of(context).colorScheme.tertiary
                : label == 'Hors service' && value > 0
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
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
        Icon(
          icon,
          size: 54,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
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
          Icon(
            Icons.error_outline,
            size: 44,
            color: Theme.of(context).colorScheme.error,
          ),
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
