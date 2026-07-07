import 'package:flutter_test/flutter_test.dart';
import 'package:riyada/utils/error_messages.dart';

void main() {
  test('server business messages pass through when not technical', () {
    expect(friendlyErrorMessage('فشل التحقق من الدفع'), 'فشل التحقق من الدفع');
  });

  test('technical socket errors use connection guidance in debug', () {
    final msg = friendlyErrorMessage(Exception('SocketException: Connection refused'));
    expect(msg.contains('الاتصال') || msg.contains('المحاولة'), isTrue);
  });
}
