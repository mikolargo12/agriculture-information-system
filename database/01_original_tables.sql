-- STEP B: the five ORIGINAL (unnormalized) tables from the project paper, with sample data.
-- Run once, after Step A.
create table public.crop (
  crop_id integer generated always as identity primary key,
  crop_name varchar(80), variety varchar(80), crop_category varchar(50),
  growing_period_days integer, recommended_season varchar(30));
create table public.farmer (
  farmer_id integer generated always as identity primary key,
  first_name varchar(50), last_name varchar(50), contact_number varchar(20),
  address varchar(150), date_registered date);
create table public.farm (
  farm_id integer generated always as identity primary key,
  farmer_id integer references public.farmer(farmer_id),
  farm_name varchar(100), location varchar(150), area_hectares numeric(8,2),
  soil_type varchar(50), irrigation_type varchar(50));
create table public.planting (
  planting_id integer generated always as identity primary key,
  farm_id integer references public.farm(farm_id), crop_id integer references public.crop(crop_id),
  planting_date date, area_planted numeric(8,2), seed_quantity numeric(8,2),
  expected_harvest_date date, status varchar(30));
create table public.harvest (
  harvest_id integer generated always as identity primary key,
  planting_id integer references public.planting(planting_id),
  harvest_date date, quantity_kg numeric(10,2), selling_price_per_kg numeric(10,2),
  quality_grade varchar(30), remarks varchar(200));

insert into public.crop (crop_name, variety, crop_category, growing_period_days, recommended_season) values
 ('Rice','NSIC Rc 222','Cereal',115,'Wet Season'),('Corn','Yellow Corn','Cereal',100,'Dry Season'),
 ('Tomato','Diamante Max','Vegetable',90,'Dry Season'),('Eggplant','Morena','Vegetable',100,'Year Round'),
 ('Banana','Lakatan','Fruit',300,'Year Round'),('Mango','Carabao','Fruit',150,'Year Round'),
 ('Peanut','BPI Pn 9','Legume',110,'Year Round'),('Cassava','Golden Yellow','Root Crop',240,'Year Round'),
 ('Sweet Potato','NSIC Sp 30','Root Crop',120,'Year Round'),('Watermelon','Sweet 16','Fruit',85,'Dry Season');

insert into public.farmer (first_name, last_name, contact_number, address, date_registered) values
 ('Juan','Dela Cruz','09171234567','Cebu City','2026-10-26'),('Maria','Santos','09181234567','Carcar City, Cebu','2026-10-26'),
 ('Pedro','Reyes','09191234567','Danao City, Cebu','2026-10-26'),('Ana','Garcia','09201234567','Argao, Cebu','2026-10-26'),
 ('Jose','Mendoza','09211234567','Bogo City, Cebu','2026-10-26'),('Ramon','Flores','09221234567','Toledo City, Cebu','2026-10-26'),
 ('Elena','Cruz','09231234567','Naga City, Cebu','2026-10-26'),('Antonio','Lim','09241234567','Minglanilla, Cebu','2026-10-26'),
 ('Rosa','Fernandez','09251234567','Liloan, Cebu','2026-10-26'),('Mario','Villanueva','09261234567','Compostela, Cebu','2026-10-26'),
 ('Teresa','Navarro','09271234567','Talisay City, Cebu','2026-10-26'),('Carlos','Ramos','09281234567','Consolacion, Cebu','2026-10-26'),
 ('Liza','Torres','09291234567','Dalaguete, Cebu','2026-10-26'),('Roberto','Castillo','09301234567','Barili, Cebu','2026-10-26'),
 ('Susan','Aquino','09311234567','Sibonga, Cebu','2026-10-26');

insert into public.farm (farmer_id, farm_name, location, area_hectares, soil_type, irrigation_type) values
 (1,'Dela Cruz Farm','Cebu City',2.50,'Loam','Rainfed'),(2,'Santos Rice Farm','Carcar City, Cebu',4.20,'Clay Loam','Irrigated'),
 (3,'Reyes Agricultural Farm','Danao City, Cebu',3.80,'Sandy Loam','Rainfed'),(4,'Garcia Vegetable Farm','Argao, Cebu',1.75,'Loam','Drip Irrigation'),
 (5,'Mendoza Farm','Bogo City, Cebu',5.00,'Clay','Irrigated'),(6,'Flores Corn Farm','Toledo City, Cebu',3.40,'Sandy Loam','Rainfed'),
 (7,'Cruz Family Farm','Naga City, Cebu',2.80,'Loam','Irrigated'),(8,'Lim Agricultural Farm','Minglanilla, Cebu',2.25,'Clay Loam','Drip Irrigation'),
 (9,'Fernandez Farm','Liloan, Cebu',3.10,'Sandy Loam','Rainfed'),(10,'Villanueva Green Farm','Compostela, Cebu',4.50,'Loam','Irrigated'),
 (11,'Navarro Rice Field','Talisay City, Cebu',3.75,'Clay','Irrigated'),(12,'Ramos Farm','Consolacion, Cebu',2.60,'Loam','Rainfed'),
 (13,'Torres Vegetable Farm','Dalaguete, Cebu',1.80,'Sandy Loam','Drip Irrigation'),(14,'Castillo Agricultural Farm','Barili, Cebu',5.50,'Clay Loam','Irrigated'),
 (15,'Aquino Farm','Sibonga, Cebu',3.20,'Loam','Rainfed');

-- Planting and harvest rows follow the pattern visible in the paper's sample data (30 plantings, 20 harvests).
insert into public.planting (farm_id, crop_id, planting_date, area_planted, seed_quantity, expected_harvest_date, status)
select ((n-1)%15)+1, ((n-1)%10)+1, date '2026-01-10' + 3*(n-1), 0.5 + 0.1*((n-1)%10), 10 + 5*(((n-9)%8+8)%8),
       date '2026-01-10' + 3*(n-1) + c.growing_period_days, case when n <= 20 then 'Harvested' else 'Growing' end
from generate_series(1,30) n join public.crop c on c.crop_id = ((n-1)%10)+1 order by n;

insert into public.harvest (planting_id, harvest_date, quantity_kg, selling_price_per_kg, quality_grade, remarks)
select p.planting_id, p.expected_harvest_date + 2, 900 + 125*(p.planting_id-1), 22 + 3.5*((p.planting_id-1)%8),
       'Grade ' || chr(65 + (p.planting_id-1)%3),
       case (p.planting_id-1)%3 when 0 then 'High quality harvest' when 1 then 'Good harvest' else 'Acceptable quality' end
from public.planting p where p.planting_id <= 20 order by p.planting_id;
