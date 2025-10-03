-- Supabase debug va tekshirish
-- Bu kodlarni SQL Editor'da ishga tushiring

-- 1. Farms jadvalini tekshirish
SELECT * FROM public.farms LIMIT 5;

-- 2. RLS holatini tekshirish
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'farms';

-- 3. RLS siyosatlarini tekshirish
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'farms';

-- 4. Auth foydalanuvchilarini tekshirish
SELECT id, email, created_at 
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 5. Farms jadvali strukturasini tekshirish
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'farms' 
AND table_schema = 'public';

-- 6. Test uchun farms jadvaliga ma'lumot qo'shish (faqat test uchun)
-- INSERT INTO public.farms (owner_id, name, description) 
-- VALUES (auth.uid(), 'Test Farm', 'Test description');

-- 7. RLS'ni vaqtincha o'chirish (faqat test uchun)
-- ALTER TABLE public.farms DISABLE ROW LEVEL SECURITY;
