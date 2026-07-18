import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riyada/l10n/app_localizations.dart';

void main() {
  testWidgets('Arabic app tagline is localized', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Text(AppLocalizations.of(context).appTagline),
        ),
      ),
    );

    expect(find.text('احجز ملعبك في نينوى'), findsOneWidget);
  });

  testWidgets('operational error copy follows English locale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Text(AppLocalizations.of(context).unexpectedError),
        ),
      ),
    );

    expect(
      find.text('Something went wrong. Please restart the app and try again.'),
      findsOneWidget,
    );
  });
}
