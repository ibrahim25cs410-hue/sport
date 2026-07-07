import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../../config/security_config.dart';

/// يثبّت شهادة API في الإنتاج لمنع MITM — يُفعَّل عبر dart-define فقط.
void configureSslPinning(Dio dio) {
  if (!SecurityConfig.shouldPinCertificates) return;
  if (kIsWeb) return;

  final expectedPin = SecurityConfig.sslPinSha256.toLowerCase().replaceAll(':', '');

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) {
        final der = cert.der;
        final digest = sha256.convert(der).bytes;
        final hex = digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        return hex == expectedPin;
      };
      return client;
    },
  );
}
