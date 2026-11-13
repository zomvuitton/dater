// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dater';

  @override
  String get appTagline => 'Share your free hours with the circles you choose.';

  @override
  String get navMyWeek => 'My week';

  @override
  String get navCircles => 'Circles';

  @override
  String get navFriends => 'Friends';

  @override
  String get navProfile => 'Profile';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get retry => 'Try again';

  @override
  String get join => 'Join';

  @override
  String get copied => 'Copied';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get fieldRequired => 'Required';

  @override
  String get email => 'E-mail';

  @override
  String get emailInvalid => 'Enter a valid e-mail address';

  @override
  String get password => 'Password';

  @override
  String get passwordTooShort => 'At least 6 characters';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get signOut => 'Sign out';

  @override
  String get haveAccount => 'Already have an account? Sign in';

  @override
  String get noAccount => 'New here? Create an account';

  @override
  String get authCheckEmail => 'Check your e-mail to confirm your account, then sign in.';

  @override
  String get displayName => 'Name';

  @override
  String get username => 'Username';

  @override
  String get usernameHelp => '3–20 characters: a–z, 0–9 and _';

  @override
  String get usernameInvalid => 'Use 3–20 lowercase letters, digits or _';

  @override
  String get usernameTaken => 'This username is taken';

  @override
  String get onboardingTitle => 'Pick your username';

  @override
  String get onboardingBody => 'Friends find and add you with your @username.';

  @override
  String get continueAction => 'Continue';

  @override
  String get myWeekTitle => 'My week';

  @override
  String get myWeekHint => 'Tap hours to select them, or long-press and drag. Tap a day to select it all.';

  @override
  String hoursSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours selected',
      one: '1 hour selected',
    );
    return '$_temp0';
  }

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get markAvailable => 'I\'m free';

  @override
  String get removeAvailability => 'Remove availability';

  @override
  String sharedHours(int hours, int circles) {
    String _temp0 = intl.Intl.pluralLogic(hours, locale: localeName, other: '$hours hours', one: '1 hour');
    String _temp1 = intl.Intl.pluralLogic(circles, locale: localeName, other: '$circles circles', one: '1 circle');
    return '$_temp0 shared with $_temp1';
  }

  @override
  String removedHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count hours', one: '1 hour');
    return '$_temp0 removed';
  }

  @override
  String get copyPreviousWeek => 'Copy last week';

  @override
  String get copyWeekTitle => 'Copy last week?';

  @override
  String get copyWeekBody => 'Your availability for this week will be replaced with last week\'s.';

  @override
  String get copyWeekAction => 'Copy';

  @override
  String copyWeekDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copied $count hours',
      one: 'Copied 1 hour',
      zero: 'Last week was empty',
    );
    return '$_temp0';
  }

  @override
  String get noCirclesTitle => 'Create a circle first';

  @override
  String get noCirclesBody => 'You choose which circles can see each free hour, so you need at least one circle.';

  @override
  String get pickerTitle => 'Who can see this?';

  @override
  String pickerSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Share $count free hours with:',
      one: 'Share 1 free hour with:',
    );
    return '$_temp0';
  }

  @override
  String get pickerAllCircles => 'All circles';

  @override
  String get pickerSave => 'Share';

  @override
  String get newCircle => 'New circle';

  @override
  String get editCircle => 'Edit circle';

  @override
  String get createCircle => 'Create circle';

  @override
  String get circleName => 'Name';

  @override
  String get circleNameHint => 'e.g. Close friends, Climbing, Work';

  @override
  String get circleIcon => 'Icon';

  @override
  String get circleColor => 'Color';

  @override
  String get circlesEmptyTitle => 'No circles yet';

  @override
  String get circlesEmptyBody => 'Create a circle for a group of friends, or join one with an invite code.';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count members', one: '1 member');
    return '$_temp0';
  }

  @override
  String get youOwn => 'Yours';

  @override
  String get owner => 'Owner';

  @override
  String youSuffix(String name) {
    return '$name (you)';
  }

  @override
  String get joinWithCode => 'Join with code';

  @override
  String get inviteCode => 'Invite code';

  @override
  String get inviteInvalid => 'This invite code is not valid anymore.';

  @override
  String get backToCircles => 'Back to circles';

  @override
  String get invite => 'Invite';

  @override
  String inviteTitle(String name) {
    return 'Invite to $name';
  }

  @override
  String get inviteBody => 'Anyone with this code or link can join the circle.';

  @override
  String get copyCode => 'Copy code';

  @override
  String get shareLink => 'Share link';

  @override
  String inviteShareText(String name, String link, String code) {
    return 'Join my circle \"$name\" on Dater: $link (code: $code)';
  }

  @override
  String get inviteWithLink => 'Invite with a link';

  @override
  String get inviteWithLinkBody => 'Share the invite code with anyone';

  @override
  String get addFriendToCircle => 'Add a friend';

  @override
  String get noFriendsToAdd => 'All your friends are already in this circle.';

  @override
  String removeMemberTitle(String name) {
    return 'Remove $name from the circle?';
  }

  @override
  String get regenerateCode => 'New invite code';

  @override
  String get regenerateCodeTitle => 'Create a new invite code?';

  @override
  String get regenerateCodeBody => 'The old code and links will stop working.';

  @override
  String get leaveCircle => 'Leave circle';

  @override
  String leaveCircleTitle(String name) {
    return 'Leave $name?';
  }

  @override
  String get leaveCircleBody => 'The hours you shared with this circle will be removed.';

  @override
  String get deleteCircle => 'Delete circle';

  @override
  String deleteCircleTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteCircleBody => 'Members, shared hours and plans of this circle will be deleted.';

  @override
  String get tabWeek => 'Free times';

  @override
  String get tabPlans => 'Plans';

  @override
  String get tabMembers => 'Members';

  @override
  String get heatmapHint => 'Numbers show how many members are free. Tap an hour to see who and propose a plan.';

  @override
  String freeCount(int free, int total) {
    return '$free of $total free';
  }

  @override
  String get nobodyFree => 'Nobody has shared this hour yet.';

  @override
  String get proposePlan => 'Propose a plan';

  @override
  String get proposePlanAction => 'Propose';

  @override
  String get planTitle => 'What\'s the plan?';

  @override
  String get planTitleHint => 'e.g. Coffee, Movie night';

  @override
  String get planNote => 'Note (optional)';

  @override
  String get startTime => 'Start time';

  @override
  String get endTime => 'End time';

  @override
  String get plansEmptyTitle => 'No plans yet';

  @override
  String get plansEmptyBody => 'Tap a free hour on the Free times tab to propose one.';

  @override
  String proposedBy(String name) {
    return 'Proposed by $name';
  }

  @override
  String planCounts(int going, int maybe, int no) {
    return '$going going · $maybe maybe · $no can\'t';
  }

  @override
  String get going => 'Going';

  @override
  String get maybe => 'Maybe';

  @override
  String get notGoing => 'Can\'t';

  @override
  String get deletePlanTitle => 'Delete this plan?';

  @override
  String get searchUsername => 'Search by @username';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get addFriend => 'Add';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get requestSent => 'Friend request sent';

  @override
  String get requestPending => 'Pending';

  @override
  String get friendsLabel => 'Friends';

  @override
  String get incomingRequests => 'Friend requests';

  @override
  String get sentRequests => 'Sent requests';

  @override
  String get cancelRequest => 'Cancel';

  @override
  String friendsCount(int count) {
    return 'Friends ($count)';
  }

  @override
  String get friendsEmpty => 'Search for friends by their username above.';

  @override
  String get unfriend => 'Remove friend';

  @override
  String unfriendTitle(String name) {
    return 'Remove $name from friends?';
  }

  @override
  String get unfriendBody => 'You stay together in circles you already share.';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Device language';

  @override
  String get open => 'Open';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get notificationsEmptyTitle => 'No notifications yet';

  @override
  String get notificationsEmptyBody => 'You\'ll see new plans in your circles and answers to your plans here.';

  @override
  String notifPlanProposed(String name, String title) {
    return '$name proposed a plan: $title';
  }

  @override
  String notifPlanGoing(String name, String title) {
    return '$name is going to “$title”';
  }

  @override
  String notifPlanMaybe(String name, String title) {
    return '$name might join “$title”';
  }

  @override
  String notifPlanNo(String name, String title) {
    return '$name can\'t make it to “$title”';
  }

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count h ago';
  }
}
