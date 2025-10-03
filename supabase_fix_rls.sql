-- Supabase RLS (Row Level Security) sozlamalari
-- Bu faylni Supabase SQL Editor'da ishga tushiring

-- 1. RLS'ni yoqish farms jadvali uchun
ALTER TABLE public.farms ENABLE ROW LEVEL SECURITY;

-- 2. Farms jadvali uchun RLS siyosatlari
-- Foydalanuvchi o'z fermasini ko'ra olishi va o'zgartirishi mumkin
CREATE POLICY "Users can view own farms" ON public.farms
    FOR SELECT USING (auth.uid() = owner_id);

CREATE POLICY "Users can insert own farms" ON public.farms
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own farms" ON public.farms
    FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own farms" ON public.farms
    FOR DELETE USING (auth.uid() = owner_id);

-- 3. Customers jadvali uchun RLS
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own customers" ON public.customers
    FOR SELECT USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can insert own customers" ON public.customers
    FOR INSERT WITH CHECK (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can update own customers" ON public.customers
    FOR UPDATE USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can delete own customers" ON public.customers
    FOR DELETE USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

-- 4. Orders jadvali uchun RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own orders" ON public.orders
    FOR SELECT USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can insert own orders" ON public.orders
    FOR INSERT WITH CHECK (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can update own orders" ON public.orders
    FOR UPDATE USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can delete own orders" ON public.orders
    FOR DELETE USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

-- 5. Egg productions jadvali uchun RLS
ALTER TABLE public.egg_productions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own egg productions" ON public.egg_productions
    FOR SELECT USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can insert own egg productions" ON public.egg_productions
    FOR INSERT WITH CHECK (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can update own egg productions" ON public.egg_productions
    FOR UPDATE USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can delete own egg productions" ON public.egg_productions
    FOR DELETE USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

-- 6. Activity logs jadvali uchun RLS
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own activity logs" ON public.activity_logs
    FOR SELECT USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can insert own activity logs" ON public.activity_logs
    FOR INSERT WITH CHECK (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can update own activity logs" ON public.activity_logs
    FOR UPDATE USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can delete own activity logs" ON public.activity_logs
    FOR DELETE USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

-- 7. Inventory items jadvali uchun RLS
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own inventory items" ON public.inventory_items
    FOR SELECT USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can insert own inventory items" ON public.inventory_items
    FOR INSERT WITH CHECK (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can update own inventory items" ON public.inventory_items
    FOR UPDATE USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can delete own inventory items" ON public.inventory_items
    FOR DELETE USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

-- 8. Inventory transactions jadvali uchun RLS
ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own inventory transactions" ON public.inventory_transactions
    FOR SELECT USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can insert own inventory transactions" ON public.inventory_transactions
    FOR INSERT WITH CHECK (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can update own inventory transactions" ON public.inventory_transactions
    FOR UPDATE USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

CREATE POLICY "Users can delete own inventory transactions" ON public.inventory_transactions
    FOR DELETE USING (auth.uid() = (SELECT owner_id FROM public.farms WHERE id = farm_id));

-- 9. Tekshirish uchun
SELECT 'RLS siyosatlari muvaffaqiyatli yaratildi!' as status;
