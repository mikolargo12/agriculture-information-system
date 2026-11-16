# Agriculture Information System

A web-based system for recording farmers, farms, crops, planting activities and harvests, with a dashboard,
reports and role-based access (Administrator and Staff). Built with HTML, Bootstrap 5, JavaScript and a
Supabase PostgreSQL database (3NF).

## Run it
1. Create a Supabase project. In the SQL Editor run, one at a time and once each:
   `database/00_reset.sql`, `database/01_original_tables.sql`, `database/02_normalize.sql`. Check with `database/check.sql`.
2. Copy `config.example.js` to `config.js` and paste your Supabase URL and anon (public) key.
   Never commit `config.js` and never use the service_role key.
3. Open `index.html` with a local server (for example the VS Code "Live Server" extension).
4. Create an account on the login page, then make it an Administrator in the SQL Editor:
   `update public.profiles set role = 'admin' where full_name = 'your-email@example.com';`

## Contents
- `index.html` – the application
- `database/` – SQL scripts (original tables, normalization to 3NF, constraints, security rules)
- `docs/` – project documentation

Roles: Administrator (full access) and Staff (add/edit; cannot delete or change Crops).
