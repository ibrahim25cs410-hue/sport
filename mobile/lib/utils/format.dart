import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/riyada_theme_extension.dart';

final _arDateTime = DateFormat('EEEE d MMMM yyyy HH:mm', 'ar');

String formatDateTime(DateTime dt) => _arDateTime.format(dt.toLocal());

/// وقت بنظام 12 ساعة مع ص/م — مثال: 4:00 م
String formatTime12Ar(DateTime dt) {
  final local = dt.toLocal();
  final hour = local.hour;
  final minute = local.minute;
  final isPm = hour >= 12;
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  final period = isPm ? 'م' : 'ص';
  return '$h12:${minute.toString().padLeft(2, '0')} $period';
}

/// نطاق زمني للحجز — مثال: 4:00 م – 6:00 م
String formatTimeRange12Ar(DateTime start, int hours) {
  final end = start.add(Duration(hours: hours));
  return '${formatTime12Ar(start)} – ${formatTime12Ar(end)}';
}

String formatMoney(int amount) => '${NumberFormat('#,###', 'ar').format(amount)} د.ع';

String formatRemaining(double hours) {
  if (hours <= 0) return 'انتهى الحجز';
  if (hours < 1) return '${(hours * 60).round()} دقيقة متبقية';
  if (hours < 24) return '${hours.round()} ساعة متبقية';
  final d = hours ~/ 24;
  final h = (hours % 24).round();
  return '$d يوم و $h ساعة';
}

String statusLabel(String status) => switch (status) {
      'pending' => 'بانتظار الموافقة',
      'approved' => 'مؤكد',
      'rejected' => 'مرفوض',
      'cancelled' => 'ملغي',
      _ => status,
    };

Color statusColor(BuildContext context, String status) {
  final c = context.colors;
  return switch (status) {
    'pending' => c.warning,
    'approved' => c.success,
    'rejected' => c.error,
    'cancelled' => c.neutral,
    _ => c.info,
  };
}
