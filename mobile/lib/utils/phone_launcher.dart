import 'package:url_launcher/url_launcher.dart';

Future<void> launchPhoneCall(String phone) async {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return;
  final uri = Uri.parse('tel:$digits');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}
