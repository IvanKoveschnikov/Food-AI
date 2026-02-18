import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_ai/core/constants/app_strings.dart';
import 'package:food_ai/features/auth/auth_provider.dart';
import 'package:food_ai/services/dish_templates_service.dart';
import 'package:food_ai/services/products_service.dart';

class TemplateEditScreen extends ConsumerStatefulWidget {
  const TemplateEditScreen({super.key, required this.templateId, required this.name});

  final String templateId;
  final String name;

  @override
  ConsumerState<TemplateEditScreen> createState() => _TemplateEditScreenState();
}

class _TemplateEditScreenState extends ConsumerState<TemplateEditScreen> {
  late TextEditingController _nameController;
  List<ProductRecord> _allProducts = [];
  List<ProductRecord> _templateProducts = [];
  final Set<String> _selectedIds = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final all = await getProducts(userId: user.id);
    final templateProds = await getTemplateProducts(widget.templateId);
    setState(() {
      _allProducts = all;
      _templateProducts = templateProds;
      _selectedIds.clear();
      _selectedIds.addAll(templateProds.map((p) => p.id));
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await updateTemplate(widget.templateId, _nameController.text.trim());
      await setTemplateProducts(widget.templateId, _selectedIds.toList());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить список?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await deleteTemplate(widget.templateId);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _addProduct() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final added = await showDialog<ProductRecord>(
      context: context,
      builder: (ctx) => _PickProductDialog(
        existing: _allProducts,
        selectedIds: _selectedIds,
        userId: user.id,
      ),
    );
    if (added != null && mounted) {
      setState(() {
        _selectedIds.add(added.id);
        if (!_templateProducts.any((p) => p.id == added.id)) {
          _templateProducts = [..._templateProducts, added];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.myDishes)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final displayList = <ProductRecord>[];
    for (final id in _selectedIds) {
      final p = _allProducts.cast<ProductRecord?>().firstWhere(
            (x) => x?.id == id,
            orElse: () => null,
          );
      if (p != null) displayList.add(p);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование списка'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text(AppStrings.save),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Название списка'),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.products, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...displayList.map((p) {
            final selected = _selectedIds.contains(p.id);
            return CheckboxListTile(
              title: Text(p.name),
              value: selected,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedIds.add(p.id);
                  } else {
                    _selectedIds.remove(p.id);
                  }
                });
              },
            );
          }),
          OutlinedButton.icon(
            onPressed: _addProduct,
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.addOwnProduct),
          ),
        ],
      ),
    );
  }
}

class _PickProductDialog extends StatefulWidget {
  const _PickProductDialog({required this.existing, required this.selectedIds, required this.userId});

  final List<ProductRecord> existing;
  final Set<String> selectedIds;
  final String userId;

  @override
  State<_PickProductDialog> createState() => _PickProductDialogState();
}

class _PickProductDialogState extends State<_PickProductDialog> {
  final _nameController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<ProductRecord> get _filtered {
    if (_query.isEmpty) return widget.existing;
    final q = _query.toLowerCase();
    return widget.existing.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.addOwnProduct),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Поиск или новое название'),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtered.length + 1,
                itemBuilder: (context, i) {
                  if (i == _filtered.length) {
                    if (_nameController.text.trim().isEmpty) return const SizedBox.shrink();
                    return ListTile(
                      title: Text('Создать "${_nameController.text.trim()}"'),
                      leading: const Icon(Icons.add),
                      onTap: () async {
                        final name = _nameController.text.trim();
                        if (name.isEmpty) return;
                        final p = await insertProduct(name: name, scope: 'user', createdBy: widget.userId);
                        if (p != null && mounted) Navigator.of(context).pop(p);
                      },
                    );
                  }
                  final p = _filtered[i];
                  final already = widget.selectedIds.contains(p.id);
                  return ListTile(
                    title: Text(p.name),
                    enabled: !already,
                    subtitle: already ? const Text('Уже в списке') : null,
                    onTap: () => Navigator.of(context).pop(p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
      ],
    );
  }
}
