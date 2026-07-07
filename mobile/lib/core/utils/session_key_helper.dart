import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/session_key.dart';

UserSessionKey? watchSessionKey(WidgetRef ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return null;
  return UserSessionKey(client: ref.read(apiClientProvider), userId: user.id);
}
