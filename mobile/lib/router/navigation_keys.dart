import 'package:flutter/material.dart';

/// مفتاح الموجّه الجذري — للشاشات الكاملة فوق الـ Shell.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// مفتاح موجّه التبويبات (الرئيسية / المالك).
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
