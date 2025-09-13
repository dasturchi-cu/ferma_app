-- FERMA APP UCHUN SODDA SUPABASE SCHEMA
-- Sizning modellaringizga mos keladi

-- 1. FARMS JADVALI (asosiy farm ma'lumotlari)
CREATE TABLE IF NOT EXISTS public.farms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL DEFAULT 'Mening Fermam',
    owner_id UUID NOT NULL,
    description TEXT,
    location TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. CUSTOMERS JADVALI
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    total_debt DECIMAL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. ORDERS JADVALI
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    tray_count INTEGER NOT NULL DEFAULT 0,
    price_per_tray DECIMAL NOT NULL DEFAULT 0,
    total_amount DECIMAL DEFAULT 0,
    delivery_date TIMESTAMP WITH TIME ZONE NOT NULL,
    is_paid BOOLEAN DEFAULT FALSE,
    paid_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. ACTIVITY_LOGS JADVALI  
CREATE TABLE IF NOT EXISTS public.activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    metadata JSONB,
    importance TEXT DEFAULT 'normal',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_farms_owner_id ON farms(owner_id);
CREATE INDEX IF NOT EXISTS idx_customers_farm_id ON customers(farm_id);
CREATE INDEX IF NOT EXISTS idx_orders_farm_id ON orders(farm_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_farm_id ON activity_logs(farm_id);

-- RLS ENABLE QILISH
ALTER TABLE farms ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- POLICIES
CREATE POLICY "Users can view own farms" ON farms FOR ALL USING (auth.uid() = owner_id);
CREATE POLICY "Users can manage customers" ON customers FOR ALL USING (farm_id IN (SELECT id FROM farms WHERE owner_id = auth.uid()));
CREATE POLICY "Users can manage orders" ON orders FOR ALL USING (farm_id IN (SELECT id FROM farms WHERE owner_id = auth.uid()));
CREATE POLICY "Users can manage activity logs" ON activity_logs FOR ALL USING (farm_id IN (SELECT id FROM farms WHERE owner_id = auth.uid()));

-- REALTIME
ALTER PUBLICATION supabase_realtime ADD TABLE farms;
ALTER PUBLICATION supabase_realtime ADD TABLE customers;
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE activity_logs;

SELECT 'Ferma App jadvallar yaratildi! 🎉' as message;