-- Optional: run after Step B, and again after Step C, to confirm the data is there.
select 'farmer' t, count(*) from public.farmer union all select 'farm', count(*) from public.farm
union all select 'crop', count(*) from public.crop union all select 'planting', count(*) from public.planting
union all select 'harvest', count(*) from public.harvest;
-- Expected: farmer 15, farm 15, crop 10, planting 30, harvest 20
