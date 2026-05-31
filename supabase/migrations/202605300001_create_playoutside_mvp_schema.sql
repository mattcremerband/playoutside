-- Play Outside database layer MVP
-- Venues are the main discovery object. Activities are generic. Events are scheduled organiser-owned listings.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
create extension if not exists postgis with schema extensions;

create type public.publish_status as enum ('draft', 'pending_review', 'published', 'rejected', 'archived');
create type public.venue_activity_status as enum ('active', 'inactive', 'pending_review', 'rejected');
create type public.tag_suggestion_status as enum ('pending', 'approved', 'rejected');
create type public.intensity_level as enum ('relaxed', 'easy', 'moderate', 'challenging', 'extreme');
create type public.media_type as enum ('image', 'video');
create type public.event_type as enum ('once_off', 'recurring', 'series');
create type public.organiser_user_role as enum ('owner', 'admin', 'editor');
create type public.profile_role as enum ('admin', 'organiser', 'user');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  role public.profile_role not null default 'user',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.media (
  id uuid primary key default extensions.gen_random_uuid(),
  storage_path text,
  url text,
  media_type public.media_type not null,
  alt_text text,
  uploaded_by_user_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.organisers (
  id uuid primary key default extensions.gen_random_uuid(),
  name text not null,
  slug text unique not null,
  description text,
  website_url text,
  email text,
  phone text,
  logo_media_id uuid references public.media(id) on delete set null,
  status public.publish_status not null default 'pending_review',
  created_by_user_id uuid references public.profiles(id) on delete set null,
  reviewed_by_user_id uuid references public.profiles(id) on delete set null,
  rejection_reason text,
  published_at timestamptz,
  archived_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organiser_users (
  id uuid primary key default extensions.gen_random_uuid(),
  organiser_id uuid not null references public.organisers(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.organiser_user_role not null,
  created_at timestamptz not null default now(),
  unique (organiser_id, user_id)
);

create table public.activities (
  id uuid primary key default extensions.gen_random_uuid(),
  name text not null,
  slug text unique not null,
  short_description text,
  description text,
  seo_title text,
  seo_description text,
  default_intensity_level public.intensity_level,
  cover_media_id uuid references public.media(id) on delete set null,
  is_featured boolean not null default false,
  featured_priority int not null default 0,
  status public.publish_status not null default 'draft',
  created_by_user_id uuid references public.profiles(id) on delete set null,
  reviewed_by_user_id uuid references public.profiles(id) on delete set null,
  rejection_reason text,
  published_at timestamptz,
  archived_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.venues (
  id uuid primary key default extensions.gen_random_uuid(),
  claimed_by_organiser_id uuid references public.organisers(id) on delete set null,
  name text not null,
  slug text unique not null,
  short_description text,
  description text,
  pricing_description text,
  availability_description text,
  phone text,
  email text,
  website_url text,
  country text,
  province text,
  city text,
  suburb text,
  address_line_1 text,
  address_line_2 text,
  postal_code text,
  latitude numeric check (latitude is null or latitude between -90 and 90),
  longitude numeric check (longitude is null or longitude between -180 and 180),
  location extensions.geography(Point, 4326),
  cover_media_id uuid references public.media(id) on delete set null,
  is_featured boolean not null default false,
  featured_priority int not null default 0,
  status public.publish_status not null default 'draft',
  view_count int not null default 0 check (view_count >= 0),
  external_click_count int not null default 0 check (external_click_count >= 0),
  created_by_user_id uuid references public.profiles(id) on delete set null,
  reviewed_by_user_id uuid references public.profiles(id) on delete set null,
  rejection_reason text,
  published_at timestamptz,
  archived_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.venue_activities (
  id uuid primary key default extensions.gen_random_uuid(),
  venue_id uuid not null references public.venues(id) on delete cascade,
  activity_id uuid not null references public.activities(id) on delete cascade,
  description text,
  price_description text,
  availability_description text,
  intensity_level public.intensity_level,
  is_featured boolean not null default false,
  featured_priority int not null default 0,
  status public.venue_activity_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (venue_id, activity_id)
);

create table public.events (
  id uuid primary key default extensions.gen_random_uuid(),
  organiser_id uuid not null references public.organisers(id) on delete restrict,
  venue_id uuid not null references public.venues(id) on delete restrict,
  title text not null,
  slug text unique not null,
  short_description text,
  description text,
  event_type public.event_type not null,
  start_datetime timestamptz not null,
  end_datetime timestamptz not null,
  is_recurring boolean not null default false,
  recurrence_description text,
  price_description text,
  cover_media_id uuid references public.media(id) on delete set null,
  is_featured boolean not null default false,
  featured_priority int not null default 0,
  status public.publish_status not null default 'draft',
  view_count int not null default 0 check (view_count >= 0),
  external_click_count int not null default 0 check (external_click_count >= 0),
  submitted_by_user_id uuid references public.profiles(id) on delete set null,
  reviewed_by_user_id uuid references public.profiles(id) on delete set null,
  rejection_reason text,
  published_at timestamptz,
  archived_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint events_datetime_order check (end_datetime > start_datetime)
);

create table public.event_activities (
  id uuid primary key default extensions.gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  activity_id uuid not null references public.activities(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (event_id, activity_id)
);

create table public.categories (
  id uuid primary key default extensions.gen_random_uuid(),
  parent_category_id uuid references public.categories(id) on delete set null,
  name text not null,
  slug text unique not null,
  description text,
  icon text,
  colour text,
  display_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.activity_categories (
  id uuid primary key default extensions.gen_random_uuid(),
  activity_id uuid not null references public.activities(id) on delete cascade,
  category_id uuid not null references public.categories(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (activity_id, category_id)
);

create table public.tags (
  id uuid primary key default extensions.gen_random_uuid(),
  name text not null,
  slug text unique not null,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.activity_tags (
  id uuid primary key default extensions.gen_random_uuid(),
  activity_id uuid not null references public.activities(id) on delete cascade,
  tag_id uuid not null references public.tags(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (activity_id, tag_id)
);

create table public.venue_tags (
  id uuid primary key default extensions.gen_random_uuid(),
  venue_id uuid not null references public.venues(id) on delete cascade,
  tag_id uuid not null references public.tags(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (venue_id, tag_id)
);

create table public.tag_suggestions (
  id uuid primary key default extensions.gen_random_uuid(),
  suggested_name text not null,
  suggested_slug text,
  activity_id uuid references public.activities(id) on delete set null,
  venue_id uuid references public.venues(id) on delete set null,
  suggested_by_user_id uuid references public.profiles(id) on delete set null,
  status public.tag_suggestion_status not null default 'pending',
  reviewed_by_user_id uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.activity_media (
  id uuid primary key default extensions.gen_random_uuid(),
  activity_id uuid not null references public.activities(id) on delete cascade,
  media_id uuid not null references public.media(id) on delete cascade,
  display_order int not null default 0,
  created_at timestamptz not null default now(),
  unique (activity_id, media_id)
);

create table public.venue_media (
  id uuid primary key default extensions.gen_random_uuid(),
  venue_id uuid not null references public.venues(id) on delete cascade,
  media_id uuid not null references public.media(id) on delete cascade,
  display_order int not null default 0,
  created_at timestamptz not null default now(),
  unique (venue_id, media_id)
);

create table public.venue_activity_media (
  id uuid primary key default extensions.gen_random_uuid(),
  venue_activity_id uuid not null references public.venue_activities(id) on delete cascade,
  media_id uuid not null references public.media(id) on delete cascade,
  display_order int not null default 0,
  created_at timestamptz not null default now(),
  unique (venue_activity_id, media_id)
);

create table public.event_media (
  id uuid primary key default extensions.gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  media_id uuid not null references public.media(id) on delete cascade,
  display_order int not null default 0,
  created_at timestamptz not null default now(),
  unique (event_id, media_id)
);

create table public.venue_links (
  id uuid primary key default extensions.gen_random_uuid(),
  venue_id uuid not null references public.venues(id) on delete cascade,
  label text not null,
  url text not null,
  link_type text not null,
  display_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.event_links (
  id uuid primary key default extensions.gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  label text not null,
  url text not null,
  link_type text not null,
  display_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Future feature attachment points:
-- reviews should reference venues first, with optional event_id later if event-specific ratings are needed.
-- bookings/payments can reference events and organiser-owned inventory without changing the activity model.
-- favourites can target venues/events through separate join tables or a typed saved_items table.

create index profiles_role_idx on public.profiles(role);

create index organisers_slug_idx on public.organisers(slug);
create index organisers_status_idx on public.organisers(status);
create index organisers_created_by_user_id_idx on public.organisers(created_by_user_id);

create index organiser_users_organiser_id_idx on public.organiser_users(organiser_id);
create index organiser_users_user_id_idx on public.organiser_users(user_id);

create index media_uploaded_by_user_id_idx on public.media(uploaded_by_user_id);

create index activities_slug_idx on public.activities(slug);
create index activities_status_idx on public.activities(status);
create index activities_is_featured_idx on public.activities(is_featured, featured_priority);
create index activities_created_by_user_id_idx on public.activities(created_by_user_id);

create index venues_slug_idx on public.venues(slug);
create index venues_status_idx on public.venues(status);
create index venues_city_idx on public.venues(city);
create index venues_suburb_idx on public.venues(suburb);
create index venues_province_idx on public.venues(province);
create index venues_is_featured_idx on public.venues(is_featured, featured_priority);
create index venues_claimed_by_organiser_id_idx on public.venues(claimed_by_organiser_id);
create index venues_location_gist_idx on public.venues using gist(location);

create index venue_activities_venue_id_idx on public.venue_activities(venue_id);
create index venue_activities_activity_id_idx on public.venue_activities(activity_id);
create index venue_activities_status_idx on public.venue_activities(status);

create index events_slug_idx on public.events(slug);
create index events_status_idx on public.events(status);
create index events_start_datetime_idx on public.events(start_datetime);
create index events_venue_id_idx on public.events(venue_id);
create index events_organiser_id_idx on public.events(organiser_id);
create index events_submitted_by_user_id_idx on public.events(submitted_by_user_id);

create index event_activities_event_id_idx on public.event_activities(event_id);
create index event_activities_activity_id_idx on public.event_activities(activity_id);

create index categories_slug_idx on public.categories(slug);
create index categories_parent_category_id_idx on public.categories(parent_category_id);

create index activity_categories_activity_id_idx on public.activity_categories(activity_id);
create index activity_categories_category_id_idx on public.activity_categories(category_id);

create index tags_slug_idx on public.tags(slug);

create index activity_tags_activity_id_idx on public.activity_tags(activity_id);
create index activity_tags_tag_id_idx on public.activity_tags(tag_id);

create index venue_tags_venue_id_idx on public.venue_tags(venue_id);
create index venue_tags_tag_id_idx on public.venue_tags(tag_id);

create index tag_suggestions_activity_id_idx on public.tag_suggestions(activity_id);
create index tag_suggestions_venue_id_idx on public.tag_suggestions(venue_id);
create index tag_suggestions_suggested_by_user_id_idx on public.tag_suggestions(suggested_by_user_id);
create index tag_suggestions_status_idx on public.tag_suggestions(status);

create index activity_media_activity_id_idx on public.activity_media(activity_id);
create index activity_media_media_id_idx on public.activity_media(media_id);
create index venue_media_venue_id_idx on public.venue_media(venue_id);
create index venue_media_media_id_idx on public.venue_media(media_id);
create index venue_activity_media_venue_activity_id_idx on public.venue_activity_media(venue_activity_id);
create index venue_activity_media_media_id_idx on public.venue_activity_media(media_id);
create index event_media_event_id_idx on public.event_media(event_id);
create index event_media_media_id_idx on public.event_media(media_id);
create index venue_links_venue_id_idx on public.venue_links(venue_id);
create index event_links_event_id_idx on public.event_links(event_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
create trigger set_media_updated_at before update on public.media for each row execute function public.set_updated_at();
create trigger set_organisers_updated_at before update on public.organisers for each row execute function public.set_updated_at();
create trigger set_activities_updated_at before update on public.activities for each row execute function public.set_updated_at();
create trigger set_venues_updated_at before update on public.venues for each row execute function public.set_updated_at();
create trigger set_venue_activities_updated_at before update on public.venue_activities for each row execute function public.set_updated_at();
create trigger set_events_updated_at before update on public.events for each row execute function public.set_updated_at();
create trigger set_categories_updated_at before update on public.categories for each row execute function public.set_updated_at();
create trigger set_tags_updated_at before update on public.tags for each row execute function public.set_updated_at();
create trigger set_venue_links_updated_at before update on public.venue_links for each row execute function public.set_updated_at();
create trigger set_event_links_updated_at before update on public.event_links for each row execute function public.set_updated_at();

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

create or replace function public.current_profile_role()
returns public.profile_role
language sql
stable
security definer
set search_path = public
as $$
  select role
  from public.profiles
  where id = auth.uid();
$$;

create or replace function public.is_organiser_member(p_organiser_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.organiser_users
    where organiser_id = p_organiser_id
      and user_id = auth.uid()
  );
$$;

create or replace function public.is_organiser_admin(p_organiser_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.organiser_users
    where organiser_id = p_organiser_id
      and user_id = auth.uid()
      and role in ('owner', 'admin')
  );
$$;

create or replace function public.search_venues_nearby(
  p_lat numeric,
  p_lng numeric,
  p_radius_km numeric default 25,
  p_activity_slug text default null,
  p_category_slug text default null
)
returns table (
  venue_id uuid,
  name text,
  slug text,
  short_description text,
  city text,
  suburb text,
  province text,
  latitude numeric,
  longitude numeric,
  distance_km numeric,
  matched_activities text[]
)
language sql
stable
as $$
  with origin as (
    select case
      when p_lat is null or p_lng is null then null::extensions.geography
      else extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng::double precision, p_lat::double precision), 4326)::extensions.geography
    end as geog
  )
  select
    v.id,
    v.name,
    v.slug,
    v.short_description,
    v.city,
    v.suburb,
    v.province,
    v.latitude,
    v.longitude,
    case
      when p_lat is null or p_lng is null or v.location is null then null
      else round((extensions.ST_Distance(v.location, origin.geog) / 1000)::numeric, 2)
    end as distance_km,
    array_agg(distinct a.name order by a.name) as matched_activities
  from public.venues v
  join public.venue_activities va on va.venue_id = v.id
  join public.activities a on a.id = va.activity_id
  left join public.activity_categories ac on ac.activity_id = a.id
  left join public.categories c on c.id = ac.category_id
  cross join origin
  where v.status = 'published'
    and v.deleted_at is null
    and va.status = 'active'
    and a.status = 'published'
    and a.deleted_at is null
    and (p_activity_slug is null or a.slug = p_activity_slug)
    and (p_category_slug is null or c.slug = p_category_slug)
    and (
      p_lat is null
      or p_lng is null
      or (
        v.location is not null
        and extensions.ST_DWithin(v.location, origin.geog, p_radius_km * 1000)
      )
    )
  group by v.id, origin.geog
  order by distance_km nulls last, v.is_featured desc, v.featured_priority desc, v.name;
$$;

alter table public.profiles enable row level security;
alter table public.media enable row level security;
alter table public.organisers enable row level security;
alter table public.organiser_users enable row level security;
alter table public.activities enable row level security;
alter table public.venues enable row level security;
alter table public.venue_activities enable row level security;
alter table public.events enable row level security;
alter table public.event_activities enable row level security;
alter table public.categories enable row level security;
alter table public.activity_categories enable row level security;
alter table public.tags enable row level security;
alter table public.activity_tags enable row level security;
alter table public.venue_tags enable row level security;
alter table public.tag_suggestions enable row level security;
alter table public.activity_media enable row level security;
alter table public.venue_media enable row level security;
alter table public.venue_activity_media enable row level security;
alter table public.event_media enable row level security;
alter table public.venue_links enable row level security;
alter table public.event_links enable row level security;

create policy "profiles are readable by self and admins" on public.profiles for select using (id = auth.uid() or public.is_admin());
create policy "users can insert own profile" on public.profiles for insert with check (id = auth.uid());
create policy "users can update own profile except privilege escalation" on public.profiles for update using (id = auth.uid() or public.is_admin()) with check (public.is_admin() or (id = auth.uid() and role = public.current_profile_role()));

create policy "published activities are public" on public.activities for select using (status = 'published' and deleted_at is null);
create policy "published venues are public" on public.venues for select using (status = 'published' and deleted_at is null);
create policy "published events are public" on public.events for select using (status = 'published' and deleted_at is null);
create policy "published organisers are public" on public.organisers for select using (status = 'published' and deleted_at is null);
create policy "active categories are public" on public.categories for select using (is_active);
create policy "active tags are public" on public.tags for select using (is_active);
create policy "visible media is public" on public.media for select using (deleted_at is null);

create policy "public venue activities for public venues" on public.venue_activities for select using (
  status = 'active'
  and exists (select 1 from public.venues v where v.id = venue_id and v.status = 'published' and v.deleted_at is null)
);
create policy "public event activities for public events" on public.event_activities for select using (
  exists (select 1 from public.events e where e.id = event_id and e.status = 'published' and e.deleted_at is null)
);
create policy "public activity categories for public activities" on public.activity_categories for select using (
  exists (select 1 from public.activities a where a.id = activity_id and a.status = 'published' and a.deleted_at is null)
);
create policy "public activity tags for public activities" on public.activity_tags for select using (
  exists (select 1 from public.activities a where a.id = activity_id and a.status = 'published' and a.deleted_at is null)
);
create policy "public venue tags for public venues" on public.venue_tags for select using (
  exists (select 1 from public.venues v where v.id = venue_id and v.status = 'published' and v.deleted_at is null)
);
create policy "public activity media for public activities" on public.activity_media for select using (
  exists (select 1 from public.activities a where a.id = activity_id and a.status = 'published' and a.deleted_at is null)
);
create policy "public venue media for public venues" on public.venue_media for select using (
  exists (select 1 from public.venues v where v.id = venue_id and v.status = 'published' and v.deleted_at is null)
);
create policy "public venue activity media for public venue activities" on public.venue_activity_media for select using (
  exists (
    select 1
    from public.venue_activities va
    join public.venues v on v.id = va.venue_id
    where va.id = venue_activity_id
      and va.status = 'active'
      and v.status = 'published'
      and v.deleted_at is null
  )
);
create policy "public event media for public events" on public.event_media for select using (
  exists (select 1 from public.events e where e.id = event_id and e.status = 'published' and e.deleted_at is null)
);
create policy "public venue links for public venues" on public.venue_links for select using (
  exists (select 1 from public.venues v where v.id = venue_id and v.status = 'published' and v.deleted_at is null)
);
create policy "public event links for public events" on public.event_links for select using (
  exists (select 1 from public.events e where e.id = event_id and e.status = 'published' and e.deleted_at is null)
);

create policy "organiser members can read their organiser" on public.organisers for select using (public.is_organiser_member(id) or public.is_admin());
create policy "organiser members can read memberships" on public.organiser_users for select using (user_id = auth.uid() or public.is_organiser_member(organiser_id) or public.is_admin());
create policy "organiser admins manage memberships" on public.organiser_users for all using (public.is_organiser_admin(organiser_id) or public.is_admin()) with check (public.is_organiser_admin(organiser_id) or public.is_admin());
create policy "organiser creators can add their owner membership" on public.organiser_users for insert to authenticated with check (
  user_id = auth.uid()
  and role = 'owner'
  and exists (
    select 1
    from public.organisers o
    where o.id = organiser_id
      and o.created_by_user_id = auth.uid()
  )
);

create policy "authenticated users can create pending organisers" on public.organisers for insert to authenticated with check (
  created_by_user_id = auth.uid()
  and status in ('draft', 'pending_review')
);
create policy "organiser members can update unpublished organiser records" on public.organisers for update using (
  public.is_organiser_admin(id) or public.is_admin()
) with check (
  public.is_admin() or status in ('draft', 'pending_review', 'rejected', 'archived')
);

create policy "organiser members can read their events" on public.events for select using (public.is_organiser_member(organiser_id) or public.is_admin());
create policy "organiser members can create pending events" on public.events for insert to authenticated with check (
  public.is_organiser_member(organiser_id)
  and submitted_by_user_id = auth.uid()
  and status in ('draft', 'pending_review')
);
create policy "organiser members can update unpublished events" on public.events for update using (
  public.is_organiser_member(organiser_id) or public.is_admin()
) with check (
  public.is_admin() or status in ('draft', 'pending_review', 'rejected', 'archived')
);
create policy "organiser members manage their event activities" on public.event_activities for all using (
  exists (
    select 1
    from public.events e
    where e.id = event_id
      and public.is_organiser_member(e.organiser_id)
  )
  or public.is_admin()
) with check (
  exists (
    select 1
    from public.events e
    where e.id = event_id
      and public.is_organiser_member(e.organiser_id)
  )
  or public.is_admin()
);
create policy "organiser members manage their event media" on public.event_media for all using (
  exists (
    select 1
    from public.events e
    where e.id = event_id
      and public.is_organiser_member(e.organiser_id)
  )
  or public.is_admin()
) with check (
  exists (
    select 1
    from public.events e
    where e.id = event_id
      and public.is_organiser_member(e.organiser_id)
  )
  or public.is_admin()
);
create policy "organiser members manage their event links" on public.event_links for all using (
  exists (
    select 1
    from public.events e
    where e.id = event_id
      and public.is_organiser_member(e.organiser_id)
  )
  or public.is_admin()
) with check (
  exists (
    select 1
    from public.events e
    where e.id = event_id
      and public.is_organiser_member(e.organiser_id)
  )
  or public.is_admin()
);

create policy "claimed organiser members can update unpublished venues" on public.venues for update using (
  public.is_admin() or public.is_organiser_member(claimed_by_organiser_id)
) with check (
  public.is_admin() or status in ('draft', 'pending_review', 'rejected', 'archived')
);

create policy "authenticated users can suggest tags" on public.tag_suggestions for insert to authenticated with check (
  suggested_by_user_id = auth.uid()
  and status = 'pending'
);
create policy "users can read own tag suggestions" on public.tag_suggestions for select using (
  suggested_by_user_id = auth.uid() or public.is_admin()
);

create policy "authenticated users can upload media metadata" on public.media for insert to authenticated with check (uploaded_by_user_id = auth.uid());
create policy "users can update own media metadata" on public.media for update using (uploaded_by_user_id = auth.uid() or public.is_admin()) with check (uploaded_by_user_id = auth.uid() or public.is_admin());

create policy "admins manage activities" on public.activities for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage venues" on public.venues for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage events" on public.events for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage organisers" on public.organisers for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage categories" on public.categories for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage tags" on public.tags for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage tag suggestions" on public.tag_suggestions for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage media" on public.media for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage venue activities" on public.venue_activities for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage event activities" on public.event_activities for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage activity categories" on public.activity_categories for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage activity tags" on public.activity_tags for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage venue tags" on public.venue_tags for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage activity media" on public.activity_media for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage venue media" on public.venue_media for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage venue activity media" on public.venue_activity_media for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage event media" on public.event_media for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage venue links" on public.venue_links for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage event links" on public.event_links for all using (public.is_admin()) with check (public.is_admin());
