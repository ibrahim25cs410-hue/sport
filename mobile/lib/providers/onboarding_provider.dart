import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the first-run onboarding carousel has been completed.
final onboardingCompleteProvider = StateProvider<bool>((ref) => true);
