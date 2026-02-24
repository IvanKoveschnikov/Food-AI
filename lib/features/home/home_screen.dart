import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:food_ai/core/constants/app_strings.dart';
import 'package:food_ai/features/home/home_providers.dart';
import 'package:food_ai/services/dishes_service.dart';
import 'package:food_ai/services/storage_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static String _dateToStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final focusedMonth = ref.watch(calendarFocusedMonthProvider);
    final dishesAsync = ref.watch(dishesForSelectedDateProvider);
    final markedDatesAsync = ref.watch(dishDatesInFocusedMonthProvider);
    final todayAsync = ref.watch(todayProvider);
    final today = todayAsync.when(
      data: (d) => d,
      loading: () => DateTime.now(),
      error: (_, __) => DateTime.now(),
    );
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dishesForSelectedDateProvider);
          ref.invalidate(dishDatesInFocusedMonthProvider);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final maxWidth = width < 520 ? width - 32 : 520.0;
            return Align(
              alignment: Alignment.topCenter,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TableCalendar(
                          firstDay: DateTime(2020, 1, 1),
                          lastDay: DateTime(2030, 12, 31),
                          focusedDay: focusedMonth,
                          currentDay: DateTime(
                            today.year,
                            today.month,
                            today.day,
                          ),
                          selectedDayPredicate: (d) =>
                              isSameDay(d, selectedDate),
                          onDaySelected: (day, _) =>
                              ref.read(selectedDateProvider.notifier).state =
                                  day,
                          onPageChanged: (focused) =>
                              ref
                                      .read(
                                        calendarFocusedMonthProvider.notifier,
                                      )
                                      .state =
                                  focused,
                          locale: locale.languageCode,
                          calendarFormat: CalendarFormat.month,
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                          ),
                          calendarStyle: CalendarStyle(
                            selectedDecoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                            selectedTextStyle: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                            todayDecoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                          ),
                          calendarBuilders: CalendarBuilders(
                            selectedBuilder: (context, date, _) {
                              final isToday =
                                  date.year == today.year &&
                                  date.month == today.month &&
                                  date.day == today.day;
                              if (!isToday) return null;
                              return Center(
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${date.day}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            },
                            markerBuilder: (context, date, events) {
                              return markedDatesAsync.when(
                                data: (marked) {
                                  final hasDish = marked.any(
                                    (d) =>
                                        d.year == date.year &&
                                        d.month == date.month &&
                                        d.day == date.day,
                                  );
                                  if (!hasDish) return null;
                                  return Positioned(
                                    bottom: 4,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  );
                                },
                                loading: () => null,
                                error: (error, stackTrace) => null,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                  ),
                                  onPressed: () => context.go('/camera'),
                                  icon: const Icon(Icons.bolt, size: 18),
                                  label: const Text(
                                    'Анализ AI',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                  ),
                                  onPressed: () => context.push(
                                    '/add-no-photo?date=${_dateToStr(selectedDate)}',
                                  ),
                                  icon: const Icon(Icons.edit_note, size: 18),
                                  label: const Text(
                                    'Добавить',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '${AppStrings.dishesOnDate} — ${DateFormat.yMMMd(locale.toString()).format(selectedDate)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        dishesAsync.when(
                          data: (dishes) {
                            if (dishes.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Center(
                                  child: Text(
                                    AppStrings.noDishes,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                ),
                              );
                            }
                            return Column(
                              children: dishes
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => _DishCard(dish: entry.value)
                                        .animate()
                                        .fadeIn(
                                          delay: Duration(
                                            milliseconds: 50 * entry.key,
                                          ),
                                        )
                                        .slideY(
                                          begin: 0.2,
                                          end: 0,
                                          curve: Curves.easeOutQuad,
                                        ),
                                  )
                                  .toList(),
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'Ошибка: $e',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DishCard extends ConsumerWidget {
  const _DishCard({required this.dish});

  final DishRecord dish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/dish/${dish.id}'),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: dish.imageUrl != null && dish.imageUrl!.isNotEmpty
              ? FutureBuilder<String?>(
                  future: getDishImageSignedUrl(dish.imageUrl!),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return _shimmerPlaceholder();
                    }
                    if (snap.hasData && snap.data != null) {
                      return Hero(
                        tag: 'dish_image_${dish.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            snap.data!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _placeholderIcon(),
                          ),
                        ),
                      );
                    }
                    return _placeholderIcon();
                  },
                )
              : _placeholderIcon(),
          title: Text(dish.name),
          subtitle: Text(dish.date),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            color: Colors.grey,
            onPressed: () async {
              try {
                await deleteDish(dish.id);
                if (context.mounted) {
                  // Принудительно обновляем список и календарь
                  ref.invalidate(dishesForSelectedDateProvider);
                  ref.invalidate(dishDatesInFocusedMonthProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка удаления: $e')),
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.restaurant, size: 28, color: Colors.grey),
    );
  }

  Widget _shimmerPlaceholder() {
    return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1200),
          color: Colors.white.withOpacity(0.5),
        );
  }
}
