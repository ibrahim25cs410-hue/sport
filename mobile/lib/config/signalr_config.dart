import '../config/platform_info.dart';

abstract final class SignalRConfig {
  static String hubUrlFromApiBase(String apiBaseUrl) {
    final root = apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
    return '$root/hubs/booking';
  }

  static String defaultHubUrl() => hubUrlFromApiBase(PlatformInfo.resolveBaseUrl());
}
