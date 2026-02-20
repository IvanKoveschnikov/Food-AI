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
  double _totalCalories = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;

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
    try {
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
      final totals = _calculateTotals(composition);
      setState(() {
        _dish = dish;
        _composition = composition;
        _selectedProductIds.clear();
        _selectedProductIds.addAll(composition.map((p) => p.id));
        _allProducts = all;
        _loading = false;
        _totalCalories = totals.$1;
        _totalProtein = totals.$2;
        _totalCarbs = totals.$3;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _addOwnProduct() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final added = await showDialog<ProductRecord>(
      context: context,
      builder: (ctx) =>
          _AddProductDialog(existingProducts: _allProducts, userId: user.id),
    );
    if (added != null && mounted) {
      setState(() {
        _allProducts = [..._allProducts, added];
        _selectedProductIds.add(added.id);
        _composition = [..._composition, added];
        final totals = _calculateTotals(_composition);
        _totalCalories = totals.$1;
        _totalProtein = totals.$2;
        _totalCarbs = totals.$3;
      });
    }
  }

  (double, double, double) _calculateTotals(List<ProductRecord> products) {
    var kcal = 0.0;
    var protein = 0.0;
    var carbs = 0.0;
    for (final p in products) {
      kcal += p.calories ?? 0;
      protein += p.protein ?? 0;
      carbs += p.carbs ?? 0;
    }
    return (kcal, protein, carbs);
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
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(AppStrings.save),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final maxWidth = width < 520 ? width - 32 : 520.0;
            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_dish!.imageUrl != null &&
                          _dish!.imageUrl!.isNotEmpty)
                        FutureBuilder<String?>(
                          future: getDishImageSignedUrl(_dish!.imageUrl!),
                          builder: (context, snap) {
                            if (snap.hasData && snap.data != null) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  snap.data!,
                                  height: 220,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox.shrink(),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      if (_dish!.imageUrl != null &&
                          _dish!.imageUrl!.isNotEmpty)
                        const SizedBox(height: 16),

                      // Название и дата
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Название блюда',
                          hintText: 'Например: Авокадо-тост с яйцом',
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Дата: ${_dish!.date}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),

                      // Карточки ККАЛ/Б/Ж/У (пока без расчётов)
                      Row(
                        children: [
                          Expanded(
                            child: _MacroCard(
                              label: 'ККАЛ',
                              value: _totalCalories == 0
                                  ? '—'
                                  : _totalCalories.round().toString(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MacroCard(
                              label: 'БЕЛКИ',
                              value: _totalProtein == 0
                                  ? '—'
                                  : _totalProtein.toStringAsFixed(1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MacroCard(
                              label: 'УГЛЕВ',
                              value: _totalCarbs == 0
                                  ? '—'
                                  : _totalCarbs.toStringAsFixed(1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Совет ИИ (описание)
                      if ((_dish!.description ?? '').trim().isNotEmpty)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Совет ИИ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _dish!.description!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      if ((_dish!.description ?? '').trim().isNotEmpty)
                        const SizedBox(height: 16),

                      // Состав
                      Text(
                        AppStrings.composition,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._composition.map(
                            (p) => InputChip(
                              label: Text(p.name),
                              onDeleted: () {
                                setState(() {
                                  _selectedProductIds.remove(p.id);
                                  _composition = _composition
                                      .where((e) => e.id != p.id)
                                      .toList();
                                  final totals =
                                      _calculateTotals(_composition);
                                  _totalCalories = totals.$1;
                                  _totalProtein = totals.$2;
                                  _totalCarbs = totals.$3;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _addOwnProduct,
                          icon: const Icon(Icons.add),
                          label: const Text(AppStrings.addOwnProduct),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey[700],
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddProductDialog extends StatefulWidget {
  const _AddProductDialog({
    required this.existingProducts,
    required this.userId,
  });

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
    return widget.existingProducts
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
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
              decoration: const InputDecoration(
                hintText: 'Поиск или новое название',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtered.length + 1,
                itemBuilder: (context, i) {
                  if (i == _filtered.length) {
                    if (_nameController.text.trim().isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return ListTile(
                      title: Text('Создать "${_nameController.text.trim()}"'),
                      leading: const Icon(Icons.add),
                      onTap: () async {
                        final name = _nameController.text.trim();
                        if (name.isEmpty) {
                          return;
                        }
                        final navigator = Navigator.of(context);
                        final p = await insertProduct(
                          name: name,
                          scope: 'user',
                          createdBy: widget.userId,
                        );
                        if (p != null) {
                          navigator.pop(p);
                        }
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
