import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inventory/domain/equipment_item.dart';
import '../../inventory/presentation/inventory_providers.dart';

Future<void> showLendDialog({
  required BuildContext context,
  required WidgetRef ref,
  required EquipmentItem item,
  required VoidCallback onChanged,
}) async {
  final formKey = GlobalKey<FormState>();
  final borrowerController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  DateTime? dueAt;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Sortie · ${item.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: borrowerController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Emprunteur ou responsable',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Indiquez le nom de la personne.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantité',
                  helperText: '${item.availableQuantity} disponible(s)',
                  prefixIcon: const Icon(Icons.numbers),
                ),
                validator: (value) {
                  final quantity = int.tryParse(value ?? '');
                  if (quantity == null || quantity < 1) {
                    return 'Saisissez une quantité valide.';
                  }
                  if (quantity > item.availableQuantity) {
                    return 'Maximum disponible : ${item.availableQuantity}.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(
                  dueAt == null
                      ? 'Aucune date de retour prévue'
                      : 'Retour prévu le ${_formatDate(dueAt!)}',
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: IconButton(
                  tooltip: 'Choisir la date de retour',
                  icon: Icon(dueAt == null ? Icons.add : Icons.close),
                  onPressed: () async {
                    if (dueAt != null) {
                      setState(() => dueAt = null);
                      return;
                    }
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      helpText: 'Date de retour prévue',
                    );
                    if (picked != null) setState(() => dueAt = picked);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final repository = await ref.read(
                  inventoryRepositoryProvider.future,
                );
                await repository.lendEquipment(
                  item: item,
                  borrower: borrowerController.text,
                  quantity: int.parse(quantityController.text),
                  dueAt: dueAt,
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              } catch (error) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('La sortie a échoué : $error')),
                  );
                }
              }
            },
            child: const Text('Enregistrer la sortie'),
          ),
        ],
      ),
    ),
  );
  borrowerController.dispose();
  quantityController.dispose();
  if (result == true) {
    onChanged();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sortie enregistrée.')),
      );
    }
  }
}

Future<void> confirmDeleteEquipment({
  required BuildContext context,
  required WidgetRef ref,
  required EquipmentItem item,
  required VoidCallback onChanged,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Supprimer cette fiche ?'),
      content: Text(
        '« ${item.name} » et sa fiche seront supprimés de l’inventaire. '
        'Les sorties déjà terminées resteront dans le journal.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    final repository = await ref.read(inventoryRepositoryProvider.future);
    await repository.deleteEquipment(item.id);
    onChanged();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Matériel supprimé.')),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suppression impossible : $error')),
      );
    }
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
