import 'package:flutter/material.dart';

/// A user's public profile.
class Profile {
  const Profile({required this.id, required this.username, required this.displayName, this.avatarUrl});

  final String id;

  /// Null until the user finishes onboarding.
  final String? username;
  final String displayName;
  final String? avatarUrl;

  /// The best name to show for this person.
  String get label => displayName.isNotEmpty ? displayName : '@${username ?? '?'}';

  String get initials {
    final source = label.replaceFirst('@', '').trim();
    return source.isEmpty ? '?' : source.characters.first.toUpperCase();
  }

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    username: json['username'] as String?,
    displayName: (json['display_name'] as String?) ?? '',
    avatarUrl: json['avatar_url'] as String?,
  );
}

enum FriendshipStatus { pending, accepted }

class Friendship {
  const Friendship({required this.id, required this.requester, required this.addressee, required this.status});

  final String id;
  final Profile requester;
  final Profile addressee;
  final FriendshipStatus status;

  /// The person on the other side of this friendship, seen from [myId].
  Profile other(String myId) => requester.id == myId ? addressee : requester;

  bool isIncoming(String myId) => status == FriendshipStatus.pending && addressee.id == myId;
  bool isOutgoing(String myId) => status == FriendshipStatus.pending && requester.id == myId;

  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
    id: json['id'] as String,
    requester: Profile.fromJson(json['requester'] as Map<String, dynamic>),
    addressee: Profile.fromJson(json['addressee'] as Map<String, dynamic>),
    status: FriendshipStatus.values.byName(json['status'] as String),
  );
}

class Circle {
  const Circle({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.emoji,
    required this.colorHex,
    required this.inviteCode,
    this.memberCount,
  });

  final String id;
  final String ownerId;
  final String name;
  final String emoji;
  final String colorHex;
  final String inviteCode;
  final int? memberCount;

  Color get color => colorFromHex(colorHex);

  factory Circle.fromJson(Map<String, dynamic> json) {
    final members = json['circle_members'];
    int? count;
    if (members is List && members.isNotEmpty && members.first is Map) {
      count = (members.first as Map)['count'] as int?;
    }
    return Circle(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      colorHex: json['color'] as String,
      inviteCode: json['invite_code'] as String,
      memberCount: count,
    );
  }
}

enum CircleRole { owner, member }

class CircleMember {
  const CircleMember({required this.profile, required this.role});

  final Profile profile;
  final CircleRole role;

  factory CircleMember.fromJson(Map<String, dynamic> json) => CircleMember(
    profile: Profile.fromJson(json['profiles'] as Map<String, dynamic>),
    role: CircleRole.values.byName(json['role'] as String),
  );
}

enum PlanResponseStatus { going, maybe, no }

class Plan {
  const Plan({
    required this.id,
    required this.circleId,
    required this.createdBy,
    required this.title,
    required this.note,
    required this.startsAt,
    required this.endsAt,
    required this.responses,
  });

  final String id;
  final String circleId;
  final String createdBy;
  final String title;
  final String? note;

  /// Local time.
  final DateTime startsAt;

  /// Local time.
  final DateTime endsAt;

  /// user id -> response.
  final Map<String, PlanResponseStatus> responses;

  int count(PlanResponseStatus status) => responses.values.where((s) => s == status).length;

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    id: json['id'] as String,
    circleId: json['circle_id'] as String,
    createdBy: json['created_by'] as String,
    title: json['title'] as String,
    note: json['note'] as String?,
    startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
    endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
    responses: {
      for (final r in (json['plan_responses'] as List? ?? const []))
        (r as Map)['user_id'] as String: PlanResponseStatus.values.byName(r['status'] as String),
    },
  );
}

Color colorFromHex(String hex) {
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16) ?? 0x4CAF50;
  return Color(0xFF000000 | value);
}

String colorToHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Colors offered when creating a circle.
const circleColorChoices = <Color>[
  Color(0xFF4CAF50),
  Color(0xFF2196F3),
  Color(0xFFFF9800),
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
  Color(0xFF009688),
  Color(0xFFF44336),
  Color(0xFF795548),
];

/// Emoji offered when creating a circle.
const circleEmojiChoices = ['👥', '🏠', '💼', '🎉', '⚽', '🎮', '☕', '🍻', '🎓', '❤️', '🧗', '🎵'];

enum NotificationType {
  planProposed('plan_proposed'),
  planResponse('plan_response');

  const NotificationType(this.dbValue);
  final String dbValue;

  static NotificationType fromDb(String value) => values.firstWhere((t) => t.dbValue == value);
}

/// An entry in the in-app notification inbox.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.actor,
    required this.circleId,
    required this.circleName,
    required this.circleEmoji,
    required this.planTitle,
    required this.planStartsAt,
    required this.response,
    required this.createdAt,
    required this.readAt,
  });

  final String id;
  final NotificationType type;
  final Profile actor;
  final String circleId;
  final String circleName;
  final String circleEmoji;
  final String planTitle;

  /// Local time.
  final DateTime planStartsAt;
  final PlanResponseStatus? response;

  /// Local time.
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  /// Where tapping the notification leads.
  String get route => '/circles/$circleId?tab=plans';

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final circle = json['circle'] as Map<String, dynamic>;
    final plan = json['plan'] as Map<String, dynamic>;
    final response = json['response'] as String?;
    final readAt = json['read_at'] as String?;
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.fromDb(json['type'] as String),
      actor: Profile.fromJson(json['actor'] as Map<String, dynamic>),
      circleId: json['circle_id'] as String,
      circleName: circle['name'] as String,
      circleEmoji: circle['emoji'] as String,
      planTitle: plan['title'] as String,
      planStartsAt: DateTime.parse(plan['starts_at'] as String).toLocal(),
      response: response == null ? null : PlanResponseStatus.values.byName(response),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      readAt: readAt == null ? null : DateTime.parse(readAt).toLocal(),
    );
  }
}
