import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/wallet.dart';
import '../../providers/service_providers.dart';
import '../../providers/session_key.dart';
import '../../services/wallet_service.dart';

final walletServiceProvider = Provider<WalletService>(
  (ref) => WalletService(ref.watch(apiClientProvider)),
);

final ownerWalletProvider = FutureProvider.family<WalletDetail, UserSessionKey>((ref, key) async {
  return ref.watch(walletServiceProvider).getWallet();
});

final ownerWalletStatusProvider = FutureProvider.family<WalletStatus, UserSessionKey>((ref, key) async {
  return ref.watch(walletServiceProvider).getStatus();
});
