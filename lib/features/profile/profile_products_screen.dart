import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_ai/core/constants/app_strings.dart';
import 'package:food_ai/features/auth/auth_provider.dart';
import 'package:food_ai/services/products_service.dart'
    show deleteProduct, getProducts, insertProduct, ProductRecord;

class ProfileProductsScreen extends ConsumerStatefulWidget {
  const ProfileProductsScreen({super.key});

  @override
  ConsumerState<ProfileProductsScreen> createState() =>
      _ProfileProductsScreenState();
}

class _ProfileProductsScreenState extends ConsumerState<ProfileProductsScreen> {
  List<ProductRecord> _userProducts = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final all = await getProducts(userId: user.id);
    final userOnly = all.where((p) => p.scope == 'user').toList();
    userOnly.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    if (mounted) {
      setState(() {
        _userProducts = userOnly;
        _loading = false;
      });
    }
  }

  Future<void> _addProduct() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text(AppStrings.addOwnProduct),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(labelText: 'Название продукта'),
            autofocus: true,
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(c.text.trim()),
              child: const Text(AppStrings.add),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    final norm = name.trim().toLowerCase();
    // Подтягиваем полный список (глобальные + пользовательские) и проверяем дубликаты
    final all = await getProducts(userId: user.id);
    for (final p in all) {
      if (p.name.trim().toLowerCase() == norm) {
        final msg = p.scope == 'global'
            ? 'Такой продукт уже есть в основном списке'
            : 'У вас уже есть такой продукт';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
        return;
      }
    }
    final p = await insertProduct(
      name: name,
      scope: 'user',
      createdBy: user.id,
    );
    if (p != null && mounted) await _load();
  }

  Future<void> _deleteProduct(ProductRecord p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить продукт?'),
        content: Text('«${p.name}» будет удалён из вашего списка.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await deleteProduct(p.id);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.trim().isEmpty
        ? _userProducts
        : _userProducts
              .where(
                (p) =>
                    p.name.toLowerCase().contains(_query.trim().toLowerCase()),
              )
              .toList();

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final maxWidth = width < 520 ? width - 32 : 520.0;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Мои продукты',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.search),
                                        hintText: 'Поиск продуктов...',
                                      ),
                                      onChanged: (v) =>
                                          setState(() => _query = v),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: OutlinedButton(
                                      onPressed: () {},
                                      child: const Icon(Icons.tune),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              if (_userProducts.isEmpty)
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Нет своих продуктов'),
                                      const SizedBox(height: 16),
                                      FilledButton.icon(
                                        onPressed: _addProduct,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Добавить продукт'),
                                      ),
                                    ],
                                  ),
                                )
                              else ...[
                                Text(
                                  'НЕДАВНО ДОБАВЛЕННЫЕ',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Colors.grey[700],
                                        letterSpacing: 0.8,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filtered.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 4),
                                  itemBuilder: (context, i) {
                                    final p = filtered[i];
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.inventory_2_outlined,
                                        ),
                                        title: Text(
                                          p.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: const Text(
                                          'Пользовательский продукт',
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.pinkAccent,
                                          ),
                                          onPressed: () => _deleteProduct(p),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: _userProducts.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _addProduct,
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить продукт'),
                  ),
                ),
              ),
            ),
    );
  }
}
