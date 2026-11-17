-- Paste the full file into Supabase Dashboard > SQL Editor > New Query > Run.
-- Designed for a new/empty project. Never expose a service_role key in the browser.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 username text not null default 'Viewer',
 plan text not null default 'Free' check(plan in ('Free','Bronze','Silver','Gold')),
 theme_preference text not null default 'auto' check(theme_preference in ('auto','dark','light')),
 share_region boolean not null default false,
 region text,
 created_at timestamptz not null default now()
);

create or replace function public.new_user_profile() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,username) values (new.id,coalesce(nullif(split_part(new.email,'@',1),''),'Viewer')) on conflict do nothing;
 return new;
end $$;
drop trigger if exists auth_profile_created on auth.users;
create trigger auth_profile_created after insert on auth.users for each row execute function public.new_user_profile();
insert into public.profiles(id,username)
select id,coalesce(nullif(split_part(email,'@',1),''),'Viewer') from auth.users on conflict do nothing;

create or replace function public.guard_profile_plan() returns trigger language plpgsql as $$
begin
 if auth.role() <> 'service_role' and new.plan is distinct from old.plan then
   raise exception 'Plan changes require a verified payment';
 end if;
 return new;
end $$;
drop trigger if exists guard_profile_plan on public.profiles;
create trigger guard_profile_plan before update on public.profiles for each row execute function public.guard_profile_plan();

create table if not exists public.videos (
 id uuid primary key default gen_random_uuid(),
 title text not null, description text not null default '',
 category text not null default 'Featured', poster_url text not null default '',
 video_url text not null,
 duration_label text not null default 'Preview',
 is_premium boolean not null default false,
 created_at timestamptz not null default now()
);

create table if not exists public.comments (
 id uuid primary key default gen_random_uuid(),
 video_id uuid not null references public.videos(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 author_name text not null default 'Viewer',
 body text not null check(char_length(body) between 1 and 450),
 language text not null default 'en' check(language in ('en','hi','mr','es','fr','de','ta')),
 status text not null default 'visible' check(status in ('visible','flagged','hidden')),
 created_at timestamptz not null default now()
);

create or replace function public.validate_comment() returns trigger language plpgsql security definer set search_path=public as $$
declare uname text;
begin
 new.body:=btrim(new.body);
 if char_length(new.body)<2 or char_length(new.body)>450 then raise exception 'Comment must be 2-450 characters'; end if;
 if lower(new.body) ~ '(idiot|moron|fuck|shit|bitch|kill yourself)' then raise exception 'Abusive language is not permitted'; end if;
 if new.body ~ '([^[:alnum:][:space:]])\1{5,}' or new.body ~ '(.)\1{14,}' then raise exception 'Repeated characters are not permitted'; end if;
 if new.body ~* '(https?://|www\.)' then raise exception 'Links are not allowed in comments'; end if;
 if exists(select 1 from public.comments where user_id=auth.uid() and body=new.body and created_at>now()-interval '10 minutes') then raise exception 'Duplicate comment detected'; end if;
 select username into uname from public.profiles where id=auth.uid();
 new.author_name:=coalesce(uname,'Viewer');
 new.status:='visible';
 return new;
end $$;
drop trigger if exists validate_new_comment on public.comments;
create trigger validate_new_comment before insert on public.comments for each row execute function public.validate_comment();

create table if not exists public.comment_reactions (
 comment_id uuid not null references public.comments(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 vote int not null check(vote in (-1,1)),
 primary key(comment_id,user_id)
);
create table if not exists public.comment_reports (
 id uuid primary key default gen_random_uuid(),
 comment_id uuid not null references public.comments(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 reason text not null default 'Inappropriate',
 created_at timestamptz not null default now(),
 unique(comment_id,user_id)
);
create table if not exists public.downloads (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 video_id uuid not null references public.videos(id) on delete cascade,
 downloaded_at timestamptz not null default now(),
 plan_at_download text not null
);
create table if not exists public.payment_orders (
 order_id text primary key,
 user_id uuid not null references auth.users(id) on delete cascade,
 plan text not null check(plan in ('Bronze','Silver','Gold')),
 amount int not null,
 payment_id text unique,
 status text not null default 'pending',
 paid_at timestamptz,
 created_at timestamptz not null default now()
);
create table if not exists public.watch_parties (
 id uuid primary key default gen_random_uuid(),
 code text not null unique,
 host_id uuid not null references auth.users(id) on delete cascade,
 video_id uuid not null references public.videos(id) on delete cascade,
 is_playing boolean not null default false,
 playback_time numeric not null default 0,
 updated_at timestamptz not null default now(),
 created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.videos enable row level security;
alter table public.comments enable row level security;
alter table public.comment_reactions enable row level security;
alter table public.comment_reports enable row level security;
alter table public.downloads enable row level security;
alter table public.payment_orders enable row level security;
alter table public.watch_parties enable row level security;

drop policy if exists "own profile read" on public.profiles;
create policy "own profile read" on public.profiles for select to authenticated using(id=auth.uid());
drop policy if exists "own profile edit" on public.profiles;
create policy "own profile edit" on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
drop policy if exists "read videos" on public.videos;
create policy "read videos" on public.videos for select to authenticated using(true);
drop policy if exists "read public comments" on public.comments;
create policy "read public comments" on public.comments for select to authenticated using(status='visible');
drop policy if exists "write own comments" on public.comments;
create policy "write own comments" on public.comments for insert to authenticated with check(user_id=auth.uid() and status='visible');
drop policy if exists "read reactions" on public.comment_reactions;
create policy "read reactions" on public.comment_reactions for select to authenticated using(true);
drop policy if exists "write reactions" on public.comment_reactions;
create policy "write reactions" on public.comment_reactions for insert to authenticated with check(user_id=auth.uid());
drop policy if exists "edit reactions" on public.comment_reactions;
create policy "edit reactions" on public.comment_reactions for update to authenticated using(user_id=auth.uid());
drop policy if exists "delete reactions" on public.comment_reactions;
create policy "delete reactions" on public.comment_reactions for delete to authenticated using(user_id=auth.uid());
drop policy if exists "own reports" on public.comment_reports;
create policy "own reports" on public.comment_reports for insert to authenticated with check(user_id=auth.uid());
drop policy if exists "see own reports" on public.comment_reports;
create policy "see own reports" on public.comment_reports for select to authenticated using(user_id=auth.uid());
drop policy if exists "own downloads" on public.downloads;
create policy "own downloads" on public.downloads for select to authenticated using(user_id=auth.uid());
drop policy if exists "own orders" on public.payment_orders;
create policy "own orders" on public.payment_orders for select to authenticated using(user_id=auth.uid());
drop policy if exists "read watch parties" on public.watch_parties;
create policy "read watch parties" on public.watch_parties for select to authenticated using(true);
drop policy if exists "create watch parties" on public.watch_parties;
create policy "create watch parties" on public.watch_parties for insert to authenticated with check(host_id=auth.uid());
drop policy if exists "host controls party" on public.watch_parties;
create policy "host controls party" on public.watch_parties for update to authenticated using(host_id=auth.uid()) with check(host_id=auth.uid());

-- A security-definer function with a transaction-scoped lock prevents two concurrent downloads bypassing the daily limit.
create or replace function public.register_download(p_video_id uuid) returns void language plpgsql security definer set search_path=public as $$
declare v_user uuid:=auth.uid(); v_plan text; v_limit int; v_count int; v_premium boolean;
begin
 if v_user is null then raise exception 'Please sign in'; end if;
 perform pg_advisory_xact_lock(hashtext(v_user::text || (now() at time zone 'Asia/Kolkata')::date::text));
 select plan into v_plan from public.profiles where id=v_user;
 if v_plan is null then raise exception 'Profile missing'; end if;
 select is_premium into v_premium from public.videos where id=p_video_id;
 if not found then raise exception 'Video missing'; end if;
 if v_premium and v_plan='Free' then raise exception 'Premium plan required'; end if;
 v_limit:=case v_plan when 'Free' then 1 when 'Bronze' then 3 when 'Silver' then 10 else 30 end;
 select count(*) into v_count from public.downloads where user_id=v_user and (downloaded_at at time zone 'Asia/Kolkata')::date=(now() at time zone 'Asia/Kolkata')::date;
 if v_count>=v_limit then raise exception 'Daily download limit reached'; end if;
 insert into public.downloads(user_id,video_id,plan_at_download) values(v_user,p_video_id,v_plan);
end $$;
revoke all on function public.register_download(uuid) from public;
grant execute on function public.register_download(uuid) to authenticated;

-- Storage: create a private bucket named videos in Supabase Storage for your own protected uploads.
-- Then add a video row with video_url='private/filename.mp4'. Keep storage access private.

-- Provide known publicly accessible demo samples to make the video player testable.
insert into public.videos(title,description,category,poster_url,video_url,duration_label,is_premium) values
('Nature in Motion','Short CC0 flower and nature video for testing the streaming controls.','Nature','https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=800&q=80','https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4','0:05',false),
('Big Buck Bunny','Open movie sample for testing playback and watch parties.','Animation','https://images.unsplash.com/photo-1474511320723-9a56873867b5?w=800&q=80','https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4','9:56',false),
('Elephants Dream','A sample premium feature entry for exercising access control.','Featured','https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&q=80','https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4','10:53',true);

-- Enable realtime on the watch party table using the Supabase Realtime publication.
do $$ begin
  alter publication supabase_realtime add table public.watch_parties;
exception when duplicate_object then null; end $$;
