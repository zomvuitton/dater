-- Notification triggers, inbox access rules and device tokens.
begin;
create extension if not exists pgtap with schema extensions;
select plan(19);

insert into auth.users (id, email, raw_user_meta_data) values
  ('11111111-1111-1111-1111-111111111111', 'alice@test.dev', '{"display_name":"Alice"}'),
  ('22222222-2222-2222-2222-222222222222', 'bob@test.dev',   '{"display_name":"Bob"}'),
  ('33333333-3333-3333-3333-333333333333', 'carol@test.dev', '{"display_name":"Carol"}'),
  ('44444444-4444-4444-4444-444444444444', 'dave@test.dev',  '{"display_name":"Dave"}');

-- Climbing: alice (owner), bob, carol. Dave is not a member.
insert into public.circles (id, owner_id, name) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Climbing');
insert into public.circle_members (circle_id, user_id) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222'),
  ('aaaaaaaa-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333');

create function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('role', 'authenticated', true),
         set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

create function pg_temp.inbox(uid uuid) returns setof public.notifications language sql as $$
  select * from public.notifications where user_id = uid order by created_at;
$$;

------------------------------------------------------------- plan proposed
select pg_temp.login('22222222-2222-2222-2222-222222222222');
insert into public.plans (id, circle_id, title, starts_at, ends_at) values
  ('bbbbbbbb-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001',
   'Bouldering', '2026-11-17 18:00+00', '2026-11-17 20:00+00');
reset role;

select is((select count(*)::int from pg_temp.inbox('11111111-1111-1111-1111-111111111111') where type = 'plan_proposed'), 1,
  'other member alice is notified about the new plan');
select is((select count(*)::int from pg_temp.inbox('33333333-3333-3333-3333-333333333333') where type = 'plan_proposed'), 1,
  'other member carol is notified about the new plan');
select is((select count(*)::int from pg_temp.inbox('22222222-2222-2222-2222-222222222222')), 0,
  'the proposer is not notified, also not about their automatic "going"');
select is((select count(*)::int from pg_temp.inbox('44444444-4444-4444-4444-444444444444')), 0,
  'non-members are not notified');
select is((select actor_id from pg_temp.inbox('11111111-1111-1111-1111-111111111111') limit 1),
  '22222222-2222-2222-2222-222222222222'::uuid, 'actor is the proposer');

------------------------------------------------------------- plan responses
select pg_temp.login('11111111-1111-1111-1111-111111111111');
insert into public.plan_responses (plan_id, user_id, status)
  values ('bbbbbbbb-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'maybe');
reset role;

select is((select response::text from pg_temp.inbox('22222222-2222-2222-2222-222222222222') where type = 'plan_response'),
  'maybe', 'the proposer is notified about an answer');

select pg_temp.login('11111111-1111-1111-1111-111111111111');
update public.plan_responses set status = 'going'
  where plan_id = 'bbbbbbbb-0000-0000-0000-000000000001' and user_id = '11111111-1111-1111-1111-111111111111';
reset role;

select is((select count(*)::int from pg_temp.inbox('22222222-2222-2222-2222-222222222222')), 1,
  'changing an unread answer replaces the notification');
select is((select response::text from pg_temp.inbox('22222222-2222-2222-2222-222222222222')), 'going',
  'the replacement carries the new answer');

select pg_temp.login('11111111-1111-1111-1111-111111111111');
update public.plan_responses set status = 'going', updated_at = now()
  where plan_id = 'bbbbbbbb-0000-0000-0000-000000000001' and user_id = '11111111-1111-1111-1111-111111111111';
reset role;
select is((select count(*)::int from pg_temp.inbox('22222222-2222-2222-2222-222222222222')), 1,
  'saving the same answer again does not notify');

select pg_temp.login('22222222-2222-2222-2222-222222222222');
update public.plan_responses set status = 'maybe'
  where plan_id = 'bbbbbbbb-0000-0000-0000-000000000001' and user_id = '22222222-2222-2222-2222-222222222222';
reset role;
select is((select count(*)::int from pg_temp.inbox('22222222-2222-2222-2222-222222222222')), 1,
  'the proposer changing their own answer does not notify anyone');

--------------------------------------------------------------- inbox access
select pg_temp.login('33333333-3333-3333-3333-333333333333');
select is((select count(*)::int from public.notifications), 1, 'carol sees only her own notifications');
select throws_ok($$ insert into public.notifications (user_id, type, actor_id, circle_id, plan_id)
  values ('11111111-1111-1111-1111-111111111111', 'plan_proposed', '33333333-3333-3333-3333-333333333333',
          'aaaaaaaa-0000-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000001') $$,
  '42501', null, 'clients cannot create notifications');

select public.mark_notifications_read();
select is((select count(*)::int from public.notifications where read_at is null), 0, 'mark all read');
reset role;
select is((select count(*)::int from pg_temp.inbox('11111111-1111-1111-1111-111111111111') where read_at is null), 1,
  'marking read does not touch other inboxes');

select pg_temp.login('11111111-1111-1111-1111-111111111111');
select public.mark_notifications_read(array[(select id from public.notifications limit 1)]);
select is((select count(*)::int from public.notifications where read_at is null), 0, 'mark selected read');

-------------------------------------------------------------- device tokens
select pg_temp.login('11111111-1111-1111-1111-111111111111');
select public.register_device_token('token-1', 'android', 'tr-TR', 'Europe/Istanbul');
select is((select locale || ' ' || time_zone from public.device_tokens), 'tr Europe/Istanbul',
  'token registered with normalized locale');

select pg_temp.login('22222222-2222-2222-2222-222222222222');
select is((select count(*)::int from public.device_tokens), 0, 'tokens of others are hidden');
select public.register_device_token('token-1', 'android', 'en', 'UTC');
reset role;
select is((select user_id from public.device_tokens where token = 'token-1'),
  '22222222-2222-2222-2222-222222222222'::uuid, 'a token moves to the account that registers it last');

------------------------------------------------------------- plan deletion
delete from public.plans where id = 'bbbbbbbb-0000-0000-0000-000000000001';
select is((select count(*)::int from public.notifications where plan_id = 'bbbbbbbb-0000-0000-0000-000000000001'), 0,
  'deleting a plan removes its notifications');

select * from finish();
rollback;
