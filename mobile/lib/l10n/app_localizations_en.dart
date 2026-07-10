// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Riyada';

  @override
  String get appTagline => 'Book your field in Nineveh';

  @override
  String get welcome => 'Welcome';

  @override
  String get login => 'Log in';

  @override
  String get register => 'Sign up';

  @override
  String get registerUser => 'User registration';

  @override
  String get registerOwner => 'Field owner registration';

  @override
  String get logout => 'Log out';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get darkModeOn => 'On';

  @override
  String get darkModeOff => 'Off';

  @override
  String get lightMode => 'Light mode';

  @override
  String get language => 'Language';

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEn => 'English';

  @override
  String get aboutApp => 'About';

  @override
  String get aboutAppSubtitle => 'Riyada — field booking in Nineveh\nVersion 1.0.0';

  @override
  String get devMode => 'Developer mode';

  @override
  String get devModeSubtitle => 'Server settings (developers)';

  @override
  String get apiHostLabel => 'Computer IP address';

  @override
  String get apiHostHint => '192.168.1.10';

  @override
  String get apiHostEmpty => 'Leave empty for automatic setup';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get confirm => 'Confirm';

  @override
  String get loading => 'Loading…';

  @override
  String get loadingData => 'Loading data…';

  @override
  String get loadingDashboard => 'Loading dashboard…';

  @override
  String get retry => 'Retry';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get name => 'Full name';

  @override
  String get phone => 'Phone number';

  @override
  String get province => 'Province';

  @override
  String get provinceNineveh => 'Nineveh';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get loginAsUser => 'User log in';

  @override
  String get loginAsOwner => 'Owner log in';

  @override
  String get loginUserSubtitle => 'Book fields and manage your bookings';

  @override
  String get loginOwnerSubtitle => 'Manage your field and booking requests';

  @override
  String get useUserLoginInstead => 'This is a user account — use user log in';

  @override
  String get useOwnerLoginInstead => 'This is an owner account — use owner log in';

  @override
  String get goToUserRegister => 'Create user account';

  @override
  String get goToOwnerRegister => 'Create owner account';

  @override
  String get goToUserLogin => 'I have a user account — log in';

  @override
  String get goToOwnerLogin => 'I have an owner account — log in';

  @override
  String get emailExactHint => 'Each email is unique — even if both end with @gmail.com';

  @override
  String get demoAccounts => 'Demo accounts';

  @override
  String get demoOwner => 'Field owner';

  @override
  String get demoUser => 'User';

  @override
  String get createAccountLogin => 'Create account & sign in';

  @override
  String get addProfilePhoto => 'Add profile photo (optional)';

  @override
  String get createOwnerAccount => 'Create field account';

  @override
  String get fields => 'Fields';

  @override
  String get myBookings => 'My bookings';

  @override
  String get notifications => 'Notifications';

  @override
  String get searchFields => 'Search for a field…';

  @override
  String get noFields => 'No fields found';

  @override
  String get noFieldsHint => 'Try changing your search terms';

  @override
  String get noBookings => 'No bookings';

  @override
  String get noBookingsHint => 'Book your first field from the Fields tab';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get pending => 'Pending';

  @override
  String get newLabel => 'New';

  @override
  String get sortDefault => 'Default';

  @override
  String get sortPriceAsc => 'Price ↑';

  @override
  String get sortPriceDesc => 'Price ↓';

  @override
  String get sortName => 'Name';

  @override
  String get cancelBooking => 'Cancel booking';

  @override
  String get cancelBookingConfirm => 'Are you sure you want to cancel this booking?';

  @override
  String get cancelWindowError => 'Cannot cancel after the booking time or for inactive bookings';

  @override
  String get cancelWindowHint => 'Free cancellation if more than 24 hours remain';

  @override
  String get cancelLatePenaltyHint => 'Cancelling within 12 hours incurs a 5,000 IQD fee';

  @override
  String get cancelLatePenaltyConfirm => 'A 5,000 IQD fee will apply: 2,500 to the field owner and 2,500 to the platform. Continue?';

  @override
  String get cancelSuccessWithPenalty => 'Cancelled — 5,000 IQD fee applied';

  @override
  String get accountRestrictedError => 'Account restricted due to excessive cancellations.';

  @override
  String get bookingInvalidHours => 'Booking duration must be between 1 and 2 hours';

  @override
  String get bookingOutsideHours => 'Operating hours: 9:00 AM – 12:00 AM';

  @override
  String get bookingPastTime => 'Cannot book a time in the past';

  @override
  String get yesCancel => 'Yes, cancel';

  @override
  String get rejectBooking => 'Reject booking';

  @override
  String get rejectBookingConfirm => 'Are you sure you want to reject this booking?';

  @override
  String get yesReject => 'Yes, reject';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get bookings => 'Bookings';

  @override
  String get all => 'All';

  @override
  String get approved => 'Confirmed';

  @override
  String get noOwnerBookings => 'No bookings';

  @override
  String get noOwnerBookingsHint => 'Booking requests will appear here';

  @override
  String get connectionLost => 'Connection lost. Please check your internet and try again.';

  @override
  String get insufficientWalletBalance => 'Insufficient balance to cover commission. Please top up.';

  @override
  String get confirmBooking => 'Confirm booking';

  @override
  String get confirmAndSend => 'Confirm & send';

  @override
  String get total => 'Total';

  @override
  String hours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get commissionNote => 'A 10% platform commission on (price per hour × hours booked) applies when the owner confirms';

  @override
  String get platformCommissionRate => '10% of field price per booked hour';

  @override
  String get bookingSent => 'Booking request sent successfully';

  @override
  String bookingSentRef(String code) {
    return 'Sent — reference: $code';
  }

  @override
  String get selectTime => 'Choose booking time';

  @override
  String get week => 'Week';

  @override
  String get noSlots => 'No available times';

  @override
  String get noSlotsHint => 'Try later or pull to refresh';

  @override
  String get tapToCall => 'Tap to call';

  @override
  String get perHour => '/hour';

  @override
  String get edit => 'Edit';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get newPasswordOptional => 'New password (optional)';

  @override
  String get yourField => 'Your field';

  @override
  String get saveField => 'Save field';

  @override
  String get addNewField => 'Add new field';

  @override
  String get fieldAddedSuccess => 'Field added — visible to users now';

  @override
  String get fieldUpdated => 'Field updated';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String passwordStrength(String level) {
    return 'Password strength: $level';
  }

  @override
  String get strengthWeak => 'Weak';

  @override
  String get strengthFair => 'Fair';

  @override
  String get strengthGood => 'Good';

  @override
  String get strengthStrong => 'Strong';

  @override
  String get showPassword => 'Show';

  @override
  String get hidePassword => 'Hide';

  @override
  String get copyReference => 'Copy reference';

  @override
  String get referenceCopied => 'Reference copied';

  @override
  String get sortBy => 'Sort';

  @override
  String get netRevenue => 'Net revenue';

  @override
  String get financialSummary => 'Financial summary';

  @override
  String get totalBookings => 'Bookings';

  @override
  String get waiting => 'Waiting';

  @override
  String hello(String name) {
    return 'Hello, $name';
  }

  @override
  String get taglineLong => 'Book your field in Nineveh with ease';

  @override
  String get startNow => 'Get started';

  @override
  String get chooseAccountType => 'Choose your account type to continue';

  @override
  String get registerUserCta => 'User — book a field';

  @override
  String get registerOwnerCta => 'Field owner — manage bookings';

  @override
  String get alreadyHaveAccount => 'I already have an account — log in';

  @override
  String get featureInstant => 'Instant booking';

  @override
  String get featureNotify => 'Notifications';

  @override
  String get featureTrusted => 'Trusted';

  @override
  String get onboardSkip => 'Skip';

  @override
  String get onboardNext => 'Next';

  @override
  String get onboardStart => 'Get started';

  @override
  String get onboardTitle1 => 'Discover the best fields';

  @override
  String get onboardBody1 => 'Browse Nineveh fields with clear prices, photos, and full details for every venue.';

  @override
  String get onboardTitle2 => 'Book in seconds';

  @override
  String get onboardBody2 => 'Pick your time, book 1–2 hours, and send your request instantly to the field owner.';

  @override
  String get onboardTitle3 => 'Stay updated in real time';

  @override
  String get onboardBody3 => 'Instant notifications on approval or rejection, and track all bookings in one place.';

  @override
  String get browseFields => 'Browse fields';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get pricePerHourLine => 'Price per hour';

  @override
  String get payAtField => 'Pay at the field';

  @override
  String get bookingSummary => 'Booking summary';

  @override
  String get devModeEnabled => 'Developer mode enabled';

  @override
  String get serverSaved => 'Server settings saved';

  @override
  String get stopDevMode => 'Disable developer mode';

  @override
  String get statusPendingApproval => 'Pending approval';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get labelField => 'Field';

  @override
  String get labelDateTime => 'Date & time';

  @override
  String get labelDuration => 'Duration';

  @override
  String get labelAmount => 'Amount';

  @override
  String get grandTotal => 'Grand total';

  @override
  String get appCommission => 'App commission';

  @override
  String markAllReadCount(int count) {
    return 'Mark all as read ($count)';
  }

  @override
  String get toggleLanguage => 'Switch language';

  @override
  String languageSwitched(String language) {
    return 'Switched to $language';
  }

  @override
  String get rtTitleNewBooking => 'New booking request';

  @override
  String rtMsgNewBooking(String userName, String dateTime, String referenceCode) {
    return 'Booking from $userName — $dateTime — $referenceCode';
  }

  @override
  String get rtTitleBookingPending => 'Your request is pending';

  @override
  String rtMsgBookingPending(String referenceCode) {
    return 'Booking request sent — $referenceCode';
  }

  @override
  String get rtTitleBookingApproved => 'Booking approved';

  @override
  String rtMsgBookingApproved(String fieldName, String referenceCode) {
    return 'Approved — $fieldName — $referenceCode';
  }

  @override
  String get rtTitleBookingRejected => 'Booking rejected';

  @override
  String rtMsgBookingRejected(String fieldName) {
    return 'Rejected — $fieldName';
  }

  @override
  String get rtTitleBookingCancelled => 'Booking cancelled';

  @override
  String rtMsgBookingCancelled(String dateTime, String fieldName) {
    return 'Cancelled $dateTime — $fieldName';
  }

  @override
  String get rtLiveConnected => 'Connected to live updates';

  @override
  String get rtLiveReconnecting => 'Reconnecting…';

  @override
  String get slotUnderSelection => 'Being booked now…';

  @override
  String get slotJustBooked => 'Sorry, this slot was just booked by another user';

  @override
  String get slotLockExpired => 'Selection expired — please choose another time';

  @override
  String get ownerDashboard => 'Owner dashboard';

  @override
  String get bookingApprovedSnack => 'Booking approved';

  @override
  String get bookingRejectedSnack => 'Booking rejected';

  @override
  String pendingBookingsAlert(int count) {
    return 'You have $count bookings awaiting approval';
  }

  @override
  String get yourInfo => 'Your information';

  @override
  String get fieldInfo => 'Field information';

  @override
  String get fieldNameLabel => 'Field name';

  @override
  String get addressLabel => 'Address';

  @override
  String get fieldPhoneLabel => 'Field phone';

  @override
  String get pricePerHourLabel => 'Price per hour (IQD)';

  @override
  String get addFieldPhoto => 'Add field photo';

  @override
  String get nameShort => 'Name';

  @override
  String get fieldRequired => 'Required';

  @override
  String get invalidPrice => 'Enter a valid price';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get registerError => 'Registration error';

  @override
  String pricePerHourDisplay(int price) {
    return '$price IQD/hour';
  }

  @override
  String get relativeNow => 'Just now';

  @override
  String relativeMinutes(int count) {
    return '$count min ago';
  }

  @override
  String relativeHours(int count) {
    return '$count h ago';
  }

  @override
  String get relativeYesterday => 'Yesterday';

  @override
  String relativeDays(int count) {
    return '$count days ago';
  }

  @override
  String relativeWeeks(int count) {
    return '$count weeks ago';
  }

  @override
  String relativeMonths(int count) {
    return '$count months ago';
  }

  @override
  String relativeYears(int count) {
    return '$count years ago';
  }

  @override
  String get passwordMinChars => 'At least 6 characters';

  @override
  String get completeAllFields => 'Please complete all fields correctly';

  @override
  String get bookingHistory => 'Booking history';

  @override
  String get totalHoursBooked => 'Total hours you\'ve booked';

  @override
  String totalHoursValue(int hours) {
    return '$hours hours';
  }

  @override
  String get statusCompleted => 'Completed';

  @override
  String get rateField => 'Rate this field';

  @override
  String get submitReview => 'Submit review';

  @override
  String get reviewSubmitted => 'Thanks for your review!';

  @override
  String get reviewOnlyAfterBooking => 'You can rate after the owner approves your booking';

  @override
  String get alreadyReviewed => 'You already reviewed this field';

  @override
  String get yourRating => 'Your rating';

  @override
  String reviewsCount(int count) {
    return '$count reviews';
  }

  @override
  String get penaltyShootout => 'Penalty shootout';

  @override
  String get penaltyChooseMode => 'Choose game mode';

  @override
  String get penaltyVsAi => 'Vs AI';

  @override
  String get penaltyVsAiHint => 'Score goals and save shots — AI gets harder every 3 goals!';

  @override
  String get penaltyTwoPlayers => '2 players, one phone';

  @override
  String get penaltyTwoPlayersHint => 'Pass the phone between shooter and keeper';

  @override
  String get penaltyYou => 'You';

  @override
  String get penaltyRobot => 'Robot';

  @override
  String get penaltyPlayer1 => 'Player 1';

  @override
  String get penaltyPlayer2 => 'Player 2';

  @override
  String penaltyRound(int round) {
    return 'Round $round';
  }

  @override
  String get penaltySuddenDeath => 'Sudden death';

  @override
  String penaltyYourTurnShoot(String player) {
    return '$player — pick your shot';
  }

  @override
  String get penaltyYourTurnSave => 'Pick dive direction';

  @override
  String penaltyKeeperTurn(String player) {
    return '$player — your turn to keep';
  }

  @override
  String get penaltyAiSaving => 'AI is preparing to save…';

  @override
  String get penaltyPassPhone => 'Pass the phone to the keeper';

  @override
  String get penaltyGoal => 'Goal!';

  @override
  String get penaltySaved => 'Saved!';

  @override
  String get penaltyPost => 'Hit the post!';

  @override
  String get penaltyTapContinue => 'Tap to continue';

  @override
  String get penaltyGameOver => 'Game over';

  @override
  String penaltyWinner(String name) {
    return 'Winner: $name';
  }

  @override
  String get penaltyDraw => 'Draw!';

  @override
  String get penaltyPlayAgain => 'Play again';

  @override
  String penaltyAiLevel(int level) {
    return 'Level $level';
  }

  @override
  String get bookNow => 'Book now';

  @override
  String get availableNow => 'Available now';

  @override
  String get popularFields => 'Popular fields';

  @override
  String get filter => 'Filter';

  @override
  String get homeTab => 'Home';

  @override
  String get favoritesTab => 'Favorites';

  @override
  String get moreTab => 'More';

  @override
  String get profileTab => 'My account';

  @override
  String get heroSlide1Title => 'Book your field in Nineveh';

  @override
  String get heroSlide1Subtitle => 'Top fields at competitive prices';

  @override
  String get heroSlide2Title => 'Penalty shootout mini-game';

  @override
  String get heroSlide2Subtitle => 'Play locally while you wait for your slot';

  @override
  String get quickSupport => 'Support';

  @override
  String get quickCertified => 'Certified';

  @override
  String get quickSoon => 'Coming soon';

  @override
  String get quickOffers => 'Offers';

  @override
  String get trustSecure => 'Secure pay';

  @override
  String get trustBookings => 'Bookings done';

  @override
  String get trustFields => 'Fields live';

  @override
  String get trustUsers => 'Happy users';

  @override
  String get noFavorites => 'No favorites';

  @override
  String get noFavoritesHint => 'Tap the heart on a field to save it here';

  @override
  String get moreMenuTitle => 'More';

  @override
  String get sortAndFilter => 'Sort & filter';

  @override
  String get searchFieldsExtended => 'Search for a field, district or city…';

  @override
  String get heroBookSeconds => 'Book your field in seconds';

  @override
  String get featureSupport => 'Support & help';

  @override
  String get amenityParking => 'Parking';

  @override
  String get amenityLighting => 'Lighting';

  @override
  String get amenityShowers => 'Showers';

  @override
  String get amenityCafeteria => 'Cafeteria';

  @override
  String get promoTitle => 'Exclusive offers this week';

  @override
  String get promoSubtitle => 'Book 3 hours and get 1 hour free';

  @override
  String get promoCta => 'Explore';

  @override
  String get exploreTab => 'Explore';

  @override
  String get category5v5 => '5v5';

  @override
  String get category7v7 => '7v7';

  @override
  String get category11v11 => '11v11';

  @override
  String get categoryIndoor => 'Indoor';

  @override
  String get categoryOutdoor => 'Outdoor';

  @override
  String get exploreFilters => 'Filters';

  @override
  String get filterPrice => 'Price';

  @override
  String get filterRating => 'Rating';

  @override
  String get applyFilters => 'Apply';

  @override
  String get mapPlaceholder => 'No fields on the map yet';

  @override
  String get bookingsUpcoming => 'Upcoming';

  @override
  String get bookingsCompleted => 'Completed';

  @override
  String get bookingsCancelled => 'Cancelled';

  @override
  String get changePassword => 'Change password';

  @override
  String get paymentMethods => 'Payment methods';

  @override
  String get paymentMethodsHint => 'Your default gateway is used when paying for bookings.';

  @override
  String get paymentMethodSaved => 'Payment method saved';

  @override
  String get paymentPendingHint => 'Payment required — complete checkout so the owner can approve your booking.';

  @override
  String get fieldLoadFailed => 'Could not load field details';

  @override
  String get chooseDate => 'Choose date';

  @override
  String get chooseTime => 'Choose time';

  @override
  String get payment => 'Payment';

  @override
  String get bookingSuccess => 'Booking confirmed';

  @override
  String get selectDuration => 'Duration';

  @override
  String get startTime => 'Start time';

  @override
  String get paymentSummary => 'Payment summary';

  @override
  String get fieldLabel => 'Field';

  @override
  String get dateLabel => 'Date';

  @override
  String get hoursLabel => 'Hours';

  @override
  String get discountLabel => 'Discount';

  @override
  String get totalLabel => 'Total';

  @override
  String get payNow => 'Pay now';

  @override
  String get payVisa => 'Visa';

  @override
  String get payMastercard => 'Mastercard';

  @override
  String get payApplePay => 'Apple Pay';

  @override
  String get payGooglePay => 'Google Pay';

  @override
  String get payCash => 'Cash';

  @override
  String get payOnline => 'Pay online';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get paymentMethodHint => 'How would you like to pay for this booking?';

  @override
  String get payOnlineHint => 'Pay now via Zain Cash or card';

  @override
  String get payCashHint => 'Pay at the venue in cash';

  @override
  String get walletTab => 'Wallet';

  @override
  String get walletBalance => 'Current balance';

  @override
  String get recentTransactions => 'Recent transactions';

  @override
  String get topUpWallet => 'Top up wallet';

  @override
  String get walletBlocked => 'Wallet blocked — contact platform admin to add balance';

  @override
  String get walletBlockedHint => 'Only an administrator can top up your commission wallet after in-person payment.';

  @override
  String get walletFilterAll => 'All';

  @override
  String get walletFilterCredits => 'Credits';

  @override
  String get walletFilterDebits => 'Debits';

  @override
  String get transactionDetails => 'Transaction details';

  @override
  String get transactionType => 'Type';

  @override
  String get transactionAmount => 'Amount';

  @override
  String get transactionDate => 'Date';

  @override
  String get transactionReason => 'Reason';

  @override
  String get transactionBookingId => 'Booking ID';

  @override
  String get transactionBookingRef => 'Booking reference';

  @override
  String get topUpAmount => 'Top-up amount (IQD)';

  @override
  String get walletTopUpSuccess => 'Wallet topped up successfully';

  @override
  String get adminTopUpWallet => 'Top up owner wallet';

  @override
  String get adminTopUpWalletHint => 'Credit an owner\'s wallet after in-person cash payment';

  @override
  String get adminTopUpNote => 'Note (optional)';

  @override
  String get qrTicketHint => 'Show this QR code at the field entrance';

  @override
  String get backToHome => 'Back to home';

  @override
  String get adminDashboard => 'Admin dashboard';

  @override
  String get totalRevenue => 'Total revenue';

  @override
  String get monthlyRevenue => 'Monthly revenue';

  @override
  String get activeBookings => 'Active bookings';

  @override
  String get fieldOccupancy => 'Occupancy';

  @override
  String get revenueChart => 'Revenue chart';

  @override
  String get totalUsers => 'Users';

  @override
  String get totalOwners => 'Owners';

  @override
  String get totalFields => 'Fields';

  @override
  String get platformRevenue => 'Platform revenue';

  @override
  String get ownerCommissionCheckout => 'Pay platform commission';

  @override
  String get outstandingCommission => 'Outstanding commission';

  @override
  String get outstandingInvoices => 'Outstanding invoices';

  @override
  String get noOutstandingInvoices => 'No outstanding invoices';

  @override
  String get noOutstandingInvoicesHint => 'All platform fees are settled';

  @override
  String get paidInvoices => 'Paid invoices';

  @override
  String get paymentHistory => 'Payment history';

  @override
  String get selectPaymentMethod => 'Select payment method';

  @override
  String get payZainCash => 'Zain Cash';

  @override
  String get payZainCashHint => 'Pay via Zain Cash app — no card data stored in Riyada';

  @override
  String get payCard => 'Visa / Mastercard';

  @override
  String get payCardHint => 'Secure hosted checkout — card details never stored in the app';

  @override
  String get payCommission => 'Pay commission';

  @override
  String payCommissionAmount(String amount) {
    return 'Pay $amount commission';
  }

  @override
  String outstandingHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours booked hours',
      one: '1 booked hour',
    );
    return '$_temp0';
  }

  @override
  String invoiceHoursBookings(int hours, int count) {
    return '$hours hours · $count bookings';
  }

  @override
  String get verifyPayment => 'Verify payment';

  @override
  String get verifyPaymentHint => 'Complete payment in the external gateway, then verify here. Only transaction tokens are used — no card data is stored.';

  @override
  String get completePaymentThenVerify => 'Complete payment externally, then tap Verify payment';

  @override
  String get paymentLaunchFailed => 'Could not open payment gateway';

  @override
  String get paymentVerifyFailed => 'Payment verification failed — try again after completing payment';

  @override
  String get paymentSuccess => 'Payment successful — account updated';

  @override
  String get newBookingTab => 'New booking';

  @override
  String get ownerRequestsTab => 'Booking requests';

  @override
  String get accountsTab => 'Accounts';

  @override
  String get pickFieldFirst => 'Select a field first';

  @override
  String get pickFieldFirstHint => 'Pick a field from Home, then complete your booking here';

  @override
  String get changeField => 'Change field';

  @override
  String get accountsSummary => 'Account summary';

  @override
  String activeBookingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active bookings',
      one: '1 active booking',
    );
    return '$_temp0';
  }

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';
}
