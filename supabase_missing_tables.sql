-- Missing Supabase Tables for Ferma App
-- Run this script in your Supabase SQL editor to create missing tables

-- Create egg_productions table
CREATE TABLE IF NOT EXISTS public.egg_productions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    farm_id UUID NOT NULL,
    production_date DATE NOT NULL,
    tray_count INTEGER NOT NULL DEFAULT 0,
    broken_count INTEGER DEFAULT 0,
    large_count INTEGER DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create chickens table 
CREATE TABLE IF NOT EXISTS public.chickens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    farm_id UUID NOT NULL,
    breed VARCHAR(100),
    total_count INTEGER NOT NULL DEFAULT 0,
    current_count INTEGER NOT NULL DEFAULT 0,
    deaths_count INTEGER DEFAULT 0,
    purchased_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create chicken_deaths table
CREATE TABLE IF NOT EXISTS public.chicken_deaths (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    farm_id UUID NOT NULL,
    chicken_id UUID,
    death_count INTEGER NOT NULL DEFAULT 1,
    death_date DATE NOT NULL,
    cause TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create egg_sales table
CREATE TABLE IF NOT EXISTS public.egg_sales (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    farm_id UUID NOT NULL,
    customer_id UUID,
    tray_count INTEGER NOT NULL,
    price_per_tray DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    sale_date DATE NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'pending', -- pending, partial, paid
    paid_amount DECIMAL(10,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create inventory_items table (if needed)
CREATE TABLE IF NOT EXISTS public.inventory_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    farm_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    unit VARCHAR(50),
    current_stock DECIMAL(10,2) DEFAULT 0,
    minimum_stock DECIMAL(10,2) DEFAULT 0,
    cost_per_unit DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create inventory_transactions table (if needed)
CREATE TABLE IF NOT EXISTS public.inventory_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    farm_id UUID NOT NULL,
    inventory_item_id UUID NOT NULL,
    transaction_type VARCHAR(20) NOT NULL, -- 'purchase', 'consumption', 'adjustment'
    quantity DECIMAL(10,2) NOT NULL,
    unit_cost DECIMAL(10,2),
    total_cost DECIMAL(10,2),
    transaction_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Add foreign key constraints
ALTER TABLE public.egg_productions 
ADD CONSTRAINT fk_egg_productions_farm 
FOREIGN KEY (farm_id) REFERENCES public.farms(id) ON DELETE CASCADE;

ALTER TABLE public.chickens 
ADD CONSTRAINT fk_chickens_farm 
FOREIGN KEY (farm_id) REFERENCES public.farms(id) ON DELETE CASCADE;

ALTER TABLE public.chicken_deaths 
ADD CONSTRAINT fk_chicken_deaths_farm 
FOREIGN KEY (farm_id) REFERENCES public.farms(id) ON DELETE CASCADE;

ALTER TABLE public.chicken_deaths 
ADD CONSTRAINT fk_chicken_deaths_chicken 
FOREIGN KEY (chicken_id) REFERENCES public.chickens(id) ON DELETE SET NULL;

ALTER TABLE public.egg_sales 
ADD CONSTRAINT fk_egg_sales_farm 
FOREIGN KEY (farm_id) REFERENCES public.farms(id) ON DELETE CASCADE;

ALTER TABLE public.egg_sales 
ADD CONSTRAINT fk_egg_sales_customer 
FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE SET NULL;

ALTER TABLE public.inventory_items 
ADD CONSTRAINT fk_inventory_items_farm 
FOREIGN KEY (farm_id) REFERENCES public.farms(id) ON DELETE CASCADE;

ALTER TABLE public.inventory_transactions 
ADD CONSTRAINT fk_inventory_transactions_farm 
FOREIGN KEY (farm_id) REFERENCES public.farms(id) ON DELETE CASCADE;

ALTER TABLE public.inventory_transactions 
ADD CONSTRAINT fk_inventory_transactions_item 
FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id) ON DELETE CASCADE;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_egg_productions_farm_date ON public.egg_productions(farm_id, production_date);
CREATE INDEX IF NOT EXISTS idx_chickens_farm ON public.chickens(farm_id);
CREATE INDEX IF NOT EXISTS idx_chicken_deaths_farm_date ON public.chicken_deaths(farm_id, death_date);
CREATE INDEX IF NOT EXISTS idx_egg_sales_farm_date ON public.egg_sales(farm_id, sale_date);
CREATE INDEX IF NOT EXISTS idx_inventory_items_farm ON public.inventory_items(farm_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_farm_date ON public.inventory_transactions(farm_id, transaction_date);

-- Enable RLS (Row Level Security) 
ALTER TABLE public.egg_productions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chickens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicken_deaths ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.egg_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (users can only access their farm's data)
CREATE POLICY "Users can view their farm's egg productions" ON public.egg_productions
    FOR SELECT USING (farm_id IN (
        SELECT id FROM public.farms WHERE owner_id = auth.uid()
    ));

CREATE POLICY "Users can insert their farm's egg productions" ON public.egg_productions
    FOR INSERT WITH CHECK (farm_id IN (
        SELECT id FROM public.farms WHERE owner_id = auth.uid()
    ));

CREATE POLICY "Users can update their farm's egg productions" ON public.egg_productions
    FOR UPDATE USING (farm_id IN (
        SELECT id FROM public.farms WHERE owner_id = auth.uid()
    ));

CREATE POLICY "Users can delete their farm's egg productions" ON public.egg_productions
    FOR DELETE USING (farm_id IN (
        SELECT id FROM public.farms WHERE owner_id = auth.uid()
    ));

-- Similar policies for other tables
CREATE POLICY "Users can manage their farm's chickens" ON public.chickens
    FOR ALL USING (farm_id IN (
        SELECT id FROM public.farms WHERE owner_id = auth.uid()
    ));

CREATE POLICY "Users can manage their farm's chicken deaths" ON public.chicken_deaths
    FOR ALL USING (farm_id IN (
        SELECT id FROM public.farms WHERE owner_id = auth.uid()
    ));

CREATE POLICY "Users can manage their farm's egg sales" ON public.egg_sales
    FOR ALL USING (farm_id IN (
        SELECT id FROM public.farms WHERE owner_id = auth.uid()
    ));

CREATE POLICY "Users can manage their farm's inventory items" ON public.inventory_items
    FOR ALL USING (farm_id IN (
        SELECT id FROM public.farms WHERE owner_id = auth.uid()
    ));

CREATE POLICY "Users can manage their farm's inventory transactions" ON public.inventory_transactions
    FOR ALL USING (farm_id IN (
        SELECT id FROM public.farms WHERE owner_id = auth.uid()
    ));

-- Enable realtime for live updates
ALTER PUBLICATION supabase_realtime ADD TABLE public.egg_productions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chickens;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chicken_deaths;
ALTER PUBLICATION supabase_realtime ADD TABLE public.egg_sales;
ALTER PUBLICATION supabase_realtime ADD TABLE public.inventory_items;
ALTER PUBLICATION supabase_realtime ADD TABLE public.inventory_transactions;

COMMIT;