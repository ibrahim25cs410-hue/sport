import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract final class CrashReporting {
  static const _dsn = String.fromEnvironment('SENTRY_DSN');
  static const _environment = String.fromEnvironment(
    'SENTRY_ENVIRONMENT',
    defaultValue: kReleaseMode ? 'production' : 'development',
  );
  static const _release = String.fromEnvironment('SENTRY_RELEASE');
  static const _filtered = '[Filtered]';
  static final _emailPattern = RegExp(
    r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}',
    caseSensitive: false,
  );
  static final _jwtPattern = RegExp(
    r'\b[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b',
  );
  static final _bearerPattern = RegExp(
    r'\bBearer\s+[A-Za-z0-9._~+/-]+=*',
    caseSensitive: false,
  );
  static final _phonePattern = RegExp(r'(?:\+?\d[\d ()-]{7,}\d)');
  static final _sensitiveAssignmentPattern = RegExp(
    r'\b(password|passwd|token|secret|authorization|api[_-]?key|email|phone|address|booking[_ -]?notes?|notes?)\s*[:=]\s*[^,;&\s]+',
    caseSensitive: false,
  );
  static const _sensitiveKeys = {
    'authorization',
    'cookie',
    'cookies',
    'password',
    'passwd',
    'secret',
    'token',
    'accesstoken',
    'refreshtoken',
    'jwt',
    'apikey',
    'email',
    'phone',
    'phonenumber',
    'address',
    'streetaddress',
    'note',
    'notes',
    'bookingnote',
    'bookingnotes',
  };

  static bool get enabled => _dsn.trim().isNotEmpty;

  static Future<void> initialize(FutureOr<void> Function() appRunner) async {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (enabled) {
        unawaited(
          Sentry.captureException(details.exception, stackTrace: details.stack),
        );
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (enabled) unawaited(Sentry.captureException(error, stackTrace: stack));
      return true;
    };

    if (!enabled) {
      await appRunner();
      return;
    }

    await SentryFlutter.init((options) {
      options
        ..dsn = _dsn
        ..environment = _environment
        ..sendDefaultPii = false
        ..attachStacktrace = true
        ..enableAutoSessionTracking = true;
      options.beforeSend = (event, hint) => sanitizeEvent(event);
      options.beforeBreadcrumb = (breadcrumb, hint) =>
          breadcrumb == null ? null : sanitizeBreadcrumb(breadcrumb);
      options.tracesSampleRate =
          double.tryParse(
            const String.fromEnvironment(
              'SENTRY_TRACES_SAMPLE_RATE',
              defaultValue: '0',
            ),
          ) ??
          0;
      if (_release.trim().isNotEmpty) options.release = _release.trim();
    }, appRunner: appRunner);
  }

  static Future<void> capture(Object error, StackTrace stack) async {
    if (enabled) await Sentry.captureException(error, stackTrace: stack);
  }

  @visibleForTesting
  static SentryEvent sanitizeEvent(SentryEvent event) {
    final json = Map<String, dynamic>.from(event.toJson())
      ..remove('user')
      ..remove('request');
    return SentryEvent.fromJson(
      _sanitizeValue(json) as Map<String, dynamic>,
    );
  }

  @visibleForTesting
  static Breadcrumb sanitizeBreadcrumb(Breadcrumb breadcrumb) {
    return Breadcrumb(
      message: _sanitizeString(breadcrumb.message),
      timestamp: breadcrumb.timestamp,
      category: breadcrumb.category,
      data: breadcrumb.data == null
          ? null
          : _sanitizeValue(breadcrumb.data) as Map<String, dynamic>,
      level: breadcrumb.level,
      type: breadcrumb.type,
    );
  }

  static dynamic _sanitizeValue(dynamic value, {String? key}) {
    if (key != null && _isSensitiveKey(key)) return _filtered;
    if (value is String) return _sanitizeString(value);
    if (value is Map) {
      return <String, dynamic>{
        for (final entry in value.entries)
          entry.key.toString(): _sanitizeValue(
            entry.value,
            key: entry.key.toString(),
          ),
      };
    }
    if (value is Iterable) {
      return value.map((item) => _sanitizeValue(item)).toList();
    }
    return value;
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (_sensitiveKeys.contains(normalized)) return true;
    return const [
      'authorization',
      'password',
      'passwd',
      'secret',
      'token',
      'email',
      'phone',
      'address',
      'cookie',
      'jwt',
    ].any(normalized.contains) ||
        normalized.endsWith('note') ||
        normalized.endsWith('notes');
  }

  static String? _sanitizeString(String? value) {
    if (value == null) return null;
    return value
        .replaceAll(_bearerPattern, _filtered)
        .replaceAll(_jwtPattern, _filtered)
        .replaceAll(_emailPattern, _filtered)
        .replaceAll(_phonePattern, _filtered)
        .replaceAllMapped(
          _sensitiveAssignmentPattern,
          (match) => '${match.group(1)}=$_filtered',
        );
  }
}
