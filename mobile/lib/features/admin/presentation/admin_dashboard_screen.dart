import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_dashboard_tab.dart';

/// Legacy full-screen admin route — content lives in [AdminDashboardTab] inside [MainWrapper].
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const AdminDashboardTab();
}
