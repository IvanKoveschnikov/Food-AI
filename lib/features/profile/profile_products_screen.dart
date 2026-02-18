import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_ai/core/constants/app_strings.dart';
import 'package:food_ai/features/auth/auth_provider.dart';
import 'package:food_ai/services/products_service.dart' show deleteProduct, getProducts, insertProduct, ProductRecord;

class ProfileProductsScreen extends ConsumerStatefulWidget {
  const ProfileProductsScreen({super.key});

  @override
  ConsumerState<ProfileProductsScreen> createState() => _ProfileProductsScreenState();
}

class _ProfileProductsScreenState extends ConsumerState<ProfileProductsScreen> {
  List<ProductRecord> _userProducts = [];
  bool _loading = true;

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
    if (mounted) setState(() {
      _userProducts = userOnly;
      _loading = false;
    });
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
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text(AppStrings.cancel)),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(c.text.trim()),
              child: const Text(AppStrings.add),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    final p = await insertProduct(name: name, scope: 'user', createdBy: user.id);
    if (p != null && mounted) await _load();
  }

  Future<void> _deleteProduct(ProductRecord p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить продукт?'),
        content: Text('«${p.name}» будет удалён из вашего списка.'),
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
    await deleteProduct(p.id);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myProducts),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _userProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _userProducts.length,
                    itemBuilder: (context, i) {
                      final p = _userProducts[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(p.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteProduct(p),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _userProducts.isEmpty ? null : FloatingActionButton(
        onPressed: _addProduct,
        child: const Icon(Icons.add),
      ),
    );
  }
}
