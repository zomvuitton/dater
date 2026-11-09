-- Dater: circles + weekly hourly availability shared per circle.
-- All times are stored as timestamptz (UTC). Each availability row is a
-- one-hour block that starts at `starts_at` and is visible to one circle.

------------------------------------------------------------------------------
-- Profiles
------------------------------------------------------------------------------
create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  username     text unique check (username ~ '^[a-z0-9_]{3,20}$'),
  display_name text not null default '' check (char_length(display_name) <= 50),
  avatar_url   text,
  created_at   timestamptz not null default now()
);

comment on column public.profiles.username is
  'Unique lowercase handle, chosen during onboarding (null until then).';

-- Create a profile row automatically for every new auth user.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(left(new.raw_user_meta_data ->> 'display_name', 50), ''));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

------------------------------------------------------------------------------
-- Friendships
------------------------------------------------------------------------------
create type public.friendship_status as enum ('pending', 'accepted');

create table public.friendships (
  id           uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles (id) on delete cascade,
  addressee_id uuid not null references public.profiles (id) on delete cascade,
  status       public.friendship_status not null default 'pending',
  created_at   timestamptz not null default now(),
  responded_at timestamptz,
  check (requester_id <> addressee_id)
);

-- One row per pair of users, regardless of direction.
create unique index friendships_pair_idx on public.friendships (
  least(requester_id, addressee_id),
  greatest(requester_id, addressee_id)
);
create index friendships_addressee_idx on public.friendships (addressee_id);

create function public.are_friends(a uuid, b uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and least(f.requester_id, f.addressee_id) = least(a, b)
      and greatest(f.requester_id, f.addressee_id) = greatest(a, b)
  );
$$;

------------------------------------------------------------------------------
-- Circles
------------------------------------------------------------------------------
create function public.generate_invite_code()
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  bytes bytea := extensions.gen_random_bytes(8);
  code text := '';
begin
  for i in 0..7 loop
    code := code || substr(alphabet, (get_byte(bytes, i) % 32) + 1, 1);
  end loop;
  return code;
end;
$$;

create table public.circles (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  name        text not null check (char_length(name) between 1 and 40),
  emoji       text not null default '👥' check (char_length(emoji) <= 8),
  color       text not null default '#4CAF50' check (color ~ '^#[0-9A-Fa-f]{6}$'),
  invite_code text not null unique default public.generate_invite_code(),
  created_at  timestamptz not null default now()
);

create type public.circle_role as enum ('owner', 'member');

create table public.circle_members (
  circle_id uuid not null references public.circles (id) on delete cascade,
  user_id   uuid not null references public.profiles (id) on delete cascade,
  role      public.circle_role not null default 'member',
  joined_at timestamptz not null default now(),
  primary key (circle_id, user_id)
);
create index circle_members_user_idx on public.circle_members (user_id);

create function public.is_circle_member(cid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.circle_members m
    where m.circle_id = cid and m.user_id = auth.uid()
  );
$$;

create function public.is_circle_owner(cid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.circles c
    where c.id = cid and c.owner_id = auth.uid()
  );
$$;

-- The creator of a circle becomes its owner member.
create function public.handle_new_circle()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.circle_members (circle_id, user_id, role)
  values (new.id, new.owner_id, 'owner');
  return new;
end;
$$;

create trigger on_circle_created
  after insert on public.circles
  for each row execute function public.handle_new_circle();

------------------------------------------------------------------------------
-- Availability: one row per (user, circle, hour block)
------------------------------------------------------------------------------
create table public.availability (
  user_id   uuid not null default auth.uid(),
  circle_id uuid not null,
  starts_at timestamptz not null
    -- Blocks start on a quarter hour so timezones with :30/:45 offsets work.
    check (extract(epoch from starts_at)::bigint % 900 = 0),
  primary key (user_id, circle_id, starts_at),
  -- Only members can share availability with a circle; leaving a circle
  -- removes everything the user shared with it.
  foreign key (circle_id, user_id)
    references public.circle_members (circle_id, user_id) on delete cascade
);
create index availability_circle_time_idx on public.availability (circle_id, starts_at);
create index availability_user_time_idx on public.availability (user_id, starts_at);

------------------------------------------------------------------------------
-- Plans proposed inside a circle
------------------------------------------------------------------------------
create table public.plans (
  id         uuid primary key default gen_random_uuid(),
  circle_id  uuid not null references public.circles (id) on delete cascade,
  created_by uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  title      text not null check (char_length(title) between 1 and 80),
  note       text check (char_length(note) <= 500),
  starts_at  timestamptz not null,
  ends_at    timestamptz not null,
  created_at timestamptz not null default now(),
  check (ends_at > starts_at)
);
create index plans_circle_time_idx on public.plans (circle_id, starts_at);

create type public.plan_response_status as enum ('going', 'maybe', 'no');

create table public.plan_responses (
  plan_id    uuid not null references public.plans (id) on delete cascade,
  user_id    uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  status     public.plan_response_status not null,
  updated_at timestamptz not null default now(),
  primary key (plan_id, user_id)
);

create function public.can_see_plan(pid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.plans p
    join public.circle_members m on m.circle_id = p.circle_id
    where p.id = pid and m.user_id = auth.uid()
  );
$$;

-- The proposer is automatically "going".
create function public.handle_new_plan()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.plan_responses (plan_id, user_id, status)
  values (new.id, new.created_by, 'going');
  return new;
end;
$$;

create trigger on_plan_created
  after insert on public.plans
  for each row execute function public.handle_new_plan();

------------------------------------------------------------------------------
-- Row level security
------------------------------------------------------------------------------
alter table public.profiles       enable row level security;
alter table public.friendships    enable row level security;
alter table public.circles        enable row level security;
alter table public.circle_members enable row level security;
alter table public.availability   enable row level security;
alter table public.plans          enable row level security;
alter table public.plan_responses enable row level security;

-- profiles: visible to every signed-in user (needed for username search).
create policy "profiles: read" on public.profiles
  for select to authenticated using (true);
create policy "profiles: update own" on public.profiles
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- friendships: only the two people involved can see a row. Sending and
-- accepting go through RPCs below; either side can remove the row.
create policy "friendships: read own" on public.friendships
  for select to authenticated
  using (auth.uid() in (requester_id, addressee_id));
create policy "friendships: delete own" on public.friendships
  for delete to authenticated
  using (auth.uid() in (requester_id, addressee_id));

-- circles
create policy "circles: read as member" on public.circles
  for select to authenticated
  using (owner_id = auth.uid() or public.is_circle_member(id));
create policy "circles: create" on public.circles
  for insert to authenticated
  with check (owner_id = auth.uid());
create policy "circles: owner updates" on public.circles
  for update to authenticated
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "circles: owner deletes" on public.circles
  for delete to authenticated
  using (owner_id = auth.uid());

-- circle_members: members see each other; the owner adds accepted friends;
-- members can leave, the owner can remove members.
create policy "members: read as member" on public.circle_members
  for select to authenticated
  using (public.is_circle_member(circle_id));
create policy "members: owner adds friends" on public.circle_members
  for insert to authenticated
  with check (
    role = 'member'
    and public.is_circle_owner(circle_id)
    and public.are_friends(auth.uid(), user_id)
  );
create policy "members: leave or remove" on public.circle_members
  for delete to authenticated
  using (
    role = 'member'
    and (user_id = auth.uid() or public.is_circle_owner(circle_id))
  );

-- availability: write your own rows (the FK guarantees membership); read the
-- rows of circles you belong to.
create policy "availability: read circle" on public.availability
  for select to authenticated
  using (public.is_circle_member(circle_id));
create policy "availability: insert own" on public.availability
  for insert to authenticated
  with check (user_id = auth.uid());
create policy "availability: delete own" on public.availability
  for delete to authenticated
  using (user_id = auth.uid());

-- plans
create policy "plans: read circle" on public.plans
  for select to authenticated
  using (public.is_circle_member(circle_id));
create policy "plans: member creates" on public.plans
  for insert to authenticated
  with check (created_by = auth.uid() and public.is_circle_member(circle_id));
create policy "plans: creator updates" on public.plans
  for update to authenticated
  using (created_by = auth.uid())
  with check (created_by = auth.uid() and public.is_circle_member(circle_id));
create policy "plans: creator or owner deletes" on public.plans
  for delete to authenticated
  using (created_by = auth.uid() or public.is_circle_owner(circle_id));

-- plan_responses
create policy "responses: read circle" on public.plan_responses
  for select to authenticated
  using (public.can_see_plan(plan_id));
create policy "responses: insert own" on public.plan_responses
  for insert to authenticated
  with check (user_id = auth.uid() and public.can_see_plan(plan_id));
create policy "responses: update own" on public.plan_responses
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and public.can_see_plan(plan_id));
create policy "responses: delete own" on public.plan_responses
  for delete to authenticated
  using (user_id = auth.uid());

-- Nothing is readable without signing in.
revoke all on all tables in schema public from anon;

------------------------------------------------------------------------------
-- RPCs
------------------------------------------------------------------------------

-- Send a friend request by username. If the other person already sent one
-- to the caller, it is accepted instead. Returns the friendship row.
create function public.send_friend_request(target_username text)
returns public.friendships
language plpgsql
security definer
set search_path = ''
as $$
declare
  me uuid := auth.uid();
  target uuid;
  existing public.friendships;
begin
  if me is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  select id into target from public.profiles where username = lower(target_username);
  if target is null then
    raise exception 'user not found' using errcode = 'P0002';
  end if;
  if target = me then
    raise exception 'cannot befriend yourself' using errcode = '22023';
  end if;

  select * into existing from public.friendships f
  where least(f.requester_id, f.addressee_id) = least(me, target)
    and greatest(f.requester_id, f.addressee_id) = greatest(me, target);

  if found then
    if existing.status = 'pending' and existing.addressee_id = me then
      update public.friendships
      set status = 'accepted', responded_at = now()
      where id = existing.id
      returning * into existing;
    end if;
    return existing;
  end if;

  insert into public.friendships (requester_id, addressee_id)
  values (me, target)
  returning * into existing;
  return existing;
end;
$$;

-- Accept a pending request addressed to the caller.
create function public.accept_friend_request(request_id uuid)
returns public.friendships
language plpgsql
security definer
set search_path = ''
as $$
declare
  result public.friendships;
begin
  update public.friendships
  set status = 'accepted', responded_at = now()
  where id = request_id and addressee_id = auth.uid() and status = 'pending'
  returning * into result;

  if result.id is null then
    raise exception 'request not found' using errcode = 'P0002';
  end if;
  return result;
end;
$$;

-- Join a circle with its invite code. Returns the circle id.
create function public.join_circle_by_code(code text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  cid uuid;
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  select id into cid from public.circles where invite_code = upper(trim(code));
  if cid is null then
    raise exception 'invalid invite code' using errcode = 'P0002';
  end if;

  insert into public.circle_members (circle_id, user_id, role)
  values (cid, auth.uid(), 'member')
  on conflict do nothing;
  return cid;
end;
$$;

-- Owner-only: invalidate the old invite code and issue a new one.
create function public.regenerate_invite_code(circle_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_code text;
begin
  update public.circles c
  set invite_code = public.generate_invite_code()
  where c.id = regenerate_invite_code.circle_id and c.owner_id = auth.uid()
  returning c.invite_code into new_code;

  if new_code is null then
    raise exception 'not the circle owner' using errcode = '42501';
  end if;
  return new_code;
end;
$$;

-- Set which circles can see the given hour blocks of the caller. Replaces
-- whatever was set for those blocks; an empty circle list clears them.
-- Circles the caller is not a member of are ignored.
create function public.set_availability(slots timestamptz[], circle_ids uuid[])
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  delete from public.availability
  where user_id = auth.uid() and starts_at = any (slots);

  insert into public.availability (user_id, circle_id, starts_at)
  select auth.uid(), m.circle_id, s
  from unnest(slots) as s
  cross join public.circle_members m
  where m.user_id = auth.uid() and m.circle_id = any (circle_ids)
  on conflict do nothing;
end;
$$;

-- Replace all of the caller's availability in [range_start, range_end) with
-- `entries` (a JSON array of {"circle_id", "starts_at"}). Used to copy a week.
create function public.replace_availability_range(
  range_start timestamptz,
  range_end timestamptz,
  entries jsonb
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  delete from public.availability
  where user_id = auth.uid()
    and starts_at >= range_start and starts_at < range_end;

  insert into public.availability (user_id, circle_id, starts_at)
  select auth.uid(), (e ->> 'circle_id')::uuid, (e ->> 'starts_at')::timestamptz
  from jsonb_array_elements(entries) as e
  join public.circle_members m
    on m.circle_id = (e ->> 'circle_id')::uuid and m.user_id = auth.uid()
  where (e ->> 'starts_at')::timestamptz >= range_start
    and (e ->> 'starts_at')::timestamptz < range_end
  on conflict do nothing;
end;
$$;

revoke execute on all functions in schema public from anon, public;
grant execute on function
  public.send_friend_request(text),
  public.accept_friend_request(uuid),
  public.join_circle_by_code(text),
  public.regenerate_invite_code(uuid),
  public.set_availability(timestamptz[], uuid[]),
  public.replace_availability_range(timestamptz, timestamptz, jsonb),
  public.is_circle_member(uuid),
  public.is_circle_owner(uuid),
  public.are_friends(uuid, uuid),
  public.can_see_plan(uuid),
  public.generate_invite_code()
to authenticated;
