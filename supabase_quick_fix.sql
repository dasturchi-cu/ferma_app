-- Quick fix for immediate Supabase sync issues
-- Run this in your Supabase SQL editor

-- Add missing address column to farms table
ALTER TABLE public.farms ADD COLUMN IF NOT EXISTS address TEXT;

-- Update activity_logs RLS policy to be more permissive (temporary fix)
DROP POLICY IF EXISTS "Users can view activity logs" ON public.activity_logs;
DROP POLICY IF EXISTS "Users can insert activity logs" ON public.activity_logs;
DROP POLICY IF EXISTS "Users can update activity logs" ON public.activity_logs;
DROP POLICY IF EXISTS "Users can delete activity logs" ON public.activity_logs;

-- Create more permissive policies for activity_logs
CREATE POLICY "Allow all for activity_logs" ON public.activity_logs
    FOR ALL USING (true);

-- Or if you want some security, use this instead:
-- CREATE POLICY "Users can manage activity logs" ON public.activity_logs
--     FOR ALL USING (
--         farm_id IN (
--             SELECT id FROM public.farms WHERE owner_id = auth.uid()
--         )
--     );

-- Refresh the schema cache
NOTIFY pgrst, 'reload schema';