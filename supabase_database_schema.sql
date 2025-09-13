-- ==============================================
-- FERMA APP UCHUN TO'LIQ SUPABASE DATABASE SCHEMA
-- ==============================================

-- Enable RLS (Row Level Security)
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

-- 1. FARMS JADVALI
CREATE TABLE public.farms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL DEFAULT 'Mening Fermam',
    owner_id UUID NOT NULL,
    description TEXT,
    location TEXT,
    established_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    total_area DECIMAL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. CUSTOMERS JADVALI
CREATE TABLE public.customers (
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
CREATE TABLE public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    tray_count INTEGER NOT NULL DEFAULT 0,
    price_per_tray DECIMAL NOT NULL DEFAULT 0,
    total_amount DECIMAL GENERATED ALWAYS AS (tray_count * price_per_tray) STORED,
    delivery_date TIMESTAMP WITH TIME ZONE NOT NULL,
    is_paid BOOLEAN DEFAULT FALSE,
    paid_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. CHICKENS JADVALI
CREATE TABLE public.chickens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    total_count INTEGER DEFAULT 0,
    current_count INTEGER DEFAULT 0,
    breed TEXT,
    age_weeks INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. CHICKEN_DEATHS JADVALI
CREATE TABLE public.chicken_deaths (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chicken_id UUID NOT NULL REFERENCES chickens(id) ON DELETE CASCADE,
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    death_count INTEGER NOT NULL DEFAULT 1,
    death_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    cause TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. EGGS JADVALI
CREATE TABLE public.eggs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. EGG_PRODUCTION JADVALI
CREATE TABLE public.egg_production (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    egg_id UUID NOT NULL REFERENCES eggs(id) ON DELETE CASCADE,
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    tray_count INTEGER NOT NULL DEFAULT 0,
    production_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. EGG_SALES JADVALI
CREATE TABLE public.egg_sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    egg_id UUID NOT NULL REFERENCES eggs(id) ON DELETE CASCADE,
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    tray_count INTEGER NOT NULL DEFAULT 0,
    price_per_tray DECIMAL NOT NULL DEFAULT 0,
    total_amount DECIMAL GENERATED ALWAYS AS (tray_count * price_per_tray) STORED,
    sale_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. BROKEN_EGGS JADVALI
CREATE TABLE public.broken_eggs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    egg_id UUID NOT NULL REFERENCES eggs(id) ON DELETE CASCADE,
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    tray_count INTEGER NOT NULL DEFAULT 0,
    broken_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    cause TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. LARGE_EGGS JADVALI
CREATE TABLE public.large_eggs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    egg_id UUID NOT NULL REFERENCES eggs(id) ON DELETE CASCADE,
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    tray_count INTEGER NOT NULL DEFAULT 0,
    separated_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. INVENTORY_ITEMS JADVALI
CREATE TABLE public.inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('feed', 'medicine', 'equipment', 'supplies', 'other')),
    description TEXT,
    quantity DECIMAL DEFAULT 0,
    unit TEXT NOT NULL DEFAULT 'pcs',
    unit_price DECIMAL,
    min_stock_level DECIMAL,
    max_stock_level DECIMAL,
    supplier TEXT,
    storage_location TEXT,
    expiry_date TIMESTAMP WITH TIME ZONE,
    batch_number TEXT,
    notes TEXT,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. INVENTORY_TRANSACTIONS JADVALI
CREATE TABLE public.inventory_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('in', 'out', 'adjust', 'transfer')),
    quantity DECIMAL NOT NULL,
    unit TEXT NOT NULL,
    unit_price DECIMAL,
    total_amount DECIMAL,
    reference_id TEXT,
    reference_type TEXT,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    recorded_by TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 13. ACTIVITY_LOGS JADVALI
CREATE TABLE public.activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('egg_production', 'egg_sale', 'chicken_death', 'inventory', 'customer', 'financial', 'system', 'other')),
    title TEXT NOT NULL,
    description TEXT,
    metadata JSONB,
    importance TEXT DEFAULT 'normal' CHECK (importance IN ('low', 'normal', 'high', 'critical')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================
-- INDEXES - Tezlik uchun
-- ==============================================

CREATE INDEX idx_farms_owner_id ON farms(owner_id);
CREATE INDEX idx_customers_farm_id ON customers(farm_id);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_farm_id ON orders(farm_id);
CREATE INDEX idx_orders_delivery_date ON orders(delivery_date);
CREATE INDEX idx_chickens_farm_id ON chickens(farm_id);
CREATE INDEX idx_chicken_deaths_farm_id ON chicken_deaths(farm_id);
CREATE INDEX idx_egg_production_farm_id ON egg_production(farm_id);
CREATE INDEX idx_egg_sales_farm_id ON egg_sales(farm_id);
CREATE INDEX idx_inventory_items_farm_id ON inventory_items(farm_id);
CREATE INDEX idx_inventory_transactions_farm_id ON inventory_transactions(farm_id);
CREATE INDEX idx_activity_logs_farm_id ON activity_logs(farm_id);
CREATE INDEX idx_activity_logs_created_at ON activity_logs(created_at);

-- ==============================================
-- ROW LEVEL SECURITY (RLS) - Xavfsizlik uchun
-- ==============================================

ALTER TABLE farms ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE chickens ENABLE ROW LEVEL SECURITY;
ALTER TABLE chicken_deaths ENABLE ROW LEVEL SECURITY;
ALTER TABLE eggs ENABLE ROW LEVEL SECURITY;
ALTER TABLE egg_production ENABLE ROW LEVEL SECURITY;
ALTER TABLE egg_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE broken_eggs ENABLE ROW LEVEL SECURITY;
ALTER TABLE large_eggs ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- ==============================================
-- POLICIES - Faqat o'z ma'lumotlariga kirish
-- ==============================================

-- FARMS policies
CREATE POLICY "Users can view their own farms" ON farms
    FOR SELECT USING (auth.uid() = owner_id);
CREATE POLICY "Users can insert their own farms" ON farms
    FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Users can update their own farms" ON farms
    FOR UPDATE USING (auth.uid() = owner_id);

-- CUSTOMERS policies
CREATE POLICY "Users can manage customers for their farms" ON customers
    FOR ALL USING (farm_id IN (SELECT id FROM farms WHERE owner_id = auth.uid()));

-- ORDERS policies
CREATE POLICY "Users can manage orders for their farms" ON orders
    FOR ALL USING (farm_id IN (SELECT id FROM farms WHERE owner_id = auth.uid()));

-- CHICKENS policies
CREATE POLICY "Users can manage chickens for their farms" ON chickens
    FOR ALL USING (farm_id IN (SELECT id FROM farms WHERE owner_id = auth.uid()));

-- CHICKEN_DEATHS policies
CREATE POLICY "Users can manage chicken deaths for their farms" ON chicken_deaths
    FOR ALL USING (farm_id IN (SELECT id FROM farms WHERE owner_id = auth.uid()));

-- EGGS policies
CREATE POLICY "Users can manage eggs for their farms" ON eggs
    FOR ALL USING (farm_id IN (SELECT id FROM farms WHERE owner_id = auth.uid()));

-- EGG_PRODUCTION policies
CREATE POLICY "Users can manage egg production for their farms" ON egg_production
    FOR ALL USING (farm_id IN (SELECT id FROM farms WHERE owner_id = auth.uid()));

-- EGG_SALES policies
CREATE POLICY "Users can manage egg sales for their farms" ON egg_sales
    FOR ALL USING (farm_id IN (SELECT id FROM farms WHERE owner_id = auth.uid()));

-- BROKEN_EGGS policies
CREATE POLICY "Users can manage broken eggs for their farms" ON broken_eggs
    FOR ALL USING (farm_id IN (SELECT id FROM farms WHERE owner_id = auth.uid()));

-- LARGE_EGGS policies
CREATE POLICY "Users can manage large eggs for their farms" ON large_eggs
    FOR ALL USING (farm_id IN (SELECT id FROM farms WHERE owner_id = auth.uid()));

-- INVENTORY policies
CREATE POLICY "Users can manage inventory for their farms" ON inventory_items
    FOR ALL USING (farm_id IN (SELECT id FROM farms WHERE owner_id = auth.uid()));

CREATE POLICY "Users can manage inventory transactions for their farms" ON inventory_transactions
    FOR ALL USING (farm_id IN (SELECT id FROM farms WHERE owner_id = auth.uid()));

-- ACTIVITY_LOGS policies
CREATE POLICY "Users can view activity logs for their farms" ON activity_logs
    FOR SELECT USING (farm_id IN (SELECT id FROM farms WHERE owner_id = auth.uid()));
CREATE POLICY "Users can insert activity logs for their farms" ON activity_logs
    FOR INSERT WITH CHECK (farm_id IN (SELECT id FROM farms WHERE owner_id = auth.uid()));

-- ==============================================
-- REALTIME UCHUN PUBLICATION
-- ==============================================

ALTER PUBLICATION supabase_realtime ADD TABLE farms;
ALTER PUBLICATION supabase_realtime ADD TABLE customers;
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE chickens;
ALTER PUBLICATION supabase_realtime ADD TABLE egg_production;
ALTER PUBLICATION supabase_realtime ADD TABLE egg_sales;
ALTER PUBLICATION supabase_realtime ADD TABLE inventory_items;
ALTER PUBLICATION supabase_realtime ADD TABLE activity_logs;

-- ==============================================
-- FUNCTIONS - Foydali funksiyalar
-- ==============================================

-- Farm uchun umumiy statistika
CREATE OR REPLACE FUNCTION get_farm_stats(farm_uuid UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_customers', (SELECT COUNT(*) FROM customers WHERE farm_id = farm_uuid),
        'active_customers', (SELECT COUNT(DISTINCT customer_id) FROM orders WHERE farm_id = farm_uuid AND delivery_date >= NOW() - INTERVAL '30 days'),
        'total_debt', (SELECT COALESCE(SUM(total_debt), 0) FROM customers WHERE farm_id = farm_uuid),
        'current_chickens', (SELECT COALESCE(current_count, 0) FROM chickens WHERE farm_id = farm_uuid LIMIT 1),
        'today_egg_production', (SELECT COALESCE(SUM(tray_count), 0) FROM egg_production WHERE farm_id = farm_uuid AND production_date::date = CURRENT_DATE),
        'this_month_sales', (SELECT COALESCE(SUM(total_amount), 0) FROM egg_sales WHERE farm_id = farm_uuid AND sale_date >= date_trunc('month', CURRENT_DATE))
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Low stock itemlarni aniqlash
CREATE OR REPLACE FUNCTION get_low_stock_items(farm_uuid UUID)
RETURNS TABLE(
    id UUID,
    name TEXT,
    category TEXT,
    quantity DECIMAL,
    min_stock_level DECIMAL,
    unit TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT i.id, i.name, i.category, i.quantity, i.min_stock_level, i.unit
    FROM inventory_items i
    WHERE i.farm_id = farm_uuid 
    AND i.min_stock_level IS NOT NULL 
    AND i.quantity <= i.min_stock_level;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- SAMPLE DATA INSERT (Test uchun)
-- Bu qismni faqat test uchun ishlatishingiz mumkin

/*
-- Sample farm yaratish (faqat test uchun)
INSERT INTO farms (id, owner_id, name) VALUES 
('sample-farm-id', 'sample-user-id', 'Test Ferma');

-- Sample customer
INSERT INTO customers (farm_id, name, phone, address) VALUES
('sample-farm-id', 'Ahmad Karimov', '+998901234567', 'Toshkent');

-- Sample chicken
INSERT INTO chickens (farm_id, total_count, current_count) VALUES
('sample-farm-id', 1000, 980);

-- Sample egg
INSERT INTO eggs (farm_id) VALUES
('sample-farm-id');
*/

-- Schema yaratish tugallandi!
SELECT 'Ferma App ma''lumotlar bazasi muvaffaqiyatli yaratildi! 🎉' as message;