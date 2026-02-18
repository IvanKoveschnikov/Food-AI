import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_ai/core/constants/app_strings.dart';
import 'package:food_ai/features/auth/auth_provider.dart';
import 'package:food_ai/features/home/home_providers.dart';
import 'package:food_ai/services/ai_service.dart';
import 'package:food_ai/services/dishes_service.dart';
import 'package:food_ai/services/dish_products_service.dart';
import 'package:food_ai/services/dish_templates_service.dart';
import 'package:food_ai/services/products_service.dart';

class AddDishNoPhotoScreen extends ConsumerStatefulWidget {
  const AddDishNoPhotoScreen({super.key, this.selectedDate});

  final String? selectedDate;

  @override
  ConsumerState<AddDishNoPhotoScreen> createState() => _AddDishNoPhotoScreenState();
}

class _AddDishNoPhotoScreenState extends ConsumerState<AddDishNoPhotoScreen> {
  bool _byDescription = true;
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  List<String> _suggestedProductNames = [];
  final Set<String> _selectedProductIds = {};
  final Set<String> _selectedNamesNoId = {};
  final Map<String, String> _nameToProductId = {};
  List<ProductRecord> _allProducts = [];
  List<DishTemplateRecord> _templates = [];
  String? _selectedTemplateId;
  bool _analyzing = false;
  bool _loading = false;
  bool _formReady = false;
  String? _analysisError;

  @override
  void dispose() {
    _descController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _dateStr() {
    if (widget.selectedDate != null && widget.selectedDate!.isNotEmpty) {
      return widget.selectedDate!;
    }
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _analyzeByDescription() async {
    setState(() {
      _analyzing = true;
      _analysisError = null;
    });
    try {
      final result = await analyzeDishDescription(_descController.text.trim());
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      if (user != null) {
        _allProducts = await getProducts(userId: user.id);
      }
      final nameToId = <String, String>{};
      for (final p in _allProducts) {
        nameToId.putIfAbsent(p.name.toLowerCase(), () => p.id);
      }
      _nameController.text = result.dishName;
      setState(() {
        _suggestedProductNames = result.productNames;
        _selectedProductIds.clear();
        _selectedNamesNoId.clear();
        _nameToProductId.clear();
        for (final n in result.productNames) {
          final id = nameToId[n.toLowerCase()];
          if (id != null) {
            _nameToProductId[n] = id;
            _selectedProductIds.add(id);
          } else {
            _selectedNamesNoId.add(n);
          }
        }
        _analyzing = false;
        _formReady = true;
        _analysisError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _analyzing = false;
          _analysisError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _loadTemplates() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final list = await getTemplatesForUser(user.id);
    setState(() => _templates = list);
  }

  Future<void> _selectTemplate(String? templateId) async {
    if (templateId == null) {
      setState(() {
        _selectedTemplateId = null;
        _formReady = false;
        _nameController.clear();
        _suggestedProductNames = [];
        _selectedProductIds.clear();
        _selectedNamesNoId.clear();
        _nameToProductId.clear();
      });
      return;
    }
    final products = await getTemplateProducts(templateId);
    DishTemplateRecord? template;
    for (final t in _templates) {
      if (t.id == templateId) {
        template = t;
        break;
      }
    }
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _allProducts = await getProducts(userId: user.id);
    }
    _nameController.text = template?.name ?? 'Блюдо';
    setState(() {
      _selectedTemplateId = templateId;
      _suggestedProductNames = products.map((p) => p.name).toList();
      _selectedProductIds.clear();
      _selectedNamesNoId.clear();
      _nameToProductId.clear();
      for (final p in products) {
        _nameToProductId[p.name] = p.id;
        _selectedProductIds.add(p.id);
      }
      _formReady = true;
    });
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final productIds = Set<String>.from(_selectedProductIds);
      for (final name in _selectedNamesNoId) {
        final p = await insertProduct(name: name, scope: 'user', createdBy: user.id);
        if (p != null) productIds.add(p.id);
      }
      final dish = await insertDish(
        userId: user.id,
        name: _nameController.text.trim().isEmpty ? 'Блюдо' : _nameController.text.trim(),
        date: _dateStr(),
      );
      await setDishProducts(dish.id, productIds.toList());
      if (mounted) {
        ref.invalidate(dishesForSelectedDateProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addOwnProduct() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final added = await showDialog<ProductRecord>(
      context: context,
      builder: (ctx) => _AddProductDialog(
        existingProducts: _allProducts,
        userId: user.id,
      ),
    );
    if (added != null && mounted) {
      setState(() {
        _allProducts = [..._allProducts, added];
        _selectedProductIds.add(added.id);
        if (!_suggestedProductNames.contains(added.name)) {
          _suggestedProductNames = [..._suggestedProductNames, added.name];
          _nameToProductId[added.name] = added.id;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.addDishNoPhoto),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('По описанию'), icon: Icon(Icons.text_fields)),
              ButtonSegment(value: false, label: Text('Из списка'), icon: Icon(Icons.list)),
            ],
            selected: {_byDescription},
            onSelectionChanged: (s) {
              setState(() {
                _byDescription = s.first;
                _formReady = false;
                if (!_byDescription) _loadTemplates();
              });
            },
          ),
          const SizedBox(height: 16),
          if (_byDescription) ...[
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Описание или название',
                hintText: 'Опишите блюдо или введите название',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _analyzing ? null : _analyzeByDescription,
              child: _analyzing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Получить состав'),
            ),
            if (_analysisError != null) ...[
              const SizedBox(height: 12),
              Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _analysisError!,
                          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _analyzeByDescription(),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else ...[
            if (_templates.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Нет готовых списков. Создайте в профиле.')),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedTemplateId,
                decoration: const InputDecoration(labelText: 'Готовый список'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Выберите список')),
                  ..._templates.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                ],
                onChanged: (v) => _selectTemplate(v),
              ),
          ],
          if (_formReady) ...[
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: AppStrings.dishName),
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            Text(AppStrings.products, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ..._suggestedProductNames.map((name) {
              final productId = _nameToProductId[name];
              final isSelected = productId != null
                  ? _selectedProductIds.contains(productId)
                  : _selectedNamesNoId.contains(name);
              return CheckboxListTile(
                title: Text(name),
                value: isSelected,
                onChanged: (v) async {
                  if (productId != null) {
                    setState(() {
                      if (v == true) {
                        _selectedProductIds.add(productId);
                      } else {
                        _selectedProductIds.remove(productId);
                      }
                    });
                  } else {
                    if (v == true) {
                      final user = ref.read(currentUserProvider);
                      if (user == null) return;
                      final created = await insertProduct(name: name, scope: 'user', createdBy: user.id);
                      if (created != null && mounted) {
                        setState(() {
                          _nameToProductId[name] = created.id;
                          _allProducts = [..._allProducts, created];
                          _selectedNamesNoId.remove(name);
                          _selectedProductIds.add(created.id);
                        });
                      }
                    } else {
                      setState(() => _selectedNamesNoId.remove(name));
                    }
                  }
                },
              );
            }),
            OutlinedButton.icon(
              onPressed: _addOwnProduct,
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addOwnProduct),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text(AppStrings.save),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : () => context.pop(),
              child: const Text(AppStrings.cancel),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddProductDialog extends StatefulWidget {
  const _AddProductDialog({required this.existingProducts, required this.userId});

  final List<ProductRecord> existingProducts;
  final String userId;

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  final _nameController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<ProductRecord> get _filtered {
    if (_query.isEmpty) return widget.existingProducts;
    final q = _query.toLowerCase();
    return widget.existingProducts.where((p) => p.name.toLowerCase().contains(q)).toList();
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
                  return ListTile(
                    title: Text(p.name),
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
