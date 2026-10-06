import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/kito_brand.dart';
import '../../../core/theme/kito_colors.dart';
import '../../inventory/domain/equipment_item.dart';
import '../../inventory/presentation/inventory_providers.dart';

class MovementsPage extends ConsumerWidget {
  const MovementsPage({required this.onChanged, super.key});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movements = ref.watch(movementsProvider);
    return movements.when(
      loading: () => const KitoLoadingView(message: 'Chargement des emprunts…'),
      error: (error, _) => _MovementError(
        message: '$error',
        onRetry: () => ref.invalidate(movementsProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: const [
              SizedBox(height: 70),
              Icon(
                Icons.swap_horiz,
                size: 56,
                color: KitoColors.textSecondary,
              ),
              SizedBox(height: 16),
              Text(
                'Aucun emprunt en cours',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                'Les sorties de matériel apparaîtront ici. Ouvrez une fiche dans l’inventaire pour enregistrer un prêt.',
                textAlign: TextAlign.center,
              ),
            ],
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(movementsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                '${items.length} ${items.length == 1 ? 'emprunt en cours' : 'emprunts en cours'}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...items.map(
                (movement) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MovementCard(
                    movement: movement,
                    onReturn: () => _returnItem(context, ref, movement),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _returnItem(
    BuildContext context,
    WidgetRef ref,
    StockMovement movement,
  ) async {
    final quantityController = TextEditingController(
      text: '${movement.outstandingQuantity}',
    );
    final formKey = GlobalKey<FormState>();
    final quantity = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Retour · ${movement.equipmentName}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: quantityController,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Quantité rendue',
              helperText: '${movement.outstandingQuantity} encore emprunté(s)',
            ),
            validator: (value) {
              final parsed = int.tryParse(value ?? '');
              if (parsed == null || parsed < 1) {
                return 'Saisissez une quantité valide.';
              }
              if (parsed > movement.outstandingQuantity) {
                return 'Cette personne n’en a plus autant.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, int.parse(quantityController.text));
              }
            },
            child: const Text('Confirmer le retour'),
          ),
        ],
      ),
    );
    quantityController.dispose();
    if (quantity == null || !context.mounted) return;
    try {
      final repository = await ref.read(inventoryRepositoryProvider.future);
      await repository.returnEquipment(movement: movement, quantity: quantity);
      onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retour enregistré.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Le retour a échoué : $error')),
        );
      }
    }
  }
}

class _MovementCard extends StatelessWidget {
  const _MovementCard({required this.movement, required this.onReturn});
  final StockMovement movement;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dueDate = movement.dueAt;
    final overdue =
        dueDate != null &&
        DateTime(dueDate.year, dueDate.month, dueDate.day).isBefore(
          DateTime(today.year, today.month, today.day),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: KitoColors.paleGreen,
                  child: Icon(
                    Icons.person_outline,
                    color: KitoColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movement.borrower,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        movement.equipmentName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '× ${movement.outstandingQuantity}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Icon(
                  overdue ? Icons.warning_amber_rounded : Icons.event_outlined,
                  size: 17,
                  color: overdue ? Colors.red.shade700 : null,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    movement.dueAt == null
                        ? 'Sorti le ${_formatDate(movement.checkedOutAt)} · sans échéance'
                        : 'Retour prévu le ${_formatDate(movement.dueAt!)}',
                    style: TextStyle(
                      color: overdue
                          ? Colors.red.shade700
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            if (movement.returnedQuantity > 0)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '${movement.returnedQuantity} déjà rendu(s) sur ${movement.quantity}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onReturn,
                icon: const Icon(Icons.south_west, size: 18),
                label: const Text('Enregistrer un retour'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _MovementError extends StatelessWidget {
  const _MovementError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Impossible de charger les emprunts : $message'),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
        ),
      ],
    ),
  );
}
