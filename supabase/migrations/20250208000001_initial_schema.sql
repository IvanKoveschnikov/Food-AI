-- Профили пользователей (1:1 с auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Продукты: глобальный список и пользовательские
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  scope TEXT NOT NULL CHECK (scope IN ('global', 'user')),
  created_by UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_products_global_name ON public.products(name) WHERE scope = 'global';
CREATE UNIQUE INDEX idx_products_user_name ON public.products(created_by, name) WHERE scope = 'user';

CREATE INDEX IF NOT EXISTS idx_products_scope_created_by ON public.products(scope, created_by);

-- Блюда
CREATE TABLE IF NOT EXISTS public.dishes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  date DATE NOT NULL,
  image_url TEXT,
  description TEXT,
  ai_advice TEXT,
  confidence INTEGER DEFAULT 0,
  weight_grams INTEGER DEFAULT 100,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_dishes_user_date ON public.dishes(user_id, date);

-- Состав блюда
CREATE TABLE IF NOT EXISTS public.dish_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dish_id UUID NOT NULL REFERENCES public.dishes(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  is_user_added BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(dish_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_dish_products_dish ON public.dish_products(dish_id);

-- Шаблоны блюд (готовые списки)
CREATE TABLE IF NOT EXISTS public.dish_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.dish_template_products (
  template_id UUID NOT NULL REFERENCES public.dish_templates(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  PRIMARY KEY (template_id, product_id)
);

-- RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dishes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dish_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dish_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dish_template_products ENABLE ROW LEVEL SECURITY;

-- Профили: чтение/запись своих
CREATE POLICY "profiles_select_own" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_insert_own" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Продукты: чтение global + свои user; запись только свои user
CREATE POLICY "products_select" ON public.products FOR SELECT USING (
  scope = 'global' OR (scope = 'user' AND created_by = auth.uid())
);
CREATE POLICY "products_insert_user" ON public.products FOR INSERT WITH CHECK (
  scope = 'user' AND created_by = auth.uid()
);
CREATE POLICY "products_update_user" ON public.products FOR UPDATE USING (
  scope = 'user' AND created_by = auth.uid()
);
CREATE POLICY "products_delete_user" ON public.products FOR DELETE USING (
  scope = 'user' AND created_by = auth.uid()
);

-- Блюда: только свои
CREATE POLICY "dishes_all_own" ON public.dishes FOR ALL USING (user_id = auth.uid());

-- Состав блюда: через владельца блюда
CREATE POLICY "dish_products_select" ON public.dish_products FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.dishes d WHERE d.id = dish_id AND d.user_id = auth.uid())
);
CREATE POLICY "dish_products_insert" ON public.dish_products FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.dishes d WHERE d.id = dish_id AND d.user_id = auth.uid())
);
CREATE POLICY "dish_products_update" ON public.dish_products FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.dishes d WHERE d.id = dish_id AND d.user_id = auth.uid())
);
CREATE POLICY "dish_products_delete" ON public.dish_products FOR DELETE USING (
  EXISTS (SELECT 1 FROM public.dishes d WHERE d.id = dish_id AND d.user_id = auth.uid())
);

-- Шаблоны: только свои
CREATE POLICY "dish_templates_all_own" ON public.dish_templates FOR ALL USING (user_id = auth.uid());

-- Состав шаблонов: через владельца шаблона
CREATE POLICY "dish_template_products_select" ON public.dish_template_products FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.dish_templates t WHERE t.id = template_id AND t.user_id = auth.uid())
);
CREATE POLICY "dish_template_products_insert" ON public.dish_template_products FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.dish_templates t WHERE t.id = template_id AND t.user_id = auth.uid())
);
CREATE POLICY "dish_template_products_delete" ON public.dish_template_products FOR DELETE USING (
  EXISTS (SELECT 1 FROM public.dish_templates t WHERE t.id = template_id AND t.user_id = auth.uid())
);

-- Триггер создания профиля при регистрации
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Обновление updated_at для dishes
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS dishes_updated_at ON public.dishes;
CREATE TRIGGER dishes_updated_at
  BEFORE UPDATE ON public.dishes
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
