-- STEP C: converts the original tables to 3NF in place (keeps all rows), then adds constraints,
-- audit columns, login roles and security rules. Run once, after Step B.

-- ---------- 1. Lookup (reference) tables: remove transitive dependencies ----------
create table public.ref_crop_category   (category_id smallint primary key, category_name varchar(50) not null unique);
create table public.ref_season          (season_id smallint primary key, season_name varchar(30) not null unique);
create table public.ref_soil_type       (soil_type_id smallint primary key, soil_type_name varchar(50) not null unique);
create table public.ref_irrigation_type (irrigation_type_id smallint primary key, irrigation_type_name varchar(50) not null unique);
create table public.ref_planting_status (status_id smallint primary key, status_name varchar(30) not null unique);
create table public.ref_quality_grade   (grade_id smallint primary key, grade_name varchar(30) not null unique);
create table public.ref_harvest_remark  (remark_id smallint primary key, remark_description varchar(50) not null unique);

insert into public.ref_crop_category values (1,'Cereal'),(2,'Vegetable'),(3,'Fruit'),(4,'Legume'),(5,'Root Crop');
insert into public.ref_season values (1,'Wet Season'),(2,'Dry Season'),(3,'Year Round');
insert into public.ref_soil_type values (1,'Loam'),(2,'Clay Loam'),(3,'Sandy Loam'),(4,'Clay');
insert into public.ref_irrigation_type values (1,'Rainfed'),(2,'Irrigated'),(3,'Drip Irrigation'),(4,'Sprinkler');
insert into public.ref_planting_status values (1,'Planned'),(2,'Growing'),(3,'Harvested'),(4,'Failed');
insert into public.ref_quality_grade values (1,'Grade A'),(2,'Grade B'),(3,'Grade C');
insert into public.ref_harvest_remark values (1,'Good Harvest'),(2,'Acceptable Quality'),(3,'Low Yield'),(4,'Poor Quality'),(5,'Damaged Harvest'),(6,'High Quality Harvest');

-- ---------- 2. Replace the text columns with foreign keys ----------
alter table public.crop
  add column category_id smallint references public.ref_crop_category(category_id),
  add column season_id   smallint references public.ref_season(season_id);
update public.crop c set category_id = r.category_id from public.ref_crop_category r where r.category_name = c.crop_category;
update public.crop c set season_id   = r.season_id   from public.ref_season r         where r.season_name   = c.recommended_season;
alter table public.crop alter column category_id set not null, alter column season_id set not null,
  drop column crop_category, drop column recommended_season;

alter table public.farm
  add column soil_type_id smallint references public.ref_soil_type(soil_type_id),
  add column irrigation_type_id smallint references public.ref_irrigation_type(irrigation_type_id);
update public.farm f set soil_type_id = r.soil_type_id from public.ref_soil_type r where r.soil_type_name = f.soil_type;
update public.farm f set irrigation_type_id = r.irrigation_type_id from public.ref_irrigation_type r where r.irrigation_type_name = f.irrigation_type;
alter table public.farm alter column soil_type_id set not null, alter column irrigation_type_id set not null,
  drop column soil_type, drop column irrigation_type;

alter table public.planting add column status_id smallint references public.ref_planting_status(status_id);
update public.planting p set status_id = r.status_id from public.ref_planting_status r where r.status_name = p.status;
alter table public.planting alter column status_id set not null, drop column status;

alter table public.harvest
  add column grade_id smallint references public.ref_quality_grade(grade_id),
  add column remark_id smallint references public.ref_harvest_remark(remark_id);
update public.harvest h set grade_id = r.grade_id from public.ref_quality_grade r where r.grade_name = h.quality_grade;
update public.harvest h set remark_id = r.remark_id from public.ref_harvest_remark r where lower(r.remark_description) = lower(h.remarks);
alter table public.harvest alter column grade_id set not null, alter column remark_id set not null,
  drop column quality_grade, drop column remarks;

-- ---------- 3. Required fields, uniqueness and CHECK rules ----------
alter table public.farmer
  alter column first_name set not null, alter column last_name set not null, alter column contact_number set not null,
  alter column address set not null, alter column date_registered set default current_date, alter column date_registered set not null,
  add constraint uq_farmer_contact unique (contact_number),
  add constraint chk_farmer_names check (length(trim(first_name)) > 0 and length(trim(last_name)) > 0),
  add constraint chk_farmer_contact check (contact_number ~ '^[0-9+() -]{7,20}$');
alter table public.farm
  alter column farmer_id set not null, alter column farm_name set not null, alter column location set not null, alter column area_hectares set not null,
  add constraint uq_farm unique (farmer_id, farm_name), add constraint chk_farm_area check (area_hectares > 0);
alter table public.crop
  alter column crop_name set not null, alter column variety set not null, alter column growing_period_days set not null,
  add constraint uq_crop unique (crop_name, variety), add constraint chk_crop_days check (growing_period_days between 1 and 1500);
alter table public.planting
  alter column farm_id set not null, alter column crop_id set not null, alter column planting_date set not null, alter column area_planted set not null,
  alter column expected_harvest_date set not null,
  add constraint chk_planting_area check (area_planted > 0), add constraint chk_planting_seed check (seed_quantity is null or seed_quantity >= 0),
  add constraint chk_planting_dates check (expected_harvest_date >= planting_date);
alter table public.harvest
  alter column planting_id set not null, alter column harvest_date set not null, alter column quantity_kg set not null, alter column selling_price_per_kg set not null,
  add constraint chk_harvest_qty check (quantity_kg > 0), add constraint chk_harvest_price check (selling_price_per_kg >= 0);

create function public.check_harvest_date() returns trigger language plpgsql as $$
begin
  if new.harvest_date < (select planting_date from public.planting where planting_id = new.planting_id) then
    raise exception 'Harvest date cannot be earlier than the planting date' using errcode = '23514';
  end if;
  return new;
end $$;
create trigger trg_harvest_date before insert or update on public.harvest for each row execute function public.check_harvest_date();

create index on public.farm(farmer_id);   create index on public.planting(farm_id);
create index on public.planting(crop_id); create index on public.harvest(planting_id);

-- ---------- 4. Audit columns ----------
do $$ declare t text; begin
  foreach t in array array['farmer','farm','crop','planting','harvest'] loop
    execute format('alter table public.%I add column created_at timestamptz not null default now(), add column updated_at timestamptz not null default now(), add column created_by uuid default auth.uid(), add column updated_by uuid', t);
  end loop;
end $$;
create function public.set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); new.updated_by = auth.uid(); return new; end $$;
do $$ declare t text; begin
  foreach t in array array['farmer','farm','crop','planting','harvest'] loop
    execute format('create trigger trg_%1$s_updated before update on public.%1$s for each row execute function public.set_updated_at()', t);
  end loop;
end $$;

-- ---------- 5. Login profiles and roles ----------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text, role text not null default 'staff' check (role in ('admin','staff')),
  created_at timestamptz not null default now());
create function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$
begin insert into public.profiles(id, full_name) values (new.id, new.email); return new; end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();
create function public.is_admin() returns boolean language sql security definer stable set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin') $$;
insert into public.profiles (id, full_name) select id, email from auth.users on conflict do nothing;   -- keep existing accounts

-- ---------- 6. Row Level Security ----------
do $$ declare t text; begin
  foreach t in array array['ref_crop_category','ref_season','ref_soil_type','ref_irrigation_type','ref_planting_status','ref_quality_grade','ref_harvest_remark'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy "read" on public.%I for select to authenticated using (true)', t);
  end loop;
  foreach t in array array['farmer','farm','planting','harvest'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy "read"   on public.%I for select to authenticated using (true)', t);
    execute format('create policy "insert" on public.%I for insert to authenticated with check (true)', t);
    execute format('create policy "update" on public.%I for update to authenticated using (true) with check (true)', t);
    execute format('create policy "delete" on public.%I for delete to authenticated using (public.is_admin())', t);
  end loop;
end $$;
alter table public.crop enable row level security;
create policy "read"   on public.crop for select to authenticated using (true);
create policy "insert" on public.crop for insert to authenticated with check (public.is_admin());
create policy "update" on public.crop for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "delete" on public.crop for delete to authenticated using (public.is_admin());
alter table public.profiles enable row level security;
create policy "read profiles" on public.profiles for select to authenticated using (true);
create policy "admin updates profiles" on public.profiles for update to authenticated using (public.is_admin()) with check (public.is_admin());
