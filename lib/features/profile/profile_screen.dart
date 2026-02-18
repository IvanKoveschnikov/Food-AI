import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_ai/core/constants/app_strings.dart';
import 'package:food_ai/features/auth/auth_provider.dart';
import 'package:food_ai/features/profile/templates_screen.dart';
import 'package:food_ai/features/profile/profile_products_screen.dart';
import 'package:food_ai/features/profile/global_products_screen.dart';
import 'package:food_ai/services/auth_service.dart';
import 'package:food_ai/services/profile_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          profileAsync.when(
            data: (profile) {
              final displayName = profile?.displayName?.trim();
              final title = displayName != null && displayName.isNotEmpty
                  ? displayName
                  : (user?.email ?? 'Вход не выполнен');
              final initial = title.isNotEmpty ? title.substring(0, 1).toUpperCase() : '?';
              return ListTile(
                leading: CircleAvatar(
                  child: Text(initial),
                ),
                title: Text(title),
                subtitle: Text(user != null ? (user.email ?? '') : 'Войдите для синхронизации'),
                trailing: user != null
                    ? IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditNameDialog(context, ref, profile?.displayName ?? ''),
                      )
                    : null,
              );
            },
            loading: () => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user?.email ?? 'Вход не выполнен'),
              subtitle: const Text('Загрузка...'),
            ),
            error: (_, __) => ListTile(
              leading: CircleAvatar(
                child: user != null ? Text((user.email?.substring(0, 1).toUpperCase() ?? '?')) : const Icon(Icons.person),
              ),
              title: Text(user?.email ?? 'Вход не выполнен'),
              subtitle: Text(user != null ? user.email ?? '' : 'Войдите для синхронизации'),
              trailing: user != null
                  ? IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditNameDialog(context, ref, ''),
                    )
                  : null,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text(AppStrings.myDishes),
            subtitle: const Text('Готовые списки блюд'),
            onTap: () {
              if (user != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const TemplatesScreen(),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Войдите в аккаунт')));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text(AppStrings.mainProductList),
            subtitle: const Text('Справочник продуктов'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const GlobalProductsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_basket),
            title: const Text(AppStrings.myProducts),
            subtitle: const Text('Свои продукты'),
            onTap: () {
              if (user != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const ProfileProductsScreen(),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Войдите в аккаунт')));
              }
            },
          ),
          const Divider(),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(AppStrings.signOut),
              onTap: () async {
                await signOut();
                if (context.mounted) {
                  ref.invalidate(currentUserProvider);
                }
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text(AppStrings.signIn),
              onTap: () => context.push('/login'),
            ),
        ],
      ),
    );
  }

  static void _showEditNameDialog(BuildContext context, WidgetRef ref, String initial) {
    final controller = TextEditingController(text: initial);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.displayName),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Как к вам обращаться'),
          autofocus: true,
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user == null) return;
              await updateProfile(user.id, displayName: controller.text.trim());
              ref.invalidate(currentProfileProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}
