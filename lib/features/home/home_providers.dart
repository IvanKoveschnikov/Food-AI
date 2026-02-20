import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_ai/features/auth/auth_provider.dart';
import 'package:food_ai/services/dishes_service.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Текущая дата (для подсветки «сегодня» в календаре), автоматически обновляется.
final todayProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  );
});

/// Текущий месяц календаря (для загрузки отметок). Храним первый день месяца.
final calendarFocusedMonthProvider = StateProvider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, 1);
});

final dishesForSelectedDateProvider = FutureProvider<List<DishRecord>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final date = ref.watch(selectedDateProvider);
  if (user == null) return [];
  final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  return getDishesForDate(user.id, dateStr);
});

/// Даты в отображаемом месяце, на которые есть блюда (для точек в календаре).
final dishDatesInFocusedMonthProvider = FutureProvider<Set<DateTime>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final focused = ref.watch(calendarFocusedMonthProvider);
  if (user == null) return {};
  return getDishDatesInMonth(user.id, focused.year, focused.month);
});
