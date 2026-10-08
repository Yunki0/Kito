import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/equipment_item.dart';
import 'inventory_providers.dart';

class EquipmentFormPage extends ConsumerStatefulWidget {
  const EquipmentFormPage({required this.item, super.key});

  final EquipmentItem? item;

  @override
  ConsumerState<EquipmentFormPage> createState() => _EquipmentFormPageState();
}

class _EquipmentFormPageState extends ConsumerState<EquipmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _newController;
  late final TextEditingController _goodController;
  late final TextEditingController _repairController;
  late final TextEditingController _unusableController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _notesController;
  late bool _isConsumable;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _categoryController = TextEditingController(text: item?.category ?? '');
    _newController = TextEditingController(text: '${item?.newQuantity ?? 0}');
    _goodController = TextEditingController(text: '${item?.goodQuantity ?? 0}');
    _repairController = TextEditingController(
      text: '${item?.repairQuantity ?? 0}',
    );
    _unusableController = TextEditingController(
      text: '${item?.unusableQuantity ?? 0}',
    );
    _thresholdController = TextEditingController(
      text: '${item?.lowStockThreshold ?? 0}',
    );
    _notesController = TextEditingController(text: item?.notes ?? '');
    _isConsumable = item?.isConsumable ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _newController.dispose();
    _goodController.dispose();
    _repairController.dispose();
    _unusableController.dispose();
    _thresholdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _number(TextEditingController controller) =>
      int.parse(controller.text.trim());

  String? _validateQuantity(String? value, {bool allowZero = true}) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < (allowZero ? 0 : 1)) {
      return allowZero ? 'Saisissez un nombre positif ou nul.' : 'Minimum : 1.';
    }
    if (number > 100000) return 'La quantité est trop élevée.';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repository = await ref.read(inventoryRepositoryProvider.future);
      await repository.saveEquipment(
        EquipmentItem(
          id: widget.item?.id ?? '',
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          newQuantity: _number(_newController),
          goodQuantity: _number(_goodController),
          repairQuantity: _number(_repairController),
          unusableQuantity: _number(_unusableController),
          lowStockThreshold: _isConsumable ? _number(_thresholdController) : 0,
          isConsumable: _isConsumable,
          notes: _notesController.text.trim(),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enregistrement impossible : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingCategories = [
      'Camping',
      'Cuisine',
      'Outillage',
      'Pharmacie',
      'Consommables',
    ];
    if (_categoryController.text.isNotEmpty &&
        !existingCategories.contains(_categoryController.text)) {
      existingCategories.add(_categoryController.text);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item?.id.isNotEmpty == true
              ? 'Modifier le matériel'
              : 'Ajouter du matériel',
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_isSaving ? 'Enregistrement…' : 'Enregistrer'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text(
              'Identification',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nom du matériel',
                hintText: 'Ex. Tente 3 places',
                prefixIcon: Icon(Icons.backpack_outlined),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Le nom est obligatoire.'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue:
                  existingCategories.contains(_categoryController.text)
                  ? _categoryController.text
                  : null,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              hint: const Text('Choisir une catégorie'),
              items: existingCategories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) _categoryController.text = value;
              },
              validator: (value) =>
                  value == null ? 'Choisissez une catégorie.' : null,
            ),
            const SizedBox(height: 24),
            const Text(
              'État et quantités',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'Les articles neufs et en bon état sont disponibles.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _quantityField(
                    controller: _newController,
                    label: 'Neuf',
                    icon: Icons.auto_awesome_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quantityField(
                    controller: _goodController,
                    label: 'Bon état',
                    icon: Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _quantityField(
                    controller: _repairController,
                    label: 'À réparer',
                    icon: Icons.build_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quantityField(
                    controller: _unusableController,
                    label: 'Hors service',
                    icon: Icons.do_not_disturb_alt_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              value: _isConsumable,
              onChanged: (value) => setState(() => _isConsumable = value),
              title: const Text(
                'Consommable',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Afficher une alerte lorsque le stock est bas',
              ),
            ),
            if (_isConsumable) ...[
              const SizedBox(height: 8),
              _quantityField(
                controller: _thresholdController,
                label: 'Seuil d’alerte',
                icon: Icons.notifications_active_outlined,
              ),
            ],
            const SizedBox(height: 20),
            TextFormField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (facultatif)',
                hintText: 'Taille, emplacement, remarques…',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _quantityField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    validator: _validateQuantity,
  );
}
