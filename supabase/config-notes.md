# Supabase Configuration Notes

This project uses a database-only Supabase MVP layout:

- `supabase/migrations/202605300001_create_playoutside_mvp_schema.sql`
- `supabase/seed.sql`

Required extensions:

- `pgcrypto` for UUID defaults via `extensions.gen_random_uuid()`
- `postgis` for `venues.location` and radius search

Supabase normally supports both extensions. If applying to a hosted project, enable PostGIS from the Supabase dashboard if the migration role cannot create it automatically.

Useful local commands:

```bash
supabase start
supabase db reset
```

The seed file does not create auth users. Admin and organiser accounts should be created through Supabase Auth, then linked by inserting rows into `profiles` and `organiser_users`.

Example nearby search:

```sql
select *
from public.search_venues_nearby(
  -29.8587,
  31.0218,
  50,
  'mountain-biking',
  null
);
```

RLS is enabled with baseline policies:

- anonymous users can read published venues, activities, events, active categories/tags, visible media, and public join-table data
- admins can manage all MVP tables
- organiser members can manage their organiser and submitted events, but cannot publish unless they are admins
- public tags remain admin-controlled; users can submit `tag_suggestions`
