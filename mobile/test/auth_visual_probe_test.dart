import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:riyada/l10n/app_localizations.dart';
import 'package:riyada/providers/locale_provider.dart';
import 'package:riyada/providers/theme_provider.dart';
import 'package:riyada/screens/login_screen.dart';
import 'package:riyada/screens/register_owner_screen.dart';
import 'package:riyada/screens/register_user_screen.dart';
import 'package:riyada/theme/app_theme.dart';

void main() {
  Future<void> pumpAuthScreen(WidgetTester tester, Widget screen) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: legacy.MultiProvider(
          providers: [
            legacy.ChangeNotifierProvider(create: (_) => ThemeProvider()),
            legacy.ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.dark,
            home: screen,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('login fields render in debug dark mode', (tester) async {
    await pumpAuthScreen(
      tester,
      const LoginScreen(expectedRole: 'user'),
    );
    expect(find.byType(TextFormField), findsNWidgets(2));
    for (final element in find.byType(TextFormField).evaluate()) {
      final box = element.renderObject! as RenderBox;
      expect(box.size.width, greaterThan(250));
      expect(box.size.height, greaterThan(48));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('user registration fields render in debug dark mode', (tester) async {
    await pumpAuthScreen(tester, const RegisterUserScreen());
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('owner registration fields render in dark mode', (tester) async {
    await pumpAuthScreen(tester, const RegisterOwnerScreen());
    expect(find.byType(TextFormField), findsNWidgets(8));
    expect(tester.takeException(), isNull);
  });
}
