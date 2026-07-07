import 'main_wrapper.dart';

/// Shell entry — delegates to [MainWrapper] for role-based navigation.
class MainShellScreen extends MainWrapper {
  const MainShellScreen({super.key, super.initialIndex, super.shellRouteChild});
}
