-- Bucket для фото блюд (создание через Dashboard или API)
-- Политика: пользователь может загружать только в папку своего user_id
INSERT INTO storage.buckets (id, name, public)
VALUES ('dish-images', 'dish-images', false)
ON CONFLICT (id) DO NOTHING;

-- Чтение: только свои файлы (path начинается с user_id)
CREATE POLICY "dish_images_read_own"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'dish-images'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Загрузка: только в свою папку
CREATE POLICY "dish_images_insert_own"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'dish-images'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Обновление/удаление: только свои
CREATE POLICY "dish_images_update_own"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'dish-images'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "dish_images_delete_own"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'dish-images'
  AND (storage.foldername(name))[1] = auth.uid()::text
);
