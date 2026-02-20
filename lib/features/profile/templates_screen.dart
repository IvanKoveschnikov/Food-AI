import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_ai/core/constants/app_strings.dart';
import 'package:food_ai/features/auth/auth_provider.dart';
import 'package:food_ai/features/profile/template_edit_screen.dart';
import 'package:food_ai/services/dish_templates_service.dart';

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  List<DishTemplateRecord> _templates = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    final list = await getTemplatesForUser(user.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _templates = list;
      _loading = false;
    });
  }

  Future<void> _addTemplate() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final navigator = Navigator.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Новый список'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(labelText: 'Название'),
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
    final t = await insertTemplate(userId: user.id, name: name);
    if (!mounted || t == null) return;
    await _load();
    await navigator.push(
      MaterialPageRoute(
        builder: (ctx) => TemplateEditScreen(templateId: t.id, name: t.name),
      ),
    );
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.trim().isEmpty
        ? _templates
        : _templates
              .where(
                (t) =>
                    t.name.toLowerCase().contains(_query.trim().toLowerCase()),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Шаблоны блюд'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.search),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _templates.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('У вас ещё нет шаблонов'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _addTemplate,
                        icon: const Icon(Icons.add),
                        label: const Text('Создать шаблон'),
                      ),
                    ],
                  ),
                ),
              )
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
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Шаблоны блюд',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Быстрый доступ к частым блюдам',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.search),
                                        hintText: 'Поиск шаблонов...',
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
                              Text(
                                'ВСЕ ШАБЛОНЫ',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Colors.grey[700],
                                      letterSpacing: 0.8,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              ...filtered.asMap().entries.map((entry) {
                                final index = entry.key;
                                final t = entry.value;
                                final color = _stripeColorForIndex(index);
                                return _TemplateCard(
                                  record: t,
                                  stripeColor: color,
                                  onTap: () {
                                    Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (ctx) =>
                                                TemplateEditScreen(
                                                  templateId: t.id,
                                                  name: t.name,
                                                ),
                                          ),
                                        )
                                        .then((_) {
                                          _load();
                                        });
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: _templates.isEmpty
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
                    onPressed: _addTemplate,
                    icon: const Icon(Icons.add),
                    label: const Text('Создать шаблон'),
                  ),
                ),
              ),
            ),
    );
  }
}

Color _stripeColorForIndex(int index) {
  const colors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
  ];
  return colors[index % colors.length];
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.record,
    required this.stripeColor,
    required this.onTap,
  });

  final DishTemplateRecord record;
  final Color stripeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: stripeColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Шаблон блюда',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
