// End-to-end flow through the app's repositories against a real Supabase.
//
// Start the local stack (`supabase start` in the repo root), then run:
//   flutter test test/integration --dart-define=DATER_INTEGRATION=true
@TestOn('vm')
library;

import 'dart:async';

import 'package:dater/core/models.dart';
import 'package:dater/core/supabase.dart';
import 'package:dater/core/week.dart';
import 'package:dater/features/availability/availability_repository.dart';
import 'package:dater/features/circles/circles_repository.dart';
import 'package:dater/features/friends/friends_repository.dart';
import 'package:dater/features/notifications/notifications_repository.dart';
import 'package:dater/features/plans/plans_repository.dart';
import 'package:dater/features/profile/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const enabled = bool.fromEnvironment('DATER_INTEGRATION');

class TestUser {
  TestUser(this.name)
    : client = SupabaseClient(
        supabaseUrl,
        supabaseKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false, authFlowType: AuthFlowType.implicit),
      );

  final String name;
  final SupabaseClient client;
  late final String id;
  late final String username;

  ProfileRepository get profiles => ProfileRepository(client);
  FriendsRepository get friends => FriendsRepository(client);
  CirclesRepository get circles => CirclesRepository(client);
  AvailabilityRepository get availability => AvailabilityRepository(client);
  PlansRepository get plans => PlansRepository(client);
  NotificationsRepository get notifications => NotificationsRepository(client);

  Future<void> signUp(String suffix) async {
    final res = await client.auth.signUp(
      email: '${name.toLowerCase()}_$suffix@test.dev',
      password: 'password123',
      data: {'display_name': name},
    );
    id = res.user!.id;
    username = '${name.toLowerCase()}_$suffix';
    await profiles.updateMine(username: username);
  }
}

void main() {
  final suffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final alice = TestUser('Alice');
  final bob = TestUser('Bob');
  final carol = TestUser('Carol');
  final week = addWeeks(weekStartOf(DateTime.now()), 1);
  late Circle climbing;
  late Circle work;

  setUpAll(() async {
    if (!enabled) return;
    await alice.signUp(suffix);
    await bob.signUp(suffix);
    await carol.signUp(suffix);
  });

  test('profiles and username search', () async {
    expect((await alice.profiles.fetchMine())!.displayName, 'Alice');
    final found = await alice.profiles.searchByUsername('bob_$suffix');
    expect(found.map((p) => p.id), [bob.id]);
    expect(() => carol.profiles.updateMine(username: alice.username), throwsA(isA<UsernameTakenException>()));
  }, skip: !enabled);

  test('friend request and accept', () async {
    await alice.friends.sendRequest(bob.username);
    final pending = await bob.friends.fetchAll();
    expect(pending.single.isIncoming(bob.id), isTrue);
    await bob.friends.accept(pending.single.id);
    expect((await alice.friends.fetchAll()).single.status, FriendshipStatus.accepted);
  }, skip: !enabled);

  test('circles: create, add friend, non-friend rejected', () async {
    climbing = await alice.circles.create(name: 'Climbing', emoji: '🧗', colorHex: '#4CAF50');
    work = await alice.circles.create(name: 'Work', emoji: '💼', colorHex: '#2196F3');
    await alice.circles.addMember(climbing.id, bob.id);
    await expectLater(alice.circles.addMember(climbing.id, carol.id), throwsA(isA<PostgrestException>()));

    final members = await bob.circles.fetchMembers(climbing.id);
    expect(members.map((m) => m.profile.id).toSet(), {alice.id, bob.id});
    expect((await bob.circles.fetchMine()).map((c) => c.id), [climbing.id]);
  }, skip: !enabled);

  test('availability is only visible to the circles it was shared with', () async {
    const tue19 = (day: 1, hour: 19);
    const tue20 = (day: 1, hour: 20);
    const wed9 = (day: 2, hour: 9);
    await alice.availability.setSlots(week, {tue19, tue20}, {climbing.id});
    await alice.availability.setSlots(week, {wed9}, {work.id, climbing.id});
    // Narrow Wednesday 9:00 to Work only.
    await alice.availability.setSlots(week, {wed9}, {work.id});

    final mine = await alice.availability.fetchMyWeek(week);
    expect(mine, {
      tue19: {climbing.id},
      tue20: {climbing.id},
      wed9: {work.id},
    });

    final bobSees = await bob.availability.fetchCircleWeek(climbing.id, week);
    expect(bobSees, {
      tue19: {alice.id},
      tue20: {alice.id},
    });
    expect(await bob.availability.fetchCircleWeek(work.id, week), isEmpty);
    expect(await carol.availability.fetchCircleWeek(climbing.id, week), isEmpty);

    await bob.availability.setSlots(week, {tue20}, {climbing.id});
    expect((await alice.availability.fetchCircleWeek(climbing.id, week))[tue20], {alice.id, bob.id});
  }, skip: !enabled);

  test('copy week keeps local hours and circles', () async {
    final next = addWeeks(week, 1);
    await alice.availability.setSlots(next, {(day: 4, hour: 12)}, {climbing.id});
    final copied = await alice.availability.copyWeek(fromWeek: week, toWeek: next);
    expect(copied, 3);
    expect(await alice.availability.fetchMyWeek(next), await alice.availability.fetchMyWeek(week));
  }, skip: !enabled);

  test('join by invite code', () async {
    await expectLater(carol.circles.joinByCode('NOPE0000'), throwsA(isA<InvalidInviteCodeException>()));
    final joined = await carol.circles.joinByCode(climbing.inviteCode.toLowerCase());
    expect(joined, climbing.id);
    expect((await carol.availability.fetchCircleWeek(climbing.id, week)).length, 2);

    final newCode = await alice.circles.regenerateInviteCode(climbing.id);
    expect(newCode, isNot(climbing.inviteCode));
    await expectLater(bob.circles.regenerateInviteCode(climbing.id), throwsA(isA<PostgrestException>()));
  }, skip: !enabled);

  test('plans and responses', () async {
    final start = slotStart(week, (day: 1, hour: 20));
    final plan = await bob.plans.create(
      circleId: climbing.id,
      title: 'Bouldering',
      startsAt: start,
      endsAt: start.add(const Duration(hours: 2)),
    );
    expect(plan.responses, {bob.id: PlanResponseStatus.going});

    await alice.plans.respond(plan.id, PlanResponseStatus.maybe);
    await alice.plans.respond(plan.id, PlanResponseStatus.going);
    await carol.plans.respond(plan.id, PlanResponseStatus.no);

    final plans = await alice.plans.fetchUpcoming(climbing.id);
    expect(plans.single.count(PlanResponseStatus.going), 2);
    expect(plans.single.count(PlanResponseStatus.no), 1);
    expect(plans.single.startsAt, start);
    expect(await alice.plans.fetchUpcoming(work.id), isEmpty);
  }, skip: !enabled);

  test('notifications: new plan and answers, live updates, read state', () async {
    final inserted = Completer<void>();
    final ready = Completer<void>();
    await alice.client.realtime.setAuth(alice.client.auth.currentSession!.accessToken);
    final channel = alice.notifications.subscribe(
      alice.id,
      () {
        if (!inserted.isCompleted) inserted.complete();
      },
      onReady: () {
        if (!ready.isCompleted) ready.complete();
      },
    );
    await ready.future.timeout(const Duration(seconds: 20));

    final start = slotStart(week, (day: 3, hour: 19));
    final plan = await carol.plans.create(
      circleId: climbing.id,
      title: 'Coffee',
      startsAt: start,
      endsAt: start.add(const Duration(hours: 1)),
    );
    await inserted.future.timeout(const Duration(seconds: 10));
    await alice.client.removeChannel(channel);

    final aliceInbox = await alice.notifications.fetchRecent();
    final proposed = aliceInbox.firstWhere((n) => n.type == NotificationType.planProposed && n.planTitle == 'Coffee');
    expect(proposed.actor.id, carol.id);
    expect(proposed.circleName, 'Climbing');
    expect(proposed.planStartsAt, start);
    expect(proposed.isRead, isFalse);
    expect(proposed.route, '/circles/${climbing.id}?tab=plans');
    expect((await carol.notifications.fetchRecent()).where((n) => n.planTitle == 'Coffee'), isEmpty);

    await alice.plans.respond(plan.id, PlanResponseStatus.maybe);
    await alice.plans.respond(plan.id, PlanResponseStatus.going);
    final answers = (await carol.notifications.fetchRecent()).where((n) => n.type == NotificationType.planResponse);
    expect(answers.map((n) => (n.actor.id, n.response)), [(alice.id, PlanResponseStatus.going)]);

    await alice.notifications.markRead([proposed.id]);
    expect((await alice.notifications.fetchRecent()).firstWhere((n) => n.id == proposed.id).isRead, isTrue);
    await carol.notifications.markRead();
    expect((await carol.notifications.fetchRecent()).where((n) => !n.isRead), isEmpty);

    await alice.notifications.registerDeviceToken(
      token: 'tok-$suffix',
      platform: 'ios',
      locale: 'tr',
      timeZone: 'Europe/Istanbul',
    );
    await alice.notifications.deleteDeviceToken('tok-$suffix');
  }, skip: !enabled);

  test('leaving a circle removes shared hours', () async {
    await bob.circles.removeMember(climbing.id, bob.id);
    final aliceSees = await alice.availability.fetchCircleWeek(climbing.id, week);
    expect(aliceSees[(day: 1, hour: 20)], {alice.id});
    expect(await bob.circles.fetchMine(), isEmpty);
  }, skip: !enabled);
}
