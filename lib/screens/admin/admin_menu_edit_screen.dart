import 'package:flutter/material.dart';

import '../../models/menu_item.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';

/// Form for adding or editing a menu item.
///
/// Pops with `true` when the item was saved so the caller can reload.
class AdminMenuEditScreen extends StatefulWidget {
  final MenuItem? item;

  const AdminMenuEditScreen({super.key, this.item});

  @override
  State<AdminMenuEditScreen> createState() => _AdminMenuEditScreenState();
}

class _AdminMenuEditScreenState extends State<AdminMenuEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _imageAsset;
  late String _category;
  late bool _available;
  bool _isSaving = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _price = TextEditingController(text: item?.price.toString() ?? '');
    _imageAsset = TextEditingController(text: item?.imageAsset ?? '');
    _category = item?.category ?? MenuCatalog.categories[1];
    _available = item?.available ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _imageAsset.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final repo = AppScope.of(context).menuRepository;

    final price = int.tryParse(_price.text.trim()) ?? 0;
    final existing = widget.item;

    try {
      if (_isEditing && existing != null) {
        final updated = existing.copyWith(
          name: _name.text.trim(),
          description: _description.text.trim(),
          price: price,
          imageAsset: _imageAsset.text.trim(),
          category: _category,
          available: _available,
        );
        await repo.updateItem(updated);
      } else {
        final newItem = MenuItem(
          name: _name.text.trim(),
          description: _description.text.trim(),
          price: price,
          imageAsset: _imageAsset.text.trim(),
          category: _category,
          available: _available,
        );
        await repo.createItem(newItem);
      }
      navigator.pop(true);
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        title: Text(_isEditing ? 'Edit Item' : 'Add Item'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name.' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a description.' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (₹)',
                prefixText: '₹ ',
              ),
              validator: (v) {
                final price = int.tryParse(v?.trim() ?? '');
                if (price == null || price <= 0) {
                  return 'Enter a valid price.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _imageAsset,
              decoration: const InputDecoration(
                labelText: 'Image asset path',
                hintText: 'assets/images/item.jpg',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter an image path.' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final cat in MenuCatalog.categories)
                  if (cat != 'All')
                    DropdownMenuItem(value: cat, child: Text(cat)),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              value: _available,
              onChanged: (v) => setState(() => _available = v),
              title: const Text('Available'),
              subtitle: const Text(
                'Unavailable items are hidden from the student menu.',
              ),
              activeThumbColor: AppColors.successGreen,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Add Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
