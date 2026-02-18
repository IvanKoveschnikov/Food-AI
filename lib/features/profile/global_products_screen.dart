import 'package:flutter/material.dart';
import 'package:food_ai/core/constants/app_strings.dart';
import 'package:food_ai/services/products_service.dart';

class GlobalProductsScreen extends StatefulWidget {
  const GlobalProductsScreen({super.key});

  @override
  State<GlobalProductsScreen> createState() => _GlobalProductsScreenState();
}

class _GlobalProductsScreenState extends State<GlobalProductsScreen> {
  List<ProductRecord> _products = [];
  List<ProductRecord> _filtered = [];
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await getGlobalProducts();
    if (mounted) {
      _products = list;
      _applySearch();
      setState(() => _loading = false);
    }
  }

  void _applySearch() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List.from(_products);
    } else {
      _filtered = _products.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.mainProductList),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Поиск по названию',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          _products.isEmpty ? 'Нет продуктов в основном списке' : 'Ничего не найдено',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final p = _filtered[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.shopping_basket_outlined),
                                title: Text(p.name),
                                subtitle: const Text('Основной список'),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
