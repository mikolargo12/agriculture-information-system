-- STEP A: clears everything created by earlier versions. DELETES ALL DATA in these tables.
-- Your login accounts (Authentication > Users) are NOT deleted.
drop trigger if exists on_auth_user_created on auth.users;
drop table if exists public.harvest, public.planting, public.crop, public.farm, public.farmer,
  public.harvest_remark, public.planting_status, public.crop_category, public.irrigation_type,
  public.ref_harvest_remark, public.ref_quality_grade, public.ref_planting_status, public.ref_irrigation_type,
  public.ref_soil_type, public.ref_season, public.ref_crop_category, public.profiles cascade;
drop function if exists public.handle_new_user() cascade;
drop function if exists public.is_admin() cascade;
drop function if exists public.check_harvest_date() cascade;
drop function if exists public.set_updated_at() cascade;
