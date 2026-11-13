-- Notifications: an in-app inbox filled by triggers, plus optional push
-- delivery through the `push` Edge Function (see README › Bildirimler).

create extension if not exists pg_net;

------------------------------------------------------------------------------
-- Device tokens (Firebase Cloud Messaging registration tokens)
------------------------------------------------------------------------------
create table public.device_tokens (
  token      text primary key check (char_length(token) between 1 and 4096),
  user_id    uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  platform   text not null check (platform in ('android', 'ios')),
  locale     text not null default 'en' check (locale ~ '^[a-z]{2}$'),
  time_zone  text not null default 'UTC' check (char_length(time_zone) <= 64),
  updated_at timestamptz not null default now()
);
create index device_tokens_user_idx on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;

create policy "tokens: read own" on public.device_tokens
  for select to authenticated using (user_id = auth.uid());
create policy "tokens: delete own" on public.device_tokens
  for delete to authenticated using (user_id = auth.uid());

-- Registers (or moves) a token to the caller: when someone signs into another
-- account on the same phone, the token follows the new account.
create function public.register_device_token(
  token text,
  platform text,
  locale text default 'en',
  time_zone text default 'UTC'
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  insert into public.device_tokens (token, user_id, platform, locale, time_zone)
  values (
    register_device_token.token,
    auth.uid(),
    register_device_token.platform,
    coalesce(nullif(lower(left(register_device_token.locale, 2)), ''), 'en'),
    coalesce(nullif(register_device_token.time_zone, ''), 'UTC')
  )
  on conflict on constraint device_tokens_pkey do update
  set user_id    = excluded.user_id,
      platform   = excluded.platform,
      locale     = excluded.locale,
      time_zone  = excluded.time_zone,
      updated_at = now();
end;
$$;

------------------------------------------------------------------------------
-- Notifications inbox
------------------------------------------------------------------------------
create type public.notification_type as enum ('plan_proposed', 'plan_response');

create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  type       public.notification_type not null,
  actor_id   uuid not null references public.profiles (id) on delete cascade,
  circle_id  uuid not null references public.circles (id) on delete cascade,
  plan_id    uuid not null references public.plans (id) on delete cascade,
  response   public.plan_response_status,
  created_at timestamptz not null default now(),
  read_at    timestamptz,
  check ((type = 'plan_response') = (response is not null))
);
create index notifications_user_time_idx on public.notifications (user_id, created_at desc);
create index notifications_unread_idx on public.notifications (user_id) where read_at is null;

alter table public.notifications enable row level security;

-- Only the recipient can read; rows are written by triggers only.
create policy "notifications: read own" on public.notifications
  for select to authenticated using (user_id = auth.uid());
create policy "notifications: delete own" on public.notifications
  for delete to authenticated using (user_id = auth.uid());

-- Marks the given notifications (or all, when ids is null) as read.
create function public.mark_notifications_read(ids uuid[] default null)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.notifications
  set read_at = now()
  where user_id = auth.uid()
    and read_at is null
    and (ids is null or id = any (ids));
$$;

-- New plan: tell every other member of the circle.
create function public.notify_plan_proposed()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.notifications (user_id, type, actor_id, circle_id, plan_id)
  select m.user_id, 'plan_proposed', new.created_by, new.circle_id, new.id
  from public.circle_members m
  where m.circle_id = new.circle_id and m.user_id <> new.created_by;
  return new;
end;
$$;

create trigger on_plan_proposed
  after insert on public.plans
  for each row execute function public.notify_plan_proposed();

-- Answer to a plan: tell the person who proposed it. Changing one's mind
-- replaces the previous unread notification instead of adding another.
create function public.notify_plan_response()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  p public.plans;
begin
  select * into p from public.plans where id = new.plan_id;
  if p.id is null or p.created_by = new.user_id then
    return new;
  end if;

  delete from public.notifications
  where user_id = p.created_by
    and type = 'plan_response'
    and plan_id = p.id
    and actor_id = new.user_id
    and read_at is null;

  insert into public.notifications (user_id, type, actor_id, circle_id, plan_id, response)
  values (p.created_by, 'plan_response', new.user_id, p.circle_id, p.id, new.status);
  return new;
end;
$$;

create trigger on_plan_response_inserted
  after insert on public.plan_responses
  for each row execute function public.notify_plan_response();

create trigger on_plan_response_changed
  after update of status on public.plan_responses
  for each row
  when (old.status is distinct from new.status)
  execute function public.notify_plan_response();

------------------------------------------------------------------------------
-- Push delivery: call the `push` Edge Function for every new notification.
-- Disabled (no-op) until both Vault secrets exist:
--   select vault.create_secret('https://<ref>.supabase.co/functions/v1/push', 'push_webhook_url');
--   select vault.create_secret('<random secret>', 'push_webhook_secret');
------------------------------------------------------------------------------
create function public.dispatch_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  url text;
  secret text;
begin
  select decrypted_secret into url from vault.decrypted_secrets where name = 'push_webhook_url';
  select decrypted_secret into secret from vault.decrypted_secrets where name = 'push_webhook_secret';
  if url is null or secret is null then
    return new;
  end if;

  perform net.http_post(
    url := url,
    body := jsonb_build_object('notification_id', new.id),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || secret
    ),
    timeout_milliseconds := 5000
  );
  return new;
exception when others then
  -- Push is best effort: never block the plan or response that caused it.
  raise warning 'dispatch_push failed: %', sqlerrm;
  return new;
end;
$$;

create trigger on_notification_created
  after insert on public.notifications
  for each row execute function public.dispatch_push();

------------------------------------------------------------------------------
-- Live inbox updates through Supabase Realtime (respects the RLS above).
------------------------------------------------------------------------------
alter publication supabase_realtime add table public.notifications;

------------------------------------------------------------------------------
-- Privileges
------------------------------------------------------------------------------
revoke all on public.device_tokens, public.notifications from anon;
revoke execute on function
  public.register_device_token(text, text, text, text),
  public.mark_notifications_read(uuid[]),
  public.notify_plan_proposed(),
  public.notify_plan_response(),
  public.dispatch_push()
from anon, public;
grant execute on function
  public.register_device_token(text, text, text, text),
  public.mark_notifications_read(uuid[])
to authenticated;
