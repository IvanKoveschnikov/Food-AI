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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final maxWidth = width < 520 ? width - 32 : 520.0;
            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      profileAsync.when(
                        data: (profile) {
                          final displayName = profile?.displayName?.trim();
                          final title =
                              displayName != null && displayName.isNotEmpty
                              ? displayName
                              : (user?.email ?? 'Вход не выполнен');
                          final subtitle = user != null
                              ? (user.email ?? '')
                              : 'Войдите для синхронизации';
                          final initial = title.isNotEmpty
                              ? title.substring(0, 1).toUpperCase()
                              : '?';
                          return _ProfileHeader(
                            name: title,
                            email: subtitle,
                            initial: initial,
                            canEdit: user != null,
                            onEdit: () => _showEditNameDialog(
                              context,
                              ref,
                              profile?.displayName ?? '',
                            ),
                          );
                        },
                        loading: () => _ProfileHeader(
                          name: user?.email ?? 'Вход не выполнен',
                          email: 'Загрузка...',
                          initial:
                              user?.email != null && user!.email!.isNotEmpty
                              ? user.email!.substring(0, 1).toUpperCase()
                              : '?',
                          canEdit: false,
                          onEdit: () {},
                        ),
                        error: (error, stackTrace) {
                          final email = user?.email;
                          return _ProfileHeader(
                            name: email ?? 'Вход не выполнен',
                            email: email ?? 'Войдите для синхронизации',
                            initial: email != null && email.isNotEmpty
                                ? email.substring(0, 1).toUpperCase()
                                : '?',
                            canEdit: user != null,
                            onEdit: () => _showEditNameDialog(context, ref, ''),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'УПРАВЛЕНИЕ ДАННЫМИ',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[700],
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProfileSectionTile(
                        icon: Icons.shopping_basket_outlined,
                        title: AppStrings.myProducts,
                        subtitle: 'Управление вашим списком продуктов',
                        onTap: () {
                          if (user != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => const ProfileProductsScreen(),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Войдите в аккаунт'),
                              ),
                            );
                          }
                        },
                      ),
                      _ProfileSectionTile(
                        icon: Icons.public,
                        title: AppStrings.mainProductList,
                        subtitle: 'Глобальная база данных продуктов',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => const GlobalProductsScreen(),
                            ),
                          );
                        },
                      ),
                      _ProfileSectionTile(
                        icon: Icons.view_list_outlined,
                        title: AppStrings.myDishes,
                        subtitle: 'Быстрое добавление частых приёмов пищи',
                        onTap: () {
                          if (user != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => const TemplatesScreen(),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Войдите в аккаунт'),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'НАСТРОЙКИ АККАУНТА',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[700],
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProfileSectionTile(
                        icon: Icons.notifications_none,
                        title: 'Уведомления',
                        subtitle: 'Напоминания и отчёты ИИ',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Раздел в разработке'),
                            ),
                          );
                        },
                      ),
                      _ProfileSectionTile(
                        icon: Icons.lock_outline,
                        title: 'Безопасность',
                        subtitle: 'Приватность и доступ к данным',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Раздел в разработке'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      if (user != null)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFFEBEE),
                              foregroundColor: const Color(0xFFE91E63),
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () async {
                              await signOut();
                              if (context.mounted) {
                                ref.invalidate(currentUserProvider);
                              }
                            },
                            child: const Text('Выйти из аккаунта'),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () => context.push('/login'),
                            child: const Text(AppStrings.signIn),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Food AI v1.2.0',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Работает на базе нейронных сетей',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
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

  static void _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    String initial,
  ) {
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.initial,
    required this.canEdit,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String initial;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(initial, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.tune), onPressed: () {}),
                if (canEdit)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(
                  child: _ProfileStatCard(label: 'Блюда', value: '—'),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _ProfileStatCard(label: 'Шаблоны', value: '—'),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _ProfileStatCard(label: 'Продукты', value: '—'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionTile extends StatelessWidget {
  const _ProfileSectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
