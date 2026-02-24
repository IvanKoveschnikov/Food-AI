import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:food_ai/core/constants/app_strings.dart';
import 'package:food_ai/features/auth/auth_provider.dart';
import 'package:food_ai/features/home/home_providers.dart';
import 'package:food_ai/services/ai_service.dart';
import 'package:food_ai/services/dishes_service.dart';
import 'package:food_ai/services/dish_products_service.dart';
import 'package:food_ai/services/products_service.dart';
import 'package:food_ai/services/storage_service.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  XFile? _pickedFile;
  File? _file;
  String _name = '';
  List<String> _suggestedProductNames = [];
  final Set<String> _selectedProductIds = {};
  final Set<String> _selectedNamesNoId = {};
  final Map<String, String> _nameToProductId = {};
  List<ProductRecord> _allProducts = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _loading = false;
  bool _analyzing = false;
  String? _analysisError;
  String _aiAdvice = '';
  int _confidence = 0;
  int _weightGrams = 100;
  late FixedExtentScrollController _wheelController;

  @override
  void initState() {
    super.initState();
    _wheelController = FixedExtentScrollController(initialItem: 9);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _wheelController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source, imageQuality: 85);
    if (xFile == null || !mounted) return;
    setState(() {
      _pickedFile = xFile;
      _file = File(xFile.path);
      _analyzing = true;
    });
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    if (_file == null) return;
    setState(() => _analysisError = null);
    final bytes = await _file!.readAsBytes();
    try {
      final result = await analyzeDishImage(bytes);
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      if (user != null) {
        _allProducts = await getProducts(userId: user.id);
      }
      final nameToId = <String, String>{};
      for (final p in _allProducts) {
        nameToId.putIfAbsent(p.name.toLowerCase(), () => p.id);
      }
      final seen = <String>{};
      final uniqueNames = <String>[];
      for (final raw in result.productNames) {
        final trimmed = raw.trim();
        if (trimmed.isEmpty) continue;
        final lower = trimmed.toLowerCase();
        if (seen.add(lower)) {
          uniqueNames.add(trimmed);
        }
      }
      final rawDishName = result.dishName.trim();
      final normalizedDishName = rawDishName.isEmpty
          ? 'Блюдо'
          : rawDishName[0].toUpperCase() + rawDishName.substring(1);
      _nameController.text = normalizedDishName;
      _descriptionController.text = result.description;
      setState(() {
        _name = normalizedDishName;
        _suggestedProductNames = uniqueNames;
        _nameToProductId.clear();
        _selectedProductIds.clear();
        _selectedNamesNoId.clear();
        for (final n in uniqueNames) {
          final id = nameToId[n.toLowerCase()];
          if (id != null) {
            _nameToProductId[n] = id;
            _selectedProductIds.add(id);
          } else {
            _selectedNamesNoId.add(n);
          }
        }
        _analyzing = false;
        _analysisError = null;
        _aiAdvice = result.aiAdvice;
        _confidence = result.confidence;
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

  String _dateStr() {
    final date = ref.read(selectedDateProvider);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final productIds = Set<String>.from(_selectedProductIds);
      final existingByName = <String, ProductRecord>{};
      for (final p in _allProducts) {
        existingByName[p.name.trim().toLowerCase()] = p;
      }
      for (final rawName in _selectedNamesNoId) {
        final name = rawName.trim();
        if (name.isEmpty) continue;
        final lower = name.toLowerCase();
        final existing = existingByName[lower];
        if (existing != null) {
          productIds.add(existing.id);
          continue;
        }
        final p = await insertProduct(
          name: name,
          scope: 'user',
          createdBy: user.id,
        );
        if (p != null) {
          productIds.add(p.id);
          existingByName[lower] = p;
          _allProducts = [..._allProducts, p];
        }
      }
      String? imagePath;
      if (_file != null) {
        try {
          final exists = await _file!.exists();
          if (exists) {
            final dishId = DateTime.now().millisecondsSinceEpoch.toString();
            imagePath = await uploadDishImage(
              userId: user.id,
              dishId: dishId,
              file: _file!,
            );
          }
        } catch (_) {
          imagePath = null;
        }
      }
      final dish = await insertDish(
        userId: user.id,
        name: _name.trim().isEmpty ? 'Блюдо' : _name.trim(),
        date: _dateStr(),
        imageUrl: imagePath,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        aiAdvice: _aiAdvice.isEmpty ? null : _aiAdvice,
        confidence: _confidence,
        weightGrams: _weightGrams,
      );
      await setDishProducts(dish.id, productIds.toList());
      if (mounted) {
        ref.invalidate(dishesForSelectedDateProvider);
        // Сброс состояния экрана для нового фото
        setState(() {
          _pickedFile = null;
          _file = null;
          _name = '';
          _nameController.clear();
          _descriptionController.clear();
          _suggestedProductNames = [];
          _selectedProductIds.clear();
          _selectedNamesNoId.clear();
          _nameToProductId.clear();
          _aiAdvice = '';
          _confidence = 0;
          _weightGrams = 100;
          _wheelController.jumpToItem(9);
          _analysisError = null;
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Блюдо сохранено в дневник!')),
        );
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pickedFile == null || _file == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ИИ анализ')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Сделайте фото или выберите из галереи',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text(AppStrings.takePhoto),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text(AppStrings.chooseFromGallery),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('ИИ анализ'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final maxFormWidth = width < 480 ? width - 32 : 480.0;
          final topPadding = height > 700 ? 16.0 : 8.0;
          return Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxFormWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Hero(
                          tag:
                              'dish_image_new', // We don't have id yet, but Hero works conceptually
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _file!,
                              height: 240,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          top: 16,
                          child:
                              Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                              Icons.bolt,
                                              size: 16,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                            )
                                            .animate(onPlay: (c) => c.repeat())
                                            .shimmer(
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                              color: Colors.white,
                                            ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'ИИ АНАЛИЗ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .slideX(begin: -0.2, end: 0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _analyzing
                                ? null
                                : () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Галерея'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _analyzing
                                ? null
                                : () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Переснять'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_analyzing)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('ИИ анализирует фото...'),
                          ],
                        ),
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
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _runAnalysis,
                                child: const Text('Повторить'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'НАЗВАНИЕ БЛЮДА',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Например: Авокадо-тост с яйцом пашот',
                      ),
                      onChanged: (v) => setState(() => _name = v),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ОПИСАНИЕ ИИ',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Краткое описание блюда, сгенерированное ИИ. Можно отредактировать.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ОБНАРУЖЕННЫЕ ПРОДУКТЫ',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._suggestedProductNames.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final name = entry.value;
                          final productId = _nameToProductId[name];
                          final isSelected = productId != null
                              ? _selectedProductIds.contains(productId)
                              : _selectedNamesNoId.contains(name);
                          return FilterChip(
                                label: Text(name),
                                selected: isSelected,
                                selectedColor: Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.2),
                                checkmarkColor: Theme.of(
                                  context,
                                ).colorScheme.secondary,
                                onSelected: (selected) async {
                                  if (productId != null) {
                                    setState(() {
                                      if (selected) {
                                        _selectedProductIds.add(productId);
                                      } else {
                                        _selectedProductIds.remove(productId);
                                      }
                                    });
                                  } else {
                                    if (selected) {
                                      final user = ref.read(
                                        currentUserProvider,
                                      );
                                      if (user == null) return;
                                      final created = await insertProduct(
                                        name: name,
                                        scope: 'user',
                                        createdBy: user.id,
                                      );
                                      if (created != null && mounted) {
                                        setState(() {
                                          _nameToProductId[name] = created.id;
                                          _allProducts = [
                                            ..._allProducts,
                                            created,
                                          ];
                                          _selectedNamesNoId.remove(name);
                                          _selectedProductIds.add(created.id);
                                        });
                                      }
                                    } else {
                                      setState(
                                        () => _selectedNamesNoId.remove(name),
                                      );
                                    }
                                  }
                                },
                              )
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: 50 * idx))
                              .scale(begin: const Offset(0.8, 0.8));
                        }).toList(),
                        ActionChip(
                          label: const Text('+ Продукт'),
                          onPressed: _addOwnProduct,
                        ).animate().fadeIn(
                          delay: Duration(
                            milliseconds: 50 * _suggestedProductNames.length,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Горизонтальный пикер граммов
                    Column(
                      children: [
                        Text(
                          'Вес порции',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_weightGrams г',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 50,
                          child: RotatedBox(
                            quarterTurns: -1,
                            child: ListWheelScrollView.useDelegate(
                              controller: _wheelController,
                              itemExtent: 40,
                              perspective: 0.003,
                              diameterRatio: 1.8,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                setState(() => _weightGrams = (index + 1) * 10);
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 200,
                                builder: (context, index) {
                                  final grams = (index + 1) * 10;
                                  final isSelected = grams == _weightGrams;
                                  return RotatedBox(
                                    quarterTurns: 1,
                                    child: Center(
                                      child: Container(
                                        width: 2,
                                        height: isSelected ? 28 : 16,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : grams % 50 == 0
                                              ? Colors.grey[400]
                                              : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(
                                            1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading ? null : _save,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: const StadiumBorder(),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('СОХРАНИТЬ В ДНЕВНИК'),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _confidence > 0
                            ? 'Уверенность ИИ: $_confidence%'
                            : 'Анализ не выполнен',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _confidence >= 80
                              ? Colors.green
                              : _confidence >= 50
                              ? Colors.orange
                              : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading ? null : () => context.go('/'),
                      child: const Text(AppStrings.cancel),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
                    if (_nameController.text.trim().isEmpty)
                      return const SizedBox.shrink();
                    return ListTile(
                      title: Text('Создать "${_nameController.text.trim()}"'),
                      leading: const Icon(Icons.add),
                      onTap: () async {
                        final name = _nameController.text.trim();
                        if (name.isEmpty) return;
                        final p = await insertProduct(
                          name: name,
                          scope: 'user',
                          createdBy: widget.userId,
                        );
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
