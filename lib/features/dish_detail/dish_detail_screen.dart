import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_ai/core/constants/app_strings.dart';
import 'package:food_ai/features/auth/auth_provider.dart';
import 'package:food_ai/features/home/home_providers.dart';
import 'package:food_ai/services/dishes_service.dart';
import 'package:food_ai/services/dish_products_service.dart';
import 'package:food_ai/services/products_service.dart';
import 'package:food_ai/services/storage_service.dart';

class DishDetailScreen extends ConsumerStatefulWidget {
  const DishDetailScreen({super.key, required this.dishId});

  final String dishId;

  @override
  ConsumerState<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends ConsumerState<DishDetailScreen> {
  DishRecord? _dish;
  List<ProductRecord> _composition = [];
  final Set<String> _selectedProductIds = {};
  List<ProductRecord> _allProducts = [];
  final TextEditingController _nameController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dish = await getDishById(widget.dishId);
    if (dish == null || !mounted) {
      setState(() => _loading = false);
      return;
    }
    final composition = await getProductsForDish(widget.dishId);
    final user = ref.read(currentUserProvider);
    List<ProductRecord> all = [];
    if (user != null) {
      all = await getProducts(userId: user.id);
    }
    _nameController.text = dish.name;
    setState(() {
      _dish = dish;
      _composition = composition;
      _selectedProductIds.clear();
      _selectedProductIds.addAll(composition.map((p) => p.id));
      _allProducts = all;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_dish == null) return;
    setState(() => _saving = true);
    try {
      await updateDish(widget.dishId, name: _nameController.text.trim());
      await setDishProducts(widget.dishId, _selectedProductIds.toList());
      if (mounted) {
        ref.invalidate(dishesForSelectedDateProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
    if (mounted) setState(() => _saving = false);
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
        _composition = [..._composition, added];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.dishDetail)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_dish == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.dishDetail)),
        body: const Center(child: Text('Блюдо не найдено')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dishDetail),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text(AppStrings.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_dish!.imageUrl != null && _dish!.imageUrl!.isNotEmpty)
            FutureBuilder<String?>(
              future: getDishImageSignedUrl(_dish!.imageUrl!),
              builder: (context, snap) {
                if (snap.hasData && snap.data != null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      snap.data!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          if (_dish!.imageUrl != null && _dish!.imageUrl!.isNotEmpty) const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: AppStrings.dishName,
            ),
          ),
          const SizedBox(height: 8),
          Text('Дата: ${_dish!.date}', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Text(AppStrings.composition, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ..._composition.map((p) {
            final isSelected = _selectedProductIds.contains(p.id);
            return CheckboxListTile(
              title: Text(p.name),
              value: isSelected,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedProductIds.add(p.id);
                  } else {
                    _selectedProductIds.remove(p.id);
                  }
                });
              },
            );
          }),
          OutlinedButton.icon(
            onPressed: _addOwnProduct,
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.addOwnProduct),
          ),
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
