-- Начальный набор продуктов основного списка (опционально).
INSERT INTO public.products (name, scope)
SELECT v.name, 'global'::text
FROM (VALUES
  ('Картофель'),
  ('Морковь'),
  ('Лук'),
  ('Мясо'),
  ('Курица'),
  ('Рис'),
  ('Соль'),
  ('Сахар'),
  ('Молоко'),
  ('Яйца'),
  ('Мука'),
  ('Масло растительное'),
  ('Помидоры'),
  ('Огурцы'),
  ('Сыр')
) AS v(name)
WHERE NOT EXISTS (SELECT 1 FROM public.products p WHERE p.name = v.name AND p.scope = 'global');
