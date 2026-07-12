import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Riyada'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Book your field in Nineveh'**
  String get appTagline;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get register;

  /// No description provided for @registerUser.
  ///
  /// In en, this message translates to:
  /// **'User registration'**
  String get registerUser;

  /// No description provided for @registerOwner.
  ///
  /// In en, this message translates to:
  /// **'Field owner registration'**
  String get registerOwner;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @darkModeOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get darkModeOn;

  /// No description provided for @darkModeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get darkModeOff;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageAr.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageAr;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutApp;

  /// No description provided for @aboutAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Riyada — field booking in Nineveh\nVersion 1.0.0'**
  String get aboutAppSubtitle;

  /// No description provided for @devMode.
  ///
  /// In en, this message translates to:
  /// **'Developer mode'**
  String get devMode;

  /// No description provided for @devModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Server settings (developers)'**
  String get devModeSubtitle;

  /// No description provided for @apiHostLabel.
  ///
  /// In en, this message translates to:
  /// **'Computer IP address'**
  String get apiHostLabel;

  /// No description provided for @apiHostHint.
  ///
  /// In en, this message translates to:
  /// **'192.168.1.10'**
  String get apiHostHint;

  /// No description provided for @apiHostEmpty.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for automatic setup'**
  String get apiHostEmpty;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading data…'**
  String get loadingData;

  /// No description provided for @loadingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Loading dashboard…'**
  String get loadingDashboard;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phone;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @provinceNineveh.
  ///
  /// In en, this message translates to:
  /// **'Nineveh'**
  String get provinceNineveh;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @loginAsUser.
  ///
  /// In en, this message translates to:
  /// **'User log in'**
  String get loginAsUser;

  /// No description provided for @loginAsOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner log in'**
  String get loginAsOwner;

  /// No description provided for @loginUserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book fields and manage your bookings'**
  String get loginUserSubtitle;

  /// No description provided for @loginOwnerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your field and booking requests'**
  String get loginOwnerSubtitle;

  /// No description provided for @useUserLoginInstead.
  ///
  /// In en, this message translates to:
  /// **'This is a user account — use user log in'**
  String get useUserLoginInstead;

  /// No description provided for @useOwnerLoginInstead.
  ///
  /// In en, this message translates to:
  /// **'This is an owner account — use owner log in'**
  String get useOwnerLoginInstead;

  /// No description provided for @goToUserRegister.
  ///
  /// In en, this message translates to:
  /// **'Create user account'**
  String get goToUserRegister;

  /// No description provided for @goToOwnerRegister.
  ///
  /// In en, this message translates to:
  /// **'Create owner account'**
  String get goToOwnerRegister;

  /// No description provided for @goToUserLogin.
  ///
  /// In en, this message translates to:
  /// **'I have a user account — log in'**
  String get goToUserLogin;

  /// No description provided for @goToOwnerLogin.
  ///
  /// In en, this message translates to:
  /// **'I have an owner account — log in'**
  String get goToOwnerLogin;

  /// No description provided for @emailExactHint.
  ///
  /// In en, this message translates to:
  /// **'Each email is unique — even if both end with @gmail.com'**
  String get emailExactHint;

  /// No description provided for @demoAccounts.
  ///
  /// In en, this message translates to:
  /// **'Demo accounts'**
  String get demoAccounts;

  /// No description provided for @demoOwner.
  ///
  /// In en, this message translates to:
  /// **'Field owner'**
  String get demoOwner;

  /// No description provided for @demoUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get demoUser;

  /// No description provided for @createAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'Create account & sign in'**
  String get createAccountLogin;

  /// No description provided for @addProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add profile photo (optional)'**
  String get addProfilePhoto;

  /// No description provided for @createOwnerAccount.
  ///
  /// In en, this message translates to:
  /// **'Create field account'**
  String get createOwnerAccount;

  /// No description provided for @fields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get fields;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get myBookings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @searchFields.
  ///
  /// In en, this message translates to:
  /// **'Search for a field…'**
  String get searchFields;

  /// No description provided for @noFields.
  ///
  /// In en, this message translates to:
  /// **'No fields found'**
  String get noFields;

  /// No description provided for @noFieldsHint.
  ///
  /// In en, this message translates to:
  /// **'Try changing your search terms'**
  String get noFieldsHint;

  /// No description provided for @noBookings.
  ///
  /// In en, this message translates to:
  /// **'No bookings'**
  String get noBookings;

  /// No description provided for @noBookingsHint.
  ///
  /// In en, this message translates to:
  /// **'Book your first field from the Fields tab'**
  String get noBookingsHint;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @sortDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get sortDefault;

  /// No description provided for @sortPriceAsc.
  ///
  /// In en, this message translates to:
  /// **'Price ↑'**
  String get sortPriceAsc;

  /// No description provided for @sortPriceDesc.
  ///
  /// In en, this message translates to:
  /// **'Price ↓'**
  String get sortPriceDesc;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelBooking;

  /// No description provided for @cancelBookingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking?'**
  String get cancelBookingConfirm;

  /// No description provided for @cancelWindowError.
  ///
  /// In en, this message translates to:
  /// **'Cannot cancel after the booking time or for inactive bookings'**
  String get cancelWindowError;

  /// No description provided for @cancelWindowHint.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation if more than 24 hours remain'**
  String get cancelWindowHint;

  /// No description provided for @cancelLatePenaltyHint.
  ///
  /// In en, this message translates to:
  /// **'Cancelling within 12 hours incurs a 5,000 IQD fee'**
  String get cancelLatePenaltyHint;

  /// No description provided for @cancelLatePenaltyConfirm.
  ///
  /// In en, this message translates to:
  /// **'A 5,000 IQD fee will apply: 2,500 to the field owner and 2,500 to the platform. Continue?'**
  String get cancelLatePenaltyConfirm;

  /// No description provided for @cancelSuccessWithPenalty.
  ///
  /// In en, this message translates to:
  /// **'Cancelled — 5,000 IQD fee applied'**
  String get cancelSuccessWithPenalty;

  /// No description provided for @accountRestrictedError.
  ///
  /// In en, this message translates to:
  /// **'Account restricted due to excessive cancellations.'**
  String get accountRestrictedError;

  /// No description provided for @bookingInvalidHours.
  ///
  /// In en, this message translates to:
  /// **'Booking duration must be between 1 and 2 hours'**
  String get bookingInvalidHours;

  /// No description provided for @bookingOutsideHours.
  ///
  /// In en, this message translates to:
  /// **'Operating hours: 9:00 AM – 12:00 AM'**
  String get bookingOutsideHours;

  /// No description provided for @bookingPastTime.
  ///
  /// In en, this message translates to:
  /// **'Cannot book a time in the past'**
  String get bookingPastTime;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get yesCancel;

  /// No description provided for @rejectBooking.
  ///
  /// In en, this message translates to:
  /// **'Reject booking'**
  String get rejectBooking;

  /// No description provided for @rejectBookingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this booking?'**
  String get rejectBookingConfirm;

  /// No description provided for @yesReject.
  ///
  /// In en, this message translates to:
  /// **'Yes, reject'**
  String get yesReject;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get approved;

  /// No description provided for @noOwnerBookings.
  ///
  /// In en, this message translates to:
  /// **'No bookings'**
  String get noOwnerBookings;

  /// No description provided for @noOwnerBookingsHint.
  ///
  /// In en, this message translates to:
  /// **'Booking requests will appear here'**
  String get noOwnerBookingsHint;

  /// No description provided for @connectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost. Please check your internet and try again.'**
  String get connectionLost;

  /// No description provided for @insufficientWalletBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance to cover commission. Please top up.'**
  String get insufficientWalletBalance;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get confirmBooking;

  /// No description provided for @confirmAndSend.
  ///
  /// In en, this message translates to:
  /// **'Confirm & send'**
  String get confirmAndSend;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String hours(int count);

  /// No description provided for @commissionNote.
  ///
  /// In en, this message translates to:
  /// **'A 10% platform commission on (price per hour × hours booked) applies when the owner confirms'**
  String get commissionNote;

  /// No description provided for @platformCommissionRate.
  ///
  /// In en, this message translates to:
  /// **'10% of field price per booked hour'**
  String get platformCommissionRate;

  /// No description provided for @bookingSent.
  ///
  /// In en, this message translates to:
  /// **'Booking submitted — waiting for the owner to approve'**
  String get bookingSent;

  /// No description provided for @bookingSentRef.
  ///
  /// In en, this message translates to:
  /// **'Waiting for owner approval — reference: {code}'**
  String bookingSentRef(String code);

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Choose booking time'**
  String get selectTime;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @noSlots.
  ///
  /// In en, this message translates to:
  /// **'No available times'**
  String get noSlots;

  /// No description provided for @noSlotsHint.
  ///
  /// In en, this message translates to:
  /// **'Try later or pull to refresh'**
  String get noSlotsHint;

  /// No description provided for @tapToCall.
  ///
  /// In en, this message translates to:
  /// **'Tap to call'**
  String get tapToCall;

  /// No description provided for @perHour.
  ///
  /// In en, this message translates to:
  /// **'/hour'**
  String get perHour;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @newPasswordOptional.
  ///
  /// In en, this message translates to:
  /// **'New password (optional)'**
  String get newPasswordOptional;

  /// No description provided for @yourField.
  ///
  /// In en, this message translates to:
  /// **'Your field'**
  String get yourField;

  /// No description provided for @saveField.
  ///
  /// In en, this message translates to:
  /// **'Save field'**
  String get saveField;

  /// No description provided for @addNewField.
  ///
  /// In en, this message translates to:
  /// **'Add new field'**
  String get addNewField;

  /// No description provided for @fieldAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Field added — visible to users now'**
  String get fieldAddedSuccess;

  /// No description provided for @fieldUpdated.
  ///
  /// In en, this message translates to:
  /// **'Field updated'**
  String get fieldUpdated;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @passwordStrength.
  ///
  /// In en, this message translates to:
  /// **'Password strength: {level}'**
  String passwordStrength(String level);

  /// No description provided for @strengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get strengthWeak;

  /// No description provided for @strengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get strengthFair;

  /// No description provided for @strengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get strengthGood;

  /// No description provided for @strengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strengthStrong;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hidePassword;

  /// No description provided for @copyReference.
  ///
  /// In en, this message translates to:
  /// **'Copy reference'**
  String get copyReference;

  /// No description provided for @referenceCopied.
  ///
  /// In en, this message translates to:
  /// **'Reference copied'**
  String get referenceCopied;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortBy;

  /// No description provided for @netRevenue.
  ///
  /// In en, this message translates to:
  /// **'Net revenue'**
  String get netRevenue;

  /// No description provided for @financialSummary.
  ///
  /// In en, this message translates to:
  /// **'Financial summary'**
  String get financialSummary;

  /// No description provided for @totalBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get totalBookings;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waiting;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String hello(String name);

  /// No description provided for @taglineLong.
  ///
  /// In en, this message translates to:
  /// **'Book your field in Nineveh with ease'**
  String get taglineLong;

  /// No description provided for @startNow.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get startNow;

  /// No description provided for @chooseAccountType.
  ///
  /// In en, this message translates to:
  /// **'Choose your account type to continue'**
  String get chooseAccountType;

  /// No description provided for @registerUserCta.
  ///
  /// In en, this message translates to:
  /// **'User — book a field'**
  String get registerUserCta;

  /// No description provided for @registerOwnerCta.
  ///
  /// In en, this message translates to:
  /// **'Field owner — manage bookings'**
  String get registerOwnerCta;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account — log in'**
  String get alreadyHaveAccount;

  /// No description provided for @featureInstant.
  ///
  /// In en, this message translates to:
  /// **'Instant booking'**
  String get featureInstant;

  /// No description provided for @featureNotify.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get featureNotify;

  /// No description provided for @featureTrusted.
  ///
  /// In en, this message translates to:
  /// **'Trusted'**
  String get featureTrusted;

  /// No description provided for @onboardSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardSkip;

  /// No description provided for @onboardNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardNext;

  /// No description provided for @onboardStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardStart;

  /// No description provided for @onboardTitle1.
  ///
  /// In en, this message translates to:
  /// **'Discover the best fields'**
  String get onboardTitle1;

  /// No description provided for @onboardBody1.
  ///
  /// In en, this message translates to:
  /// **'Browse Nineveh fields with clear prices, photos, and full details for every venue.'**
  String get onboardBody1;

  /// No description provided for @onboardTitle2.
  ///
  /// In en, this message translates to:
  /// **'Book in seconds'**
  String get onboardTitle2;

  /// No description provided for @onboardBody2.
  ///
  /// In en, this message translates to:
  /// **'Pick your time, book 1–2 hours, and send your request instantly to the field owner.'**
  String get onboardBody2;

  /// No description provided for @onboardTitle3.
  ///
  /// In en, this message translates to:
  /// **'Stay updated in real time'**
  String get onboardTitle3;

  /// No description provided for @onboardBody3.
  ///
  /// In en, this message translates to:
  /// **'Instant notifications on approval or rejection, and track all bookings in one place.'**
  String get onboardBody3;

  /// No description provided for @browseFields.
  ///
  /// In en, this message translates to:
  /// **'Browse fields'**
  String get browseFields;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @pricePerHourLine.
  ///
  /// In en, this message translates to:
  /// **'Price per hour'**
  String get pricePerHourLine;

  /// No description provided for @payAtField.
  ///
  /// In en, this message translates to:
  /// **'Pay at the field'**
  String get payAtField;

  /// No description provided for @bookingSummary.
  ///
  /// In en, this message translates to:
  /// **'Booking summary'**
  String get bookingSummary;

  /// No description provided for @devModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Developer mode enabled'**
  String get devModeEnabled;

  /// No description provided for @serverSaved.
  ///
  /// In en, this message translates to:
  /// **'Server settings saved'**
  String get serverSaved;

  /// No description provided for @stopDevMode.
  ///
  /// In en, this message translates to:
  /// **'Disable developer mode'**
  String get stopDevMode;

  /// No description provided for @statusPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get statusPendingApproval;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @labelField.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get labelField;

  /// No description provided for @labelDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get labelDateTime;

  /// No description provided for @labelDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get labelDuration;

  /// No description provided for @labelAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get labelAmount;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand total'**
  String get grandTotal;

  /// No description provided for @appCommission.
  ///
  /// In en, this message translates to:
  /// **'App commission'**
  String get appCommission;

  /// No description provided for @markAllReadCount.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read ({count})'**
  String markAllReadCount(int count);

  /// No description provided for @toggleLanguage.
  ///
  /// In en, this message translates to:
  /// **'Switch language'**
  String get toggleLanguage;

  /// No description provided for @languageSwitched.
  ///
  /// In en, this message translates to:
  /// **'Switched to {language}'**
  String languageSwitched(String language);

  /// No description provided for @rtTitleNewBooking.
  ///
  /// In en, this message translates to:
  /// **'New booking request'**
  String get rtTitleNewBooking;

  /// No description provided for @rtMsgNewBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking from {userName} — {dateTime} — {referenceCode}'**
  String rtMsgNewBooking(String userName, String dateTime, String referenceCode);

  /// No description provided for @rtTitleBookingPending.
  ///
  /// In en, this message translates to:
  /// **'Your request is pending'**
  String get rtTitleBookingPending;

  /// No description provided for @rtMsgBookingPending.
  ///
  /// In en, this message translates to:
  /// **'Booking request sent — {referenceCode}'**
  String rtMsgBookingPending(String referenceCode);

  /// No description provided for @rtTitleBookingApproved.
  ///
  /// In en, this message translates to:
  /// **'Booking approved'**
  String get rtTitleBookingApproved;

  /// No description provided for @rtMsgBookingApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved — {fieldName} — {referenceCode}'**
  String rtMsgBookingApproved(String fieldName, String referenceCode);

  /// No description provided for @rtTitleBookingRejected.
  ///
  /// In en, this message translates to:
  /// **'Booking rejected'**
  String get rtTitleBookingRejected;

  /// No description provided for @rtMsgBookingRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected — {fieldName}'**
  String rtMsgBookingRejected(String fieldName);

  /// No description provided for @rtTitleBookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get rtTitleBookingCancelled;

  /// No description provided for @rtMsgBookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled {dateTime} — {fieldName}'**
  String rtMsgBookingCancelled(String dateTime, String fieldName);

  /// No description provided for @rtLiveConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to live updates'**
  String get rtLiveConnected;

  /// No description provided for @rtLiveReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get rtLiveReconnecting;

  /// No description provided for @slotUnderSelection.
  ///
  /// In en, this message translates to:
  /// **'Being booked now…'**
  String get slotUnderSelection;

  /// No description provided for @slotJustBooked.
  ///
  /// In en, this message translates to:
  /// **'Sorry, this slot was just booked by another user'**
  String get slotJustBooked;

  /// No description provided for @slotLockExpired.
  ///
  /// In en, this message translates to:
  /// **'Selection expired — please choose another time'**
  String get slotLockExpired;

  /// No description provided for @ownerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Owner dashboard'**
  String get ownerDashboard;

  /// No description provided for @bookingApprovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Booking approved'**
  String get bookingApprovedSnack;

  /// No description provided for @bookingRejectedSnack.
  ///
  /// In en, this message translates to:
  /// **'Booking rejected'**
  String get bookingRejectedSnack;

  /// No description provided for @pendingBookingsAlert.
  ///
  /// In en, this message translates to:
  /// **'You have {count} bookings awaiting approval'**
  String pendingBookingsAlert(int count);

  /// No description provided for @yourInfo.
  ///
  /// In en, this message translates to:
  /// **'Your information'**
  String get yourInfo;

  /// No description provided for @fieldInfo.
  ///
  /// In en, this message translates to:
  /// **'Field information'**
  String get fieldInfo;

  /// No description provided for @fieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Field name'**
  String get fieldNameLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @fieldPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Field phone'**
  String get fieldPhoneLabel;

  /// No description provided for @pricePerHourLabel.
  ///
  /// In en, this message translates to:
  /// **'Price per hour (IQD)'**
  String get pricePerHourLabel;

  /// No description provided for @addFieldPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add field photo'**
  String get addFieldPhoto;

  /// No description provided for @nameShort.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameShort;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get invalidPrice;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// No description provided for @registerError.
  ///
  /// In en, this message translates to:
  /// **'Registration error'**
  String get registerError;

  /// No description provided for @pricePerHourDisplay.
  ///
  /// In en, this message translates to:
  /// **'{price} IQD/hour'**
  String pricePerHourDisplay(int price);

  /// No description provided for @relativeNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get relativeNow;

  /// No description provided for @relativeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String relativeMinutes(int count);

  /// No description provided for @relativeHours.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String relativeHours(int count);

  /// No description provided for @relativeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get relativeYesterday;

  /// No description provided for @relativeDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String relativeDays(int count);

  /// No description provided for @relativeWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String relativeWeeks(int count);

  /// No description provided for @relativeMonths.
  ///
  /// In en, this message translates to:
  /// **'{count} months ago'**
  String relativeMonths(int count);

  /// No description provided for @relativeYears.
  ///
  /// In en, this message translates to:
  /// **'{count} years ago'**
  String relativeYears(int count);

  /// No description provided for @passwordMinChars.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordMinChars;

  /// No description provided for @completeAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all fields correctly'**
  String get completeAllFields;

  /// No description provided for @bookingHistory.
  ///
  /// In en, this message translates to:
  /// **'Booking history'**
  String get bookingHistory;

  /// No description provided for @totalHoursBooked.
  ///
  /// In en, this message translates to:
  /// **'Total hours you\'ve booked'**
  String get totalHoursBooked;

  /// No description provided for @totalHoursValue.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String totalHoursValue(int hours);

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @rateField.
  ///
  /// In en, this message translates to:
  /// **'Rate this field'**
  String get rateField;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get submitReview;

  /// No description provided for @reviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your review!'**
  String get reviewSubmitted;

  /// No description provided for @reviewOnlyAfterBooking.
  ///
  /// In en, this message translates to:
  /// **'You can rate after the owner approves your booking'**
  String get reviewOnlyAfterBooking;

  /// No description provided for @alreadyReviewed.
  ///
  /// In en, this message translates to:
  /// **'You already reviewed this field'**
  String get alreadyReviewed;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get yourRating;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(int count);

  /// No description provided for @penaltyShootout.
  ///
  /// In en, this message translates to:
  /// **'Penalty shootout'**
  String get penaltyShootout;

  /// No description provided for @penaltyChooseMode.
  ///
  /// In en, this message translates to:
  /// **'Choose game mode'**
  String get penaltyChooseMode;

  /// No description provided for @penaltyVsAi.
  ///
  /// In en, this message translates to:
  /// **'Vs AI'**
  String get penaltyVsAi;

  /// No description provided for @penaltyVsAiHint.
  ///
  /// In en, this message translates to:
  /// **'Score goals and save shots — AI gets harder every 3 goals!'**
  String get penaltyVsAiHint;

  /// No description provided for @penaltyTwoPlayers.
  ///
  /// In en, this message translates to:
  /// **'2 players, one phone'**
  String get penaltyTwoPlayers;

  /// No description provided for @penaltyTwoPlayersHint.
  ///
  /// In en, this message translates to:
  /// **'Pass the phone between shooter and keeper'**
  String get penaltyTwoPlayersHint;

  /// No description provided for @penaltyYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get penaltyYou;

  /// No description provided for @penaltyRobot.
  ///
  /// In en, this message translates to:
  /// **'Robot'**
  String get penaltyRobot;

  /// No description provided for @penaltyPlayer1.
  ///
  /// In en, this message translates to:
  /// **'Player 1'**
  String get penaltyPlayer1;

  /// No description provided for @penaltyPlayer2.
  ///
  /// In en, this message translates to:
  /// **'Player 2'**
  String get penaltyPlayer2;

  /// No description provided for @penaltyRound.
  ///
  /// In en, this message translates to:
  /// **'Round {round}'**
  String penaltyRound(int round);

  /// No description provided for @penaltySuddenDeath.
  ///
  /// In en, this message translates to:
  /// **'Sudden death'**
  String get penaltySuddenDeath;

  /// No description provided for @penaltyYourTurnShoot.
  ///
  /// In en, this message translates to:
  /// **'{player} — pick your shot'**
  String penaltyYourTurnShoot(String player);

  /// No description provided for @penaltyYourTurnSave.
  ///
  /// In en, this message translates to:
  /// **'Pick dive direction'**
  String get penaltyYourTurnSave;

  /// No description provided for @penaltyKeeperTurn.
  ///
  /// In en, this message translates to:
  /// **'{player} — your turn to keep'**
  String penaltyKeeperTurn(String player);

  /// No description provided for @penaltyAiSaving.
  ///
  /// In en, this message translates to:
  /// **'AI is preparing to save…'**
  String get penaltyAiSaving;

  /// No description provided for @penaltyPassPhone.
  ///
  /// In en, this message translates to:
  /// **'Pass the phone to the keeper'**
  String get penaltyPassPhone;

  /// No description provided for @penaltyGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal!'**
  String get penaltyGoal;

  /// No description provided for @penaltySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved!'**
  String get penaltySaved;

  /// No description provided for @penaltyPost.
  ///
  /// In en, this message translates to:
  /// **'Hit the post!'**
  String get penaltyPost;

  /// No description provided for @penaltyTapContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap to continue'**
  String get penaltyTapContinue;

  /// No description provided for @penaltyGameOver.
  ///
  /// In en, this message translates to:
  /// **'Game over'**
  String get penaltyGameOver;

  /// No description provided for @penaltyWinner.
  ///
  /// In en, this message translates to:
  /// **'Winner: {name}'**
  String penaltyWinner(String name);

  /// No description provided for @penaltyDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw!'**
  String get penaltyDraw;

  /// No description provided for @penaltyPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get penaltyPlayAgain;

  /// No description provided for @penaltyAiLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String penaltyAiLevel(int level);

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get bookNow;

  /// No description provided for @availableNow.
  ///
  /// In en, this message translates to:
  /// **'Available now'**
  String get availableNow;

  /// No description provided for @popularFields.
  ///
  /// In en, this message translates to:
  /// **'Popular fields'**
  String get popularFields;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @favoritesTab.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTab;

  /// No description provided for @moreTab.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTab;

  /// No description provided for @profileTab.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get profileTab;

  /// No description provided for @heroSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Book your field in Nineveh'**
  String get heroSlide1Title;

  /// No description provided for @heroSlide1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Top fields at competitive prices'**
  String get heroSlide1Subtitle;

  /// No description provided for @heroSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Penalty shootout mini-game'**
  String get heroSlide2Title;

  /// No description provided for @heroSlide2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Play locally while you wait for your slot'**
  String get heroSlide2Subtitle;

  /// No description provided for @quickSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get quickSupport;

  /// No description provided for @quickCertified.
  ///
  /// In en, this message translates to:
  /// **'Certified'**
  String get quickCertified;

  /// No description provided for @quickSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get quickSoon;

  /// No description provided for @quickOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get quickOffers;

  /// No description provided for @trustSecure.
  ///
  /// In en, this message translates to:
  /// **'Secure pay'**
  String get trustSecure;

  /// No description provided for @trustBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings done'**
  String get trustBookings;

  /// No description provided for @trustFields.
  ///
  /// In en, this message translates to:
  /// **'Fields live'**
  String get trustFields;

  /// No description provided for @trustUsers.
  ///
  /// In en, this message translates to:
  /// **'Happy users'**
  String get trustUsers;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites'**
  String get noFavorites;

  /// No description provided for @noFavoritesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on a field to save it here'**
  String get noFavoritesHint;

  /// No description provided for @moreMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreMenuTitle;

  /// No description provided for @sortAndFilter.
  ///
  /// In en, this message translates to:
  /// **'Sort & filter'**
  String get sortAndFilter;

  /// No description provided for @searchFieldsExtended.
  ///
  /// In en, this message translates to:
  /// **'Search for a field, district or city…'**
  String get searchFieldsExtended;

  /// No description provided for @heroBookSeconds.
  ///
  /// In en, this message translates to:
  /// **'Book your field in seconds'**
  String get heroBookSeconds;

  /// No description provided for @featureSupport.
  ///
  /// In en, this message translates to:
  /// **'Support & help'**
  String get featureSupport;

  /// No description provided for @amenityParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get amenityParking;

  /// No description provided for @amenityLighting.
  ///
  /// In en, this message translates to:
  /// **'Lighting'**
  String get amenityLighting;

  /// No description provided for @amenityShowers.
  ///
  /// In en, this message translates to:
  /// **'Showers'**
  String get amenityShowers;

  /// No description provided for @amenityCafeteria.
  ///
  /// In en, this message translates to:
  /// **'Cafeteria'**
  String get amenityCafeteria;

  /// No description provided for @promoTitle.
  ///
  /// In en, this message translates to:
  /// **'Exclusive offers this week'**
  String get promoTitle;

  /// No description provided for @promoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book 3 hours and get 1 hour free'**
  String get promoSubtitle;

  /// No description provided for @promoCta.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get promoCta;

  /// No description provided for @exploreTab.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreTab;

  /// No description provided for @category5v5.
  ///
  /// In en, this message translates to:
  /// **'5v5'**
  String get category5v5;

  /// No description provided for @category7v7.
  ///
  /// In en, this message translates to:
  /// **'7v7'**
  String get category7v7;

  /// No description provided for @category11v11.
  ///
  /// In en, this message translates to:
  /// **'11v11'**
  String get category11v11;

  /// No description provided for @categoryIndoor.
  ///
  /// In en, this message translates to:
  /// **'Indoor'**
  String get categoryIndoor;

  /// No description provided for @categoryOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get categoryOutdoor;

  /// No description provided for @exploreFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get exploreFilters;

  /// No description provided for @filterPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get filterPrice;

  /// No description provided for @filterRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get filterRating;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyFilters;

  /// No description provided for @mapPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'No fields on the map yet'**
  String get mapPlaceholder;

  /// No description provided for @bookingsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get bookingsUpcoming;

  /// No description provided for @bookingsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingsCompleted;

  /// No description provided for @bookingsCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingsCancelled;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get paymentMethods;

  /// No description provided for @paymentMethodsHint.
  ///
  /// In en, this message translates to:
  /// **'Your default gateway is used when paying for bookings.'**
  String get paymentMethodsHint;

  /// No description provided for @paymentMethodSaved.
  ///
  /// In en, this message translates to:
  /// **'Payment method saved'**
  String get paymentMethodSaved;

  /// No description provided for @paymentPendingHint.
  ///
  /// In en, this message translates to:
  /// **'Payment required — complete checkout so the owner can approve your booking.'**
  String get paymentPendingHint;

  /// No description provided for @fieldLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load field details'**
  String get fieldLoadFailed;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get chooseDate;

  /// No description provided for @chooseTime.
  ///
  /// In en, this message translates to:
  /// **'Choose time'**
  String get chooseTime;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @bookingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get bookingSuccess;

  /// No description provided for @selectDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get selectDuration;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// No description provided for @paymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment summary'**
  String get paymentSummary;

  /// No description provided for @fieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get fieldLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @hoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hoursLabel;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNow;

  /// No description provided for @payVisa.
  ///
  /// In en, this message translates to:
  /// **'Visa'**
  String get payVisa;

  /// No description provided for @payMastercard.
  ///
  /// In en, this message translates to:
  /// **'Mastercard'**
  String get payMastercard;

  /// No description provided for @payApplePay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get payApplePay;

  /// No description provided for @payGooglePay.
  ///
  /// In en, this message translates to:
  /// **'Google Pay'**
  String get payGooglePay;

  /// No description provided for @payCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get payCash;

  /// No description provided for @payOnline.
  ///
  /// In en, this message translates to:
  /// **'Pay online'**
  String get payOnline;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @paymentMethodHint.
  ///
  /// In en, this message translates to:
  /// **'How would you like to pay for this booking?'**
  String get paymentMethodHint;

  /// No description provided for @payOnlineHint.
  ///
  /// In en, this message translates to:
  /// **'Pay now via Zain Cash or card'**
  String get payOnlineHint;

  /// No description provided for @payCashHint.
  ///
  /// In en, this message translates to:
  /// **'Pay at the venue in cash'**
  String get payCashHint;

  /// No description provided for @walletTab.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletTab;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get walletBalance;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get recentTransactions;

  /// No description provided for @topUpWallet.
  ///
  /// In en, this message translates to:
  /// **'Top up wallet'**
  String get topUpWallet;

  /// No description provided for @walletBlocked.
  ///
  /// In en, this message translates to:
  /// **'Wallet blocked — contact platform admin to add balance'**
  String get walletBlocked;

  /// No description provided for @walletBlockedHint.
  ///
  /// In en, this message translates to:
  /// **'Only an administrator can top up your commission wallet after in-person payment.'**
  String get walletBlockedHint;

  /// No description provided for @walletFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get walletFilterAll;

  /// No description provided for @walletFilterCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get walletFilterCredits;

  /// No description provided for @walletFilterDebits.
  ///
  /// In en, this message translates to:
  /// **'Debits'**
  String get walletFilterDebits;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction details'**
  String get transactionDetails;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get transactionType;

  /// No description provided for @transactionAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transactionAmount;

  /// No description provided for @transactionDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transactionDate;

  /// No description provided for @transactionReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get transactionReason;

  /// No description provided for @transactionBookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get transactionBookingId;

  /// No description provided for @transactionBookingRef.
  ///
  /// In en, this message translates to:
  /// **'Booking reference'**
  String get transactionBookingRef;

  /// No description provided for @topUpAmount.
  ///
  /// In en, this message translates to:
  /// **'Top-up amount (IQD)'**
  String get topUpAmount;

  /// No description provided for @walletTopUpSuccess.
  ///
  /// In en, this message translates to:
  /// **'Wallet topped up successfully'**
  String get walletTopUpSuccess;

  /// No description provided for @adminTopUpWallet.
  ///
  /// In en, this message translates to:
  /// **'Top up owner wallet'**
  String get adminTopUpWallet;

  /// No description provided for @adminTopUpWalletHint.
  ///
  /// In en, this message translates to:
  /// **'Credit an owner\'s wallet after in-person cash payment'**
  String get adminTopUpWalletHint;

  /// No description provided for @adminTopUpNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get adminTopUpNote;

  /// No description provided for @qrTicketHint.
  ///
  /// In en, this message translates to:
  /// **'Show this QR code at the field entrance'**
  String get qrTicketHint;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin dashboard'**
  String get adminDashboard;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total revenue'**
  String get totalRevenue;

  /// No description provided for @monthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Monthly revenue'**
  String get monthlyRevenue;

  /// No description provided for @activeBookings.
  ///
  /// In en, this message translates to:
  /// **'Active bookings'**
  String get activeBookings;

  /// No description provided for @fieldOccupancy.
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get fieldOccupancy;

  /// No description provided for @revenueChart.
  ///
  /// In en, this message translates to:
  /// **'Revenue chart'**
  String get revenueChart;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get totalUsers;

  /// No description provided for @totalOwners.
  ///
  /// In en, this message translates to:
  /// **'Owners'**
  String get totalOwners;

  /// No description provided for @totalFields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get totalFields;

  /// No description provided for @platformRevenue.
  ///
  /// In en, this message translates to:
  /// **'Platform revenue'**
  String get platformRevenue;

  /// No description provided for @ownerCommissionCheckout.
  ///
  /// In en, this message translates to:
  /// **'Pay platform commission'**
  String get ownerCommissionCheckout;

  /// No description provided for @outstandingCommission.
  ///
  /// In en, this message translates to:
  /// **'Outstanding commission'**
  String get outstandingCommission;

  /// No description provided for @outstandingInvoices.
  ///
  /// In en, this message translates to:
  /// **'Outstanding invoices'**
  String get outstandingInvoices;

  /// No description provided for @noOutstandingInvoices.
  ///
  /// In en, this message translates to:
  /// **'No outstanding invoices'**
  String get noOutstandingInvoices;

  /// No description provided for @noOutstandingInvoicesHint.
  ///
  /// In en, this message translates to:
  /// **'All platform fees are settled'**
  String get noOutstandingInvoicesHint;

  /// No description provided for @paidInvoices.
  ///
  /// In en, this message translates to:
  /// **'Paid invoices'**
  String get paidInvoices;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get paymentHistory;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select payment method'**
  String get selectPaymentMethod;

  /// No description provided for @payZainCash.
  ///
  /// In en, this message translates to:
  /// **'Zain Cash'**
  String get payZainCash;

  /// No description provided for @payZainCashHint.
  ///
  /// In en, this message translates to:
  /// **'Pay via Zain Cash app — no card data stored in Riyada'**
  String get payZainCashHint;

  /// No description provided for @payCard.
  ///
  /// In en, this message translates to:
  /// **'Visa / Mastercard'**
  String get payCard;

  /// No description provided for @payCardHint.
  ///
  /// In en, this message translates to:
  /// **'Secure hosted checkout — card details never stored in the app'**
  String get payCardHint;

  /// No description provided for @payCommission.
  ///
  /// In en, this message translates to:
  /// **'Pay commission'**
  String get payCommission;

  /// No description provided for @payCommissionAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} commission'**
  String payCommissionAmount(String amount);

  /// No description provided for @outstandingHours.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 booked hour} other{{hours} booked hours}}'**
  String outstandingHours(int hours);

  /// No description provided for @invoiceHoursBookings.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours · {count} bookings'**
  String invoiceHoursBookings(int hours, int count);

  /// No description provided for @verifyPayment.
  ///
  /// In en, this message translates to:
  /// **'Verify payment'**
  String get verifyPayment;

  /// No description provided for @verifyPaymentHint.
  ///
  /// In en, this message translates to:
  /// **'Complete payment in the external gateway, then verify here. Only transaction tokens are used — no card data is stored.'**
  String get verifyPaymentHint;

  /// No description provided for @completePaymentThenVerify.
  ///
  /// In en, this message translates to:
  /// **'Complete payment externally, then tap Verify payment'**
  String get completePaymentThenVerify;

  /// No description provided for @paymentLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open payment gateway'**
  String get paymentLaunchFailed;

  /// No description provided for @paymentVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment verification failed — try again after completing payment'**
  String get paymentVerifyFailed;

  /// No description provided for @paymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment successful — account updated'**
  String get paymentSuccess;

  /// No description provided for @newBookingTab.
  ///
  /// In en, this message translates to:
  /// **'New booking'**
  String get newBookingTab;

  /// No description provided for @ownerRequestsTab.
  ///
  /// In en, this message translates to:
  /// **'Booking requests'**
  String get ownerRequestsTab;

  /// No description provided for @accountsTab.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTab;

  /// No description provided for @pickFieldFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a field first'**
  String get pickFieldFirst;

  /// No description provided for @pickFieldFirstHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a field from Home, then complete your booking here'**
  String get pickFieldFirstHint;

  /// No description provided for @changeField.
  ///
  /// In en, this message translates to:
  /// **'Change field'**
  String get changeField;

  /// No description provided for @accountsSummary.
  ///
  /// In en, this message translates to:
  /// **'Account summary'**
  String get accountsSummary;

  /// No description provided for @activeBookingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active booking} other{{count} active bookings}}'**
  String activeBookingsCount(int count);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
