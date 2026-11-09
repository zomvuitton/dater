-- Access rules for friendships, circles and per-circle availability.
begin;
create extension if not exists pgtap with schema extensions;
select plan(25);

-- Test users: alice, bob, carol (signup trigger creates profiles).
insert into auth.users (id, email, raw_user_meta_data) values
  ('11111111-1111-1111-1111-111111111111', 'alice@test.dev', '{"display_name":"Alice"}'),
  ('22222222-2222-2222-2222-222222222222', 'bob@test.dev',   '{"display_name":"Bob"}'),
  ('33333333-3333-3333-3333-333333333333', 'carol@test.dev', '{"display_name":"Carol"}');

update public.profiles set username = 'alice' where id = '11111111-1111-1111-1111-111111111111';
update public.profiles set username = 'bob'   where id = '22222222-2222-2222-2222-222222222222';
update public.profiles set username = 'carol' where id = '33333333-3333-3333-3333-333333333333';

select is((select display_name from public.profiles where username = 'alice'), 'Alice',
  'signup trigger creates profile with display name');

create function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('role', 'authenticated', true),
         set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

------------------------------------------------------------------ friendships
select pg_temp.login('11111111-1111-1111-1111-111111111111');
select lives_ok($$ select public.send_friend_request('bob') $$, 'alice sends bob a request');
select throws_ok($$ select public.send_friend_request('nobody') $$, 'P0002', 'user not found',
  'unknown username is rejected');
select throws_ok($$ select public.send_friend_request('alice') $$, '22023', null,
  'cannot befriend yourself');

select pg_temp.login('33333333-3333-3333-3333-333333333333');
select is((select count(*) from public.friendships)::int, 0, 'carol cannot see others'' requests');

select pg_temp.login('22222222-2222-2222-2222-222222222222');
select is((select status::text from public.send_friend_request('alice')), 'accepted',
  'bob requesting alice back accepts the pending request');

-------------------------------------------------------------------- circles
select pg_temp.login('11111111-1111-1111-1111-111111111111');
insert into public.circles (id, name) values ('aaaaaaaa-0000-0000-0000-000000000001', 'Climbing');
insert into public.circles (id, name) values ('aaaaaaaa-0000-0000-0000-000000000002', 'Work');

select is((select role::text from public.circle_members
           where circle_id = 'aaaaaaaa-0000-0000-0000-000000000001'
             and user_id = '11111111-1111-1111-1111-111111111111'),
  'owner', 'creator becomes owner member');
select matches((select invite_code from public.circles where id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  '^[A-Z2-9]{8}$', 'invite code is generated');

select lives_ok($$ insert into public.circle_members (circle_id, user_id)
  values ('aaaaaaaa-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222') $$,
  'owner can add a friend');
select throws_ok($$ insert into public.circle_members (circle_id, user_id)
  values ('aaaaaaaa-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333') $$,
  '42501', null, 'owner cannot add a non-friend');

select pg_temp.login('22222222-2222-2222-2222-222222222222');
select throws_ok($$ insert into public.circles (name, owner_id)
  values ('Fake', '11111111-1111-1111-1111-111111111111') $$,
  '42501', null, 'cannot create a circle for someone else');
select is((select count(*) from public.circles)::int, 1, 'bob sees only circles he is in');

---------------------------------------------------------------- availability
select pg_temp.login('11111111-1111-1111-1111-111111111111');
select lives_ok($$ select public.set_availability(
    array['2026-11-10 18:00+00', '2026-11-10 19:00+00']::timestamptz[],
    array['aaaaaaaa-0000-0000-0000-000000000001']::uuid[]) $$,
  'alice shares two hours with Climbing');
select lives_ok($$ select public.set_availability(
    array['2026-11-11 09:00+00']::timestamptz[],
    array['aaaaaaaa-0000-0000-0000-000000000002']::uuid[]) $$,
  'alice shares one hour with Work');
select throws_ok($$ insert into public.availability (circle_id, starts_at)
  values ('aaaaaaaa-0000-0000-0000-000000000001', '2026-11-10 18:10+00') $$,
  '23514', null, 'blocks must start on a quarter hour');

select pg_temp.login('22222222-2222-2222-2222-222222222222');
select is((select count(*) from public.availability
           where user_id = '11111111-1111-1111-1111-111111111111')::int, 2,
  'bob sees only what alice shared with Climbing');
select throws_ok($$ insert into public.availability (circle_id, starts_at)
  values ('aaaaaaaa-0000-0000-0000-000000000002', '2026-11-10 18:00+00') $$,
  '23503', null, 'cannot share availability with a circle you are not in');
select throws_ok($$ insert into public.availability (user_id, circle_id, starts_at)
  values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000001', '2026-11-12 18:00+00') $$,
  '42501', null, 'cannot write availability for someone else');

select pg_temp.login('33333333-3333-3333-3333-333333333333');
select is((select count(*) from public.availability)::int, 0, 'outsider sees no availability');

-------------------------------------------------------------- invite codes
select pg_temp.login('11111111-1111-1111-1111-111111111111');
create temp table codes as select invite_code from public.circles where id = 'aaaaaaaa-0000-0000-0000-000000000001';
grant select on codes to authenticated;

select pg_temp.login('33333333-3333-3333-3333-333333333333');
select is(public.join_circle_by_code(lower((select invite_code from codes))),
  'aaaaaaaa-0000-0000-0000-000000000001'::uuid, 'carol joins with the invite code');
select is((select count(*) from public.availability)::int, 2, 'new member sees circle availability');
select throws_ok($$ select public.regenerate_invite_code('aaaaaaaa-0000-0000-0000-000000000001') $$,
  '42501', null, 'only the owner can regenerate the code');

----------------------------------------------------------------------- plans
select lives_ok($$ insert into public.plans (id, circle_id, title, starts_at, ends_at)
  values ('bbbbbbbb-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001',
          'Bouldering', '2026-11-10 18:00+00', '2026-11-10 20:00+00') $$,
  'member proposes a plan');
select is((select status::text from public.plan_responses
           where plan_id = 'bbbbbbbb-0000-0000-0000-000000000001'), 'going',
  'proposer is going automatically');

----------------------------------------------------------- leaving a circle
select pg_temp.login('11111111-1111-1111-1111-111111111111');
delete from public.circle_members
where circle_id = 'aaaaaaaa-0000-0000-0000-000000000001'
  and user_id = '22222222-2222-2222-2222-222222222222';

select pg_temp.login('22222222-2222-2222-2222-222222222222');
select is((select count(*) from public.availability)::int, 0,
  'removed member no longer sees circle availability');

select * from finish();
rollback;
