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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final list = await getTemplatesForUser(user.id);
    if (mounted) setState(() {
      _templates = list;
      _loading = false;
    });
  }

  Future<void> _addTemplate() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
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
    final t = await insertTemplate(userId: user.id, name: name);
    if (t != null && mounted) {
      await _load();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => TemplateEditScreen(templateId: t.id, name: t.name),
        ),
      ).then((_) => _load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myDishes),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Нет готовых списков'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _addTemplate,
                        icon: const Icon(Icons.add),
                        label: const Text('Создать список'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _templates.length,
                    itemBuilder: (context, i) {
                      final t = _templates[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(t.name),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => TemplateEditScreen(templateId: t.id, name: t.name),
                              ),
                            ).then((_) => _load());
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _templates.isEmpty ? null : FloatingActionButton(
        onPressed: _addTemplate,
        child: const Icon(Icons.add),
      ),
    );
  }
}
