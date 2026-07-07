/// أيقونات التنقل السفلي — SVG مخصصة بأسلوب العلامة التجارية.
enum RiyadaNavIcon {
  home('assets/icons/nav/home.svg'),
  explore('assets/icons/nav/explore.svg'),
  bookings('assets/icons/nav/bookings.svg'),
  favorites('assets/icons/nav/favorites.svg'),
  profile('assets/icons/nav/profile.svg'),
  accounts('assets/icons/nav/accounts.svg');

  const RiyadaNavIcon(this.assetPath);

  final String assetPath;

  /// التبويبات الخمسة — SVG حسب Design Guidelines.
  static const shellTabs = [home, explore, bookings, favorites, profile];
}
