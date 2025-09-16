-- Clean duplicate and invalid records from Supabase database
-- Run this in your Supabase SQL editor to fix data issues

-- 1. Delete invalid egg production records (tray_count <= 0 or NULL)
DELETE FROM public.egg_productions 
WHERE tray_count IS NULL OR tray_count <= 0;

-- 2. Delete records with invalid farm_id
DELETE FROM public.egg_productions 
WHERE farm_id IS NULL 
   OR farm_id NOT IN (SELECT id FROM public.farms);

-- 3. Delete very old duplicates (keep only recent 100 records per farm)
WITH ranked_records AS (
  SELECT id,
         ROW_NUMBER() OVER (PARTITION BY farm_id ORDER BY created_at DESC) as rn
  FROM public.egg_productions
)
DELETE FROM public.egg_productions 
WHERE id IN (
  SELECT id FROM ranked_records WHERE rn > 100
);

-- 4. Remove exact duplicates (same farm_id, tray_count, record_type, production_date)
WITH duplicate_groups AS (
  SELECT farm_id, tray_count, record_type, production_date, 
         MIN(id) as keep_id,
         COUNT(*) as duplicate_count
  FROM public.egg_productions 
  GROUP BY farm_id, tray_count, record_type, production_date
  HAVING COUNT(*) > 1
),
duplicates_to_delete AS (
  SELECT ep.id
  FROM public.egg_productions ep
  JOIN duplicate_groups dg ON ep.farm_id = dg.farm_id 
                           AND ep.tray_count = dg.tray_count 
                           AND ep.record_type = dg.record_type 
                           AND ep.production_date = dg.production_date
  WHERE ep.id != dg.keep_id
)
DELETE FROM public.egg_productions 
WHERE id IN (SELECT id FROM duplicates_to_delete);

-- 5. Update NULL production_date to created_at
UPDATE public.egg_productions 
SET production_date = created_at 
WHERE production_date IS NULL;

-- 6. Update NULL record_type to 'production'
UPDATE public.egg_productions 
SET record_type = 'production' 
WHERE record_type IS NULL OR record_type = '';

-- 7. Show summary of cleaned data
SELECT 
  farm_id,
  record_type,
  COUNT(*) as record_count,
  SUM(tray_count) as total_trays,
  MIN(production_date) as earliest_date,
  MAX(production_date) as latest_date
FROM public.egg_productions 
GROUP BY farm_id, record_type
ORDER BY farm_id, record_type;

-- Success message
SELECT 'Database cleaned successfully! Duplicate and invalid records removed.' as status;