import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('tr')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Dater'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Share your free hours with the circles you choose.'**
  String get appTagline;

  /// No description provided for @navMyWeek.
  ///
  /// In en, this message translates to:
  /// **'My week'**
  String get navMyWeek;

  /// No description provided for @navCircles.
  ///
  /// In en, this message translates to:
  /// **'Circles'**
  String get navCircles;

  /// No description provided for @navFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get navFriends;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid e-mail address'**
  String get emailInvalid;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get haveAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get noAccount;

  /// No description provided for @authCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your e-mail to confirm your account, then sign in.'**
  String get authCheckEmail;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get displayName;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHelp.
  ///
  /// In en, this message translates to:
  /// **'3–20 characters: a–z, 0–9 and _'**
  String get usernameHelp;

  /// No description provided for @usernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 3–20 lowercase letters, digits or _'**
  String get usernameInvalid;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is taken'**
  String get usernameTaken;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your username'**
  String get onboardingTitle;

  /// No description provided for @onboardingBody.
  ///
  /// In en, this message translates to:
  /// **'Friends find and add you with your @username.'**
  String get onboardingBody;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @myWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'My week'**
  String get myWeekTitle;

  /// No description provided for @myWeekHint.
  ///
  /// In en, this message translates to:
  /// **'Tap hours to select them, or long-press and drag. Tap a day to select it all.'**
  String get myWeekHint;

  /// No description provided for @hoursSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour selected} other{{count} hours selected}}'**
  String hoursSelected(int count);

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearSelection;

  /// No description provided for @markAvailable.
  ///
  /// In en, this message translates to:
  /// **'I\'m free'**
  String get markAvailable;

  /// No description provided for @removeAvailability.
  ///
  /// In en, this message translates to:
  /// **'Remove availability'**
  String get removeAvailability;

  /// No description provided for @sharedHours.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}} shared with {circles, plural, =1{1 circle} other{{circles} circles}}'**
  String sharedHours(int hours, int circles);

  /// No description provided for @removedHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}} removed'**
  String removedHours(int count);

  /// No description provided for @copyPreviousWeek.
  ///
  /// In en, this message translates to:
  /// **'Copy last week'**
  String get copyPreviousWeek;

  /// No description provided for @copyWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy last week?'**
  String get copyWeekTitle;

  /// No description provided for @copyWeekBody.
  ///
  /// In en, this message translates to:
  /// **'Your availability for this week will be replaced with last week\'s.'**
  String get copyWeekBody;

  /// No description provided for @copyWeekAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyWeekAction;

  /// No description provided for @copyWeekDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Last week was empty} =1{Copied 1 hour} other{Copied {count} hours}}'**
  String copyWeekDone(int count);

  /// No description provided for @noCirclesTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a circle first'**
  String get noCirclesTitle;

  /// No description provided for @noCirclesBody.
  ///
  /// In en, this message translates to:
  /// **'You choose which circles can see each free hour, so you need at least one circle.'**
  String get noCirclesBody;

  /// No description provided for @pickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Who can see this?'**
  String get pickerTitle;

  /// No description provided for @pickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Share 1 free hour with:} other{Share {count} free hours with:}}'**
  String pickerSubtitle(int count);

  /// No description provided for @pickerAllCircles.
  ///
  /// In en, this message translates to:
  /// **'All circles'**
  String get pickerAllCircles;

  /// No description provided for @pickerSave.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get pickerSave;

  /// No description provided for @newCircle.
  ///
  /// In en, this message translates to:
  /// **'New circle'**
  String get newCircle;

  /// No description provided for @editCircle.
  ///
  /// In en, this message translates to:
  /// **'Edit circle'**
  String get editCircle;

  /// No description provided for @createCircle.
  ///
  /// In en, this message translates to:
  /// **'Create circle'**
  String get createCircle;

  /// No description provided for @circleName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get circleName;

  /// No description provided for @circleNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Close friends, Climbing, Work'**
  String get circleNameHint;

  /// No description provided for @circleIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get circleIcon;

  /// No description provided for @circleColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get circleColor;

  /// No description provided for @circlesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No circles yet'**
  String get circlesEmptyTitle;

  /// No description provided for @circlesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a circle for a group of friends, or join one with an invite code.'**
  String get circlesEmptyBody;

  /// No description provided for @memberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String memberCount(int count);

  /// No description provided for @youOwn.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get youOwn;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @youSuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String youSuffix(String name);

  /// No description provided for @joinWithCode.
  ///
  /// In en, this message translates to:
  /// **'Join with code'**
  String get joinWithCode;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// No description provided for @inviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'This invite code is not valid anymore.'**
  String get inviteInvalid;

  /// No description provided for @backToCircles.
  ///
  /// In en, this message translates to:
  /// **'Back to circles'**
  String get backToCircles;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite to {name}'**
  String inviteTitle(String name);

  /// No description provided for @inviteBody.
  ///
  /// In en, this message translates to:
  /// **'Anyone with this code or link can join the circle.'**
  String get inviteBody;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get shareLink;

  /// No description provided for @inviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Join my circle \"{name}\" on Dater: {link} (code: {code})'**
  String inviteShareText(String name, String link, String code);

  /// No description provided for @inviteWithLink.
  ///
  /// In en, this message translates to:
  /// **'Invite with a link'**
  String get inviteWithLink;

  /// No description provided for @inviteWithLinkBody.
  ///
  /// In en, this message translates to:
  /// **'Share the invite code with anyone'**
  String get inviteWithLinkBody;

  /// No description provided for @addFriendToCircle.
  ///
  /// In en, this message translates to:
  /// **'Add a friend'**
  String get addFriendToCircle;

  /// No description provided for @noFriendsToAdd.
  ///
  /// In en, this message translates to:
  /// **'All your friends are already in this circle.'**
  String get noFriendsToAdd;

  /// No description provided for @removeMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the circle?'**
  String removeMemberTitle(String name);

  /// No description provided for @regenerateCode.
  ///
  /// In en, this message translates to:
  /// **'New invite code'**
  String get regenerateCode;

  /// No description provided for @regenerateCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new invite code?'**
  String get regenerateCodeTitle;

  /// No description provided for @regenerateCodeBody.
  ///
  /// In en, this message translates to:
  /// **'The old code and links will stop working.'**
  String get regenerateCodeBody;

  /// No description provided for @leaveCircle.
  ///
  /// In en, this message translates to:
  /// **'Leave circle'**
  String get leaveCircle;

  /// No description provided for @leaveCircleTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave {name}?'**
  String leaveCircleTitle(String name);

  /// No description provided for @leaveCircleBody.
  ///
  /// In en, this message translates to:
  /// **'The hours you shared with this circle will be removed.'**
  String get leaveCircleBody;

  /// No description provided for @deleteCircle.
  ///
  /// In en, this message translates to:
  /// **'Delete circle'**
  String get deleteCircle;

  /// No description provided for @deleteCircleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteCircleTitle(String name);

  /// No description provided for @deleteCircleBody.
  ///
  /// In en, this message translates to:
  /// **'Members, shared hours and plans of this circle will be deleted.'**
  String get deleteCircleBody;

  /// No description provided for @tabWeek.
  ///
  /// In en, this message translates to:
  /// **'Free times'**
  String get tabWeek;

  /// No description provided for @tabPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get tabPlans;

  /// No description provided for @tabMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get tabMembers;

  /// No description provided for @heatmapHint.
  ///
  /// In en, this message translates to:
  /// **'Numbers show how many members are free. Tap an hour to see who and propose a plan.'**
  String get heatmapHint;

  /// No description provided for @freeCount.
  ///
  /// In en, this message translates to:
  /// **'{free} of {total} free'**
  String freeCount(int free, int total);

  /// No description provided for @nobodyFree.
  ///
  /// In en, this message translates to:
  /// **'Nobody has shared this hour yet.'**
  String get nobodyFree;

  /// No description provided for @proposePlan.
  ///
  /// In en, this message translates to:
  /// **'Propose a plan'**
  String get proposePlan;

  /// No description provided for @proposePlanAction.
  ///
  /// In en, this message translates to:
  /// **'Propose'**
  String get proposePlanAction;

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s the plan?'**
  String get planTitle;

  /// No description provided for @planTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Coffee, Movie night'**
  String get planTitleHint;

  /// No description provided for @planNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get planNote;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get endTime;

  /// No description provided for @plansEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No plans yet'**
  String get plansEmptyTitle;

  /// No description provided for @plansEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap a free hour on the Free times tab to propose one.'**
  String get plansEmptyBody;

  /// No description provided for @proposedBy.
  ///
  /// In en, this message translates to:
  /// **'Proposed by {name}'**
  String proposedBy(String name);

  /// No description provided for @planCounts.
  ///
  /// In en, this message translates to:
  /// **'{going} going · {maybe} maybe · {no} can\'t'**
  String planCounts(int going, int maybe, int no);

  /// No description provided for @going.
  ///
  /// In en, this message translates to:
  /// **'Going'**
  String get going;

  /// No description provided for @maybe.
  ///
  /// In en, this message translates to:
  /// **'Maybe'**
  String get maybe;

  /// No description provided for @notGoing.
  ///
  /// In en, this message translates to:
  /// **'Can\'t'**
  String get notGoing;

  /// No description provided for @deletePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this plan?'**
  String get deletePlanTitle;

  /// No description provided for @searchUsername.
  ///
  /// In en, this message translates to:
  /// **'Search by @username'**
  String get searchUsername;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @addFriend.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addFriend;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent'**
  String get requestSent;

  /// No description provided for @requestPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get requestPending;

  /// No description provided for @friendsLabel.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsLabel;

  /// No description provided for @incomingRequests.
  ///
  /// In en, this message translates to:
  /// **'Friend requests'**
  String get incomingRequests;

  /// No description provided for @sentRequests.
  ///
  /// In en, this message translates to:
  /// **'Sent requests'**
  String get sentRequests;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelRequest;

  /// No description provided for @friendsCount.
  ///
  /// In en, this message translates to:
  /// **'Friends ({count})'**
  String friendsCount(int count);

  /// No description provided for @friendsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Search for friends by their username above.'**
  String get friendsEmpty;

  /// No description provided for @unfriend.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get unfriend;

  /// No description provided for @unfriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from friends?'**
  String unfriendTitle(String name);

  /// No description provided for @unfriendBody.
  ///
  /// In en, this message translates to:
  /// **'You stay together in circles you already share.'**
  String get unfriendBody;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageSystem;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
