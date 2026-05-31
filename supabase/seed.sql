-- Play Outside local development seed data.
-- This seed avoids auth.users dependencies, so created_by_user_id fields remain null.

insert into public.categories (name, slug, display_order)
values
  ('Adventure', 'adventure', 10),
  ('Sport', 'sport', 20),
  ('Fitness', 'fitness', 30),
  ('Nature', 'nature', 40),
  ('Kids', 'kids', 50),
  ('Music & Events', 'music-events', 60),
  ('Markets', 'markets', 70),
  ('Water Activities', 'water-activities', 80),
  ('Social', 'social', 90),
  ('Indoor Activities', 'indoor-activities', 100)
on conflict (slug) do update set
  name = excluded.name,
  display_order = excluded.display_order,
  updated_at = now();

insert into public.tags (name, slug)
values
  ('outdoor', 'outdoor'),
  ('indoor', 'indoor'),
  ('mixed', 'mixed'),
  ('beginner-friendly', 'beginner-friendly'),
  ('family-friendly', 'family-friendly'),
  ('kids', 'kids'),
  ('bike-required', 'bike-required'),
  ('helmet-required', 'helmet-required'),
  ('team-sport', 'team-sport'),
  ('pet-friendly', 'pet-friendly'),
  ('parking', 'parking'),
  ('toilets', 'toilets'),
  ('restaurant', 'restaurant'),
  ('wheelchair-accessible', 'wheelchair-accessible'),
  ('weather-dependent', 'weather-dependent')
on conflict (slug) do update set
  name = excluded.name,
  updated_at = now();

insert into public.activities (
  name,
  slug,
  short_description,
  default_intensity_level,
  is_featured,
  featured_priority,
  status,
  published_at
)
values
  ('Mountain Biking', 'mountain-biking', 'Off-road cycling on trails, tracks, and routes.', 'challenging', true, 100, 'published', now()),
  ('Trail Running', 'trail-running', 'Running routes through parks, forests, reserves, and trail networks.', 'moderate', true, 90, 'published', now()),
  ('BMX Track', 'bmx-track', 'Purpose-built BMX tracks and pump-track style riding.', 'moderate', false, 0, 'published', now()),
  ('Hiking', 'hiking', 'Walking trails, day hikes, and nature routes.', 'easy', true, 80, 'published', now()),
  ('Paintball', 'paintball', 'Outdoor paintball arenas and group games.', 'moderate', false, 0, 'published', now()),
  ('Rock Climbing', 'rock-climbing', 'Indoor and outdoor climbing activities.', 'challenging', false, 0, 'published', now()),
  ('Touch Rugby', 'touch-rugby', 'Social and competitive non-contact rugby sessions.', 'moderate', false, 0, 'published', now()),
  ('Outdoor Yoga', 'outdoor-yoga', 'Yoga classes hosted in parks and open-air spaces.', 'relaxed', false, 0, 'published', now()),
  ('Live Music', 'live-music', 'Live bands, concerts, and open-air music events.', 'relaxed', true, 70, 'published', now()),
  ('Farmers Market', 'farmers-market', 'Local food, craft, and produce markets.', 'relaxed', true, 60, 'published', now())
on conflict (slug) do update set
  name = excluded.name,
  short_description = excluded.short_description,
  default_intensity_level = excluded.default_intensity_level,
  is_featured = excluded.is_featured,
  featured_priority = excluded.featured_priority,
  status = excluded.status,
  published_at = coalesce(public.activities.published_at, excluded.published_at),
  updated_at = now();

insert into public.activity_categories (activity_id, category_id)
select a.id, c.id
from (values
  ('mountain-biking', 'adventure'),
  ('mountain-biking', 'sport'),
  ('mountain-biking', 'fitness'),
  ('mountain-biking', 'nature'),
  ('trail-running', 'fitness'),
  ('trail-running', 'nature'),
  ('trail-running', 'sport'),
  ('bmx-track', 'sport'),
  ('bmx-track', 'kids'),
  ('hiking', 'nature'),
  ('hiking', 'fitness'),
  ('hiking', 'kids'),
  ('paintball', 'adventure'),
  ('paintball', 'social'),
  ('rock-climbing', 'adventure'),
  ('rock-climbing', 'fitness'),
  ('touch-rugby', 'sport'),
  ('touch-rugby', 'social'),
  ('outdoor-yoga', 'fitness'),
  ('outdoor-yoga', 'nature'),
  ('live-music', 'music-events'),
  ('live-music', 'social'),
  ('farmers-market', 'markets'),
  ('farmers-market', 'kids'),
  ('farmers-market', 'social')
) as links(activity_slug, category_slug)
join public.activities a on a.slug = links.activity_slug
join public.categories c on c.slug = links.category_slug
on conflict (activity_id, category_id) do nothing;

insert into public.activity_tags (activity_id, tag_id)
select a.id, t.id
from (values
  ('mountain-biking', 'outdoor'),
  ('mountain-biking', 'bike-required'),
  ('mountain-biking', 'helmet-required'),
  ('mountain-biking', 'weather-dependent'),
  ('trail-running', 'outdoor'),
  ('trail-running', 'beginner-friendly'),
  ('bmx-track', 'outdoor'),
  ('bmx-track', 'bike-required'),
  ('bmx-track', 'helmet-required'),
  ('hiking', 'outdoor'),
  ('hiking', 'beginner-friendly'),
  ('paintball', 'outdoor'),
  ('paintball', 'team-sport'),
  ('rock-climbing', 'mixed'),
  ('touch-rugby', 'outdoor'),
  ('touch-rugby', 'team-sport'),
  ('outdoor-yoga', 'outdoor'),
  ('outdoor-yoga', 'beginner-friendly'),
  ('live-music', 'mixed'),
  ('farmers-market', 'outdoor'),
  ('farmers-market', 'family-friendly')
) as links(activity_slug, tag_slug)
join public.activities a on a.slug = links.activity_slug
join public.tags t on t.slug = links.tag_slug
on conflict (activity_id, tag_id) do nothing;

insert into public.organisers (name, slug, description, website_url, status, published_at)
values
  ('Crusaders Sports Club', 'crusaders-sports-club', 'Sports club and social venue hosting regular activities and events.', 'https://www.crusadersclub.co.za', 'published', now()),
  ('Play Outside Demo Events', 'play-outside-demo-events', 'Demo organiser for local development event listings.', null, 'published', now())
on conflict (slug) do update set
  name = excluded.name,
  description = excluded.description,
  website_url = excluded.website_url,
  status = excluded.status,
  published_at = coalesce(public.organisers.published_at, excluded.published_at),
  updated_at = now();

insert into public.venues (
  name,
  slug,
  short_description,
  description,
  country,
  province,
  city,
  suburb,
  latitude,
  longitude,
  location,
  website_url,
  is_featured,
  featured_priority,
  status,
  published_at
)
values
  ('Giba Gorge', 'giba-gorge', 'Trail park with mountain biking, running, and BMX options.', 'Outdoor trail destination with a mix of cycling, running, and family-friendly activities.', 'South Africa', 'KwaZulu-Natal', 'Durban', 'Pinetown', -29.8252, 30.7946, extensions.ST_SetSRID(extensions.ST_MakePoint(30.7946, -29.8252), 4326)::extensions.geography, 'https://gibagorge.co.za', true, 100, 'published', now()),
  ('Holla Trails', 'holla-trails', 'North Coast trail network known for mountain biking routes.', 'Trail network with marked routes for mountain bikers and outdoor fitness users.', 'South Africa', 'KwaZulu-Natal', 'Ballito', 'Sugar Rush Park', -29.4831, 31.2031, extensions.ST_SetSRID(extensions.ST_MakePoint(31.2031, -29.4831), 4326)::extensions.geography, 'https://hollatrails.co.za', true, 90, 'published', now()),
  ('Crusaders Sports Club', 'crusaders-sports-club', 'Community sports club with social sport and events.', 'Sports club venue supporting regular touch rugby and community activities.', 'South Africa', 'KwaZulu-Natal', 'Durban', 'Durban North', -29.7866, 31.0402, extensions.ST_SetSRID(extensions.ST_MakePoint(31.0402, -29.7866), 4326)::extensions.geography, 'https://www.crusadersclub.co.za', true, 80, 'published', now()),
  ('Durban Botanic Gardens', 'durban-botanic-gardens', 'Historic gardens with outdoor music and family-friendly events.', 'Green outdoor venue in Durban for walks, picnics, concerts, and cultural events.', 'South Africa', 'KwaZulu-Natal', 'Durban', 'Berea', -29.8466, 31.0067, extensions.ST_SetSRID(extensions.ST_MakePoint(31.0067, -29.8466), 4326)::extensions.geography, 'https://durbanbotanicgardens.org.za', true, 70, 'published', now()),
  ('Sugar Rush Park', 'sugar-rush-park', 'Family activity park with markets, trails, and kid-friendly activities.', 'Outdoor family venue on the North Coast with food, markets, trails, and play areas.', 'South Africa', 'KwaZulu-Natal', 'Ballito', 'Umhlali', -29.4826, 31.2042, extensions.ST_SetSRID(extensions.ST_MakePoint(31.2042, -29.4826), 4326)::extensions.geography, 'https://sugarrush.co.za', true, 60, 'published', now())
on conflict (slug) do update set
  name = excluded.name,
  short_description = excluded.short_description,
  description = excluded.description,
  country = excluded.country,
  province = excluded.province,
  city = excluded.city,
  suburb = excluded.suburb,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  location = excluded.location,
  website_url = excluded.website_url,
  is_featured = excluded.is_featured,
  featured_priority = excluded.featured_priority,
  status = excluded.status,
  published_at = coalesce(public.venues.published_at, excluded.published_at),
  updated_at = now();

update public.venues
set claimed_by_organiser_id = public.organisers.id
from public.organisers
where public.venues.slug = 'crusaders-sports-club'
  and public.organisers.slug = 'crusaders-sports-club';

insert into public.venue_activities (
  venue_id,
  activity_id,
  description,
  price_description,
  availability_description,
  intensity_level,
  is_featured,
  featured_priority,
  status
)
select v.id, a.id, links.description, links.price_description, links.availability_description, links.intensity_level::public.intensity_level, links.is_featured, links.featured_priority, 'active'::public.venue_activity_status
from (values
  ('giba-gorge', 'mountain-biking', 'Mountain biking trails and routes at Giba Gorge.', 'Day fees and memberships may apply.', 'Check venue channels for trail status.', 'challenging', true, 100),
  ('giba-gorge', 'trail-running', 'Trail running routes through the Giba Gorge trail network.', 'Day fees may apply.', 'Best confirmed before arrival after heavy rain.', 'moderate', true, 90),
  ('giba-gorge', 'bmx-track', 'BMX and pump-track style riding options.', 'Day fees may apply.', 'Check venue hours before visiting.', 'moderate', false, 0),
  ('holla-trails', 'mountain-biking', 'Marked mountain biking trails on the North Coast.', 'Trail permits may apply.', 'Check trail status before travelling.', 'challenging', true, 80),
  ('crusaders-sports-club', 'touch-rugby', 'Regular social touch rugby hosted at Crusaders.', 'Session or club fees may apply.', 'Usually weekday evenings.', 'moderate', true, 70),
  ('durban-botanic-gardens', 'live-music', 'Open-air music and community events in the gardens.', 'Event-dependent pricing.', 'Check event listings for dates.', 'relaxed', true, 60),
  ('sugar-rush-park', 'farmers-market', 'Family-friendly markets with food, crafts, and outdoor activities.', 'Free entry or event-dependent pricing.', 'Often hosted over weekends.', 'relaxed', true, 50)
) as links(venue_slug, activity_slug, description, price_description, availability_description, intensity_level, is_featured, featured_priority)
join public.venues v on v.slug = links.venue_slug
join public.activities a on a.slug = links.activity_slug
on conflict (venue_id, activity_id) do update set
  description = excluded.description,
  price_description = excluded.price_description,
  availability_description = excluded.availability_description,
  intensity_level = excluded.intensity_level,
  is_featured = excluded.is_featured,
  featured_priority = excluded.featured_priority,
  status = excluded.status,
  updated_at = now();

insert into public.venue_tags (venue_id, tag_id)
select v.id, t.id
from (values
  ('giba-gorge', 'outdoor'),
  ('giba-gorge', 'parking'),
  ('giba-gorge', 'toilets'),
  ('giba-gorge', 'restaurant'),
  ('holla-trails', 'outdoor'),
  ('holla-trails', 'parking'),
  ('holla-trails', 'weather-dependent'),
  ('crusaders-sports-club', 'parking'),
  ('crusaders-sports-club', 'toilets'),
  ('crusaders-sports-club', 'team-sport'),
  ('durban-botanic-gardens', 'family-friendly'),
  ('durban-botanic-gardens', 'kids'),
  ('durban-botanic-gardens', 'wheelchair-accessible'),
  ('sugar-rush-park', 'family-friendly'),
  ('sugar-rush-park', 'kids'),
  ('sugar-rush-park', 'parking'),
  ('sugar-rush-park', 'restaurant')
) as links(venue_slug, tag_slug)
join public.venues v on v.slug = links.venue_slug
join public.tags t on t.slug = links.tag_slug
on conflict (venue_id, tag_id) do nothing;

insert into public.venue_links (venue_id, label, url, link_type, display_order)
select v.id, links.label, links.url, links.link_type, links.display_order
from (values
  ('giba-gorge', 'Website', 'https://gibagorge.co.za', 'website', 10),
  ('holla-trails', 'Website', 'https://hollatrails.co.za', 'website', 10),
  ('crusaders-sports-club', 'Website', 'https://www.crusadersclub.co.za', 'website', 10),
  ('durban-botanic-gardens', 'Website', 'https://durbanbotanicgardens.org.za', 'website', 10),
  ('sugar-rush-park', 'Website', 'https://sugarrush.co.za', 'website', 10)
) as links(venue_slug, label, url, link_type, display_order)
join public.venues v on v.slug = links.venue_slug
where not exists (
  select 1 from public.venue_links vl where vl.venue_id = v.id and vl.url = links.url
);

insert into public.events (
  organiser_id,
  venue_id,
  title,
  slug,
  short_description,
  description,
  event_type,
  start_datetime,
  end_datetime,
  is_recurring,
  recurrence_description,
  price_description,
  is_featured,
  featured_priority,
  status,
  published_at
)
select o.id, v.id, e.title, e.slug, e.short_description, e.description, e.event_type::public.event_type, e.start_datetime::timestamptz, e.end_datetime::timestamptz, e.is_recurring, e.recurrence_description, e.price_description, e.is_featured, e.featured_priority, 'published'::public.publish_status, now()
from (values
  ('crusaders-sports-club', 'crusaders-sports-club', 'Touch Rugby @ Crusaders Monday Nights', 'touch-rugby-crusaders-monday-nights', 'Weekly social touch rugby under lights at Crusaders.', 'A recurring Monday night touch rugby session for social and fitness-focused players.', 'recurring', '2026-06-01 17:30:00+02', '2026-06-01 19:30:00+02', true, 'Most Monday evenings. Confirm with the organiser before arriving.', 'Session fees may apply.', true, 100),
  ('play-outside-demo-events', 'giba-gorge', 'Mount Vernon 60km Mountain Bike Race', 'mount-vernon-60km-mountain-bike-race', 'A 60km mountain bike race for experienced riders.', 'A once-off endurance mountain bike race linked to the Durban trail community.', 'once_off', '2026-07-12 06:30:00+02', '2026-07-12 13:00:00+02', false, null, 'Entry fee required.', true, 90),
  ('play-outside-demo-events', 'giba-gorge', 'Beginner Trail Run at Giba Gorge', 'beginner-trail-run-giba-gorge', 'Beginner-friendly guided trail run at Giba Gorge.', 'A short guided run for people getting started with trail running.', 'once_off', '2026-06-14 07:00:00+02', '2026-06-14 09:00:00+02', false, null, 'Booking or day fee may apply.', true, 80)
) as e(organiser_slug, venue_slug, title, slug, short_description, description, event_type, start_datetime, end_datetime, is_recurring, recurrence_description, price_description, is_featured, featured_priority)
join public.organisers o on o.slug = e.organiser_slug
join public.venues v on v.slug = e.venue_slug
on conflict (slug) do update set
  organiser_id = excluded.organiser_id,
  venue_id = excluded.venue_id,
  title = excluded.title,
  short_description = excluded.short_description,
  description = excluded.description,
  event_type = excluded.event_type,
  start_datetime = excluded.start_datetime,
  end_datetime = excluded.end_datetime,
  is_recurring = excluded.is_recurring,
  recurrence_description = excluded.recurrence_description,
  price_description = excluded.price_description,
  is_featured = excluded.is_featured,
  featured_priority = excluded.featured_priority,
  status = excluded.status,
  published_at = coalesce(public.events.published_at, excluded.published_at),
  updated_at = now();

insert into public.event_activities (event_id, activity_id)
select e.id, a.id
from (values
  ('touch-rugby-crusaders-monday-nights', 'touch-rugby'),
  ('mount-vernon-60km-mountain-bike-race', 'mountain-biking'),
  ('beginner-trail-run-giba-gorge', 'trail-running')
) as links(event_slug, activity_slug)
join public.events e on e.slug = links.event_slug
join public.activities a on a.slug = links.activity_slug
on conflict (event_id, activity_id) do nothing;

insert into public.event_links (event_id, label, url, link_type, display_order)
select e.id, links.label, links.url, links.link_type, links.display_order
from (values
  ('touch-rugby-crusaders-monday-nights', 'More info', 'https://www.crusadersclub.co.za', 'more_info', 10),
  ('mount-vernon-60km-mountain-bike-race', 'More info', 'https://gibagorge.co.za', 'more_info', 10),
  ('beginner-trail-run-giba-gorge', 'More info', 'https://gibagorge.co.za', 'more_info', 10)
) as links(event_slug, label, url, link_type, display_order)
join public.events e on e.slug = links.event_slug
where not exists (
  select 1 from public.event_links el where el.event_id = e.id and el.url = links.url
);
