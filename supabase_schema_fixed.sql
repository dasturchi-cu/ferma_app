-- Fixed Supabase Database Schema - Handles Existing Data
-- Run this in your Supabase SQL editor

-- 1. Create missing tables only
CREATE TABLE IF NOT EXISTS public.farms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT DEFAULT '',
    address TEXT DEFAULT '',
    chicken_count INTEGER DEFAULT 0,
    egg_production_rate DECIMAL(5,2) DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    address TEXT,
    total_debt DECIMAL(10,2) DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
    farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE,
    tray_count INTEGER NOT NULL DEFAULT 0,
    price_per_tray DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    delivery_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_paid BOOLEAN DEFAULT FALSE,
    paid_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- MAIN TABLE: Add missing columns to egg_productions if needed
CREATE TABLE IF NOT EXISTS public.egg_productions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE NOT NULL,
    record_type VARCHAR(50) NOT NULL DEFAULT 'production',
    tray_count INTEGER NOT NULL DEFAULT 0,
    price_per_tray DECIMAL(10,2) DEFAULT 0.0,
    note TEXT,
    production_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add missing columns to egg_productions table if they don't exist
DO $$ 
BEGIN 
    -- Add production_date column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='egg_productions' AND column_name='production_date') THEN
        ALTER TABLE public.egg_productions ADD COLUMN production_date TIMESTAMPTZ NOT NULL DEFAULT NOW();
    END IF;
    
    -- Add record_type column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='egg_productions' AND column_name='record_type') THEN
        ALTER TABLE public.egg_productions ADD COLUMN record_type VARCHAR(50) NOT NULL DEFAULT 'production';
    END IF;
    
    -- Add price_per_tray column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='egg_productions' AND column_name='price_per_tray') THEN
        ALTER TABLE public.egg_productions ADD COLUMN price_per_tray DECIMAL(10,2) DEFAULT 0.0;
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id UUID REFERENCES public.farms(id) ON DELETE CASCADE NOT NULL,
    type VARCHAR(100) NOT NULL DEFAULT 'other',
    title VARCHAR(255) NOT NULL,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    importance VARCHAR(50) DEFAULT 'normal',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Enable RLS for all tables
ALTER TABLE public.farms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.egg_productions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies and recreate them
-- Farms policies
DROP POLICY IF EXISTS "Users can view own farms" ON public.farms;
DROP POLICY IF EXISTS "Users can insert own farms" ON public.farms;
DROP POLICY IF EXISTS "Users can update own farms" ON public.farms;
DROP POLICY IF EXISTS "Users can delete own farms" ON public.farms;

CREATE POLICY "Users can view own farms" ON public.farms
    FOR SELECT USING (auth.uid() = owner_id);
CREATE POLICY "Users can insert own farms" ON public.farms
    FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Users can update own farms" ON public.farms
    FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Users can delete own farms" ON public.farms
    FOR DELETE USING (auth.uid() = owner_id);

-- Customers policies
DROP POLICY IF EXISTS "Users can view own customers" ON public.customers;
DROP POLICY IF EXISTS "Users can insert own customers" ON public.customers;
DROP POLICY IF EXISTS "Users can update own customers" ON public.customers;
DROP POLICY IF EXISTS "Users can delete own customers" ON public.customers;

CREATE POLICY "Users can view own customers" ON public.customers
    FOR SELECT USING (farm_id IN (SELECT id FROM public.farms WHERE owner_id = auth.uid()));
CREATE POLICY "Users can insert own customers" ON public.customers
    FOR INSERT WITH CHECK (farm_id IN (SELECT id FROM public.farms WHERE owner_id = auth.uid()));
CREATE POLICY "Users can update own customers" ON public.customers
    FOR UPDATE USING (farm_id IN (SELECT id FROM public.farms WHERE owner_id = auth.uid()));
CREATE POLICY "Users can delete own customers" ON public.customers
    FOR DELETE USING (farm_id IN (SELECT id FROM public.farms WHERE owner_id = auth.uid()));

-- Orders policies
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can insert own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can update own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can delete own orders" ON public.orders;

CREATE POLICY "Users can view own orders" ON public.orders
    FOR SELECT USING (farm_id IN (SELECT id FROM public.farms WHERE owner_id = auth.uid()));
CREATE POLICY "Users can insert own orders" ON public.orders
    FOR INSERT WITH CHECK (farm_id IN (SELECT id FROM public.farms WHERE owner_id = auth.uid()));
CREATE POLICY "Users can update own orders" ON public.orders
    FOR UPDATE USING (farm_id IN (SELECT id FROM public.farms WHERE owner_id = auth.uid()));
CREATE POLICY "Users can delete own orders" ON public.orders
    FOR DELETE USING (farm_id IN (SELECT id FROM public.farms WHERE owner_id = auth.uid()));

-- Egg productions policies
DROP POLICY IF EXISTS "Users can view own egg productions" ON public.egg_productions;
DROP POLICY IF EXISTS "Users can insert own egg productions" ON public.egg_productions;
DROP POLICY IF EXISTS "Users can update own egg productions" ON public.egg_productions;
DROP POLICY IF EXISTS "Users can delete own egg productions" ON public.egg_productions;

CREATE POLICY "Users can view own egg productions" ON public.egg_productions
    FOR SELECT USING (farm_id IN (SELECT id FROM public.farms WHERE owner_id = auth.uid()));
CREATE POLICY "Users can insert own egg productions" ON public.egg_productions
    FOR INSERT WITH CHECK (farm_id IN (SELECT id FROM public.farms WHERE owner_id = auth.uid()));
CREATE POLICY "Users can update own egg productions" ON public.egg_productions
    FOR UPDATE USING (farm_id IN (SELECT id FROM public.farms WHERE owner_id = auth.uid()));
CREATE POLICY "Users can delete own egg productions" ON public.egg_productions
    FOR DELETE USING (farm_id IN (SELECT id FROM public.farms WHERE owner_id = auth.uid()));

-- Activity logs policies
DROP POLICY IF EXISTS "Users can view own activity logs" ON public.activity_logs;
DROP POLICY IF EXISTS "Users can insert own activity logs" ON public.activity_logs;
DROP POLICY IF EXISTS "Users can update own activity logs" ON public.activity_logs;
DROP POLICY IF EXISTS "Users can delete own activity logs" ON public.activity_logs;

CREATE POLICY "Users can view own activity logs" ON public.activity_logs
    FOR SELECT USING (farm_id IN (SELECT id FROM public.farms WHERE owner_id = auth.uid()));
CREATE POLICY "Users can insert own activity logs" ON public.activity_logs
    FOR INSERT WITH CHECK (farm_id IN (SELECT id FROM public.farms WHERE owner_id = auth.uid()));
CREATE POLICY "Users can update own activity logs" ON public.activity_logs
    FOR UPDATE USING (farm_id IN (SELECT id FROM public.farms WHERE owner_id = auth.uid()));
CREATE POLICY "Users can delete own activity logs" ON public.activity_logs
    FOR DELETE USING (farm_id IN (SELECT id FROM public.farms WHERE owner_id = auth.uid()));

-- 4. Create indexes
CREATE INDEX IF NOT EXISTS idx_farms_owner_id ON public.farms(owner_id);
CREATE INDEX IF NOT EXISTS idx_customers_farm_id ON public.customers(farm_id);
CREATE INDEX IF NOT EXISTS idx_orders_farm_id ON public.orders(farm_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_egg_productions_farm_id ON public.egg_productions(farm_id);
CREATE INDEX IF NOT EXISTS idx_egg_productions_date ON public.egg_productions(production_date);
CREATE INDEX IF NOT EXISTS idx_activity_logs_farm_id ON public.activity_logs(farm_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON public.activity_logs(created_at);

-- 5. Enable Realtime (ignore errors if already added)
DO $$ 
BEGIN 
    ALTER PUBLICATION supabase_realtime ADD TABLE public.farms;
EXCEPTION 
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ 
BEGIN 
    ALTER PUBLICATION supabase_realtime ADD TABLE public.customers;
EXCEPTION 
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ 
BEGIN 
    ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
EXCEPTION 
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ 
BEGIN 
    ALTER PUBLICATION supabase_realtime ADD TABLE public.egg_productions;
EXCEPTION 
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ 
BEGIN 
    ALTER PUBLICATION supabase_realtime ADD TABLE public.activity_logs;
EXCEPTION 
    WHEN duplicate_object THEN NULL;
END $$;

-- 6. Create or replace triggers
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS handle_updated_at ON public.farms;
CREATE TRIGGER handle_updated_at
  BEFORE UPDATE ON public.farms
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS handle_updated_at ON public.customers;
CREATE TRIGGER handle_updated_at
  BEFORE UPDATE ON public.customers
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS handle_updated_at ON public.orders;
CREATE TRIGGER handle_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS handle_updated_at ON public.egg_productions;
CREATE TRIGGER handle_updated_at
  BEFORE UPDATE ON public.egg_productions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Final success message
SELECT 'Database schema updated successfully! All missing columns and policies are fixed.' as status;