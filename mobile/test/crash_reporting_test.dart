import 'package:flutter_test/flutter_test.dart';
import 'package:riyada/core/monitoring/crash_reporting.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  test('event scrubber removes PII and preserves stack traces', () {
    final contexts = Contexts()
      ..['booking'] = {
        'shipping_address': '123 Main Street',
        'notes': 'Call user@example.com',
        'status': 'pending',
      };
    final event = SentryEvent(
      user: SentryUser(id: '42', email: 'user@example.com'),
      request: SentryRequest(
        url: 'https://api.example.test/book?token=secret-token',
        headers: {'Authorization': 'Bearer secret-token'},
        data: {'password': 'secret'},
      ),
      contexts: contexts,
      breadcrumbs: [
        Breadcrumb(
          message: 'Booked by user@example.com phone=07701234567',
          data: {
            'authorization': 'Bearer secret-token',
            'safe': 'kept',
          },
        ),
      ],
      exceptions: [
        SentryException(
          type: 'StateError',
          value: 'token=secret-token',
          stackTrace: SentryStackTrace(
            frames: [
              SentryStackFrame(
                fileName: 'booking_service.dart',
                function: 'createBooking',
                lineNo: 42,
              ),
            ],
          ),
        ),
      ],
      // ignore: deprecated_member_use
      extra: {
        'access_token': 'secret-token',
        'description': 'Contact user@example.com',
      },
    );

    final sanitized = CrashReporting.sanitizeEvent(event);
    final json = sanitized.toJson();

    expect(json.containsKey('user'), isFalse);
    expect(json.containsKey('request'), isFalse);
    expect(json['contexts']['booking']['shipping_address'], '[Filtered]');
    expect(json['contexts']['booking']['notes'], '[Filtered]');
    expect(json['contexts']['booking']['status'], 'pending');
    expect(json['extra']['access_token'], '[Filtered]');
    expect(json['extra']['description'], 'Contact [Filtered]');
    expect(json['breadcrumbs'][0]['message'], isNot(contains('user@example.com')));
    expect(json['breadcrumbs'][0]['message'], isNot(contains('07701234567')));
    expect(json['breadcrumbs'][0]['data']['authorization'], '[Filtered]');

    final exception = sanitized.exceptions!.single;
    expect(exception.value, 'token=[Filtered]');
    expect(exception.stackTrace!.frames, hasLength(1));
    expect(exception.stackTrace!.frames.single.fileName, 'booking_service.dart');
    expect(exception.stackTrace!.frames.single.lineNo, 42);
  });

  test('breadcrumb scrubber filters nested secrets and keeps metadata', () {
    final breadcrumb = Breadcrumb(
      category: 'booking',
      type: 'default',
      message: 'password=hunter2',
      data: {
        'booking_notes': 'Gate code 1234',
        'nested': {'phone': '+964 770 123 4567', 'safe': true},
      },
    );

    final sanitized = CrashReporting.sanitizeBreadcrumb(breadcrumb);

    expect(sanitized.category, 'booking');
    expect(sanitized.type, 'default');
    expect(sanitized.message, 'password=[Filtered]');
    expect(sanitized.data!['booking_notes'], '[Filtered]');
    expect((sanitized.data!['nested'] as Map)['phone'], '[Filtered]');
    expect((sanitized.data!['nested'] as Map)['safe'], isTrue);
  });
}
