import 'package:altme/app/app.dart';
import 'package:altme/onboarding/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/helpers.dart';

void main() {
  group('Onboarding Start Page', () {
    testWidgets('is routable', (tester) async {
      await tester.pumpApp(
        Builder(
          builder: (context) => Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push<void>(OnBoardingStartPage.route());
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byType(OnBoardingStartPage), findsOneWidget);
    });

    testWidgets('renders OnBoardingStartPage', (tester) async {
      await tester.pumpApp(const OnBoardingStartPage());
      await tester.pumpAndSettle();
      expect(find.byType(OnBoardingStartPage), findsOneWidget);
    });

    testWidgets('navigates to OnBoardingSecondPage on when screen is tapped',
        (tester) async {
      await tester.pumpApp(const OnBoardingStartPage());
      await tester.tap(find.byKey(const Key('start_page_gesture_detector')));
      await tester.pumpAndSettle();
      expect(find.byType(OnBoardingSecondPage), findsOneWidget);
    });

    testWidgets('navigates to OnBoardingTosPage when button is pressed',
        (tester) async {
      await tester.pumpApp(const OnBoardingStartPage());
      await tester.tap(find.byType(BaseButton));
      await tester.pumpAndSettle();
      expect(find.byType(OnBoardingTosPage), findsOneWidget);
    });

    testWidgets('animation value change after 1 sec', (tester) async {
      await tester.pumpApp(const OnBoardingStartPage());
      final dynamic appState = tester.state(find.byType(OnBoardingStartPage));
      expect(appState.animate, true);
      appState.disableAnimation();
      expect(appState.animate, false);
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(appState.animate, true);
    });

    testWidgets('blocks going back from Onboarding start page', (tester) async {
      await tester.pumpApp(const OnBoardingStartPage());
      final dynamic appState = tester.state(find.byType(WidgetsApp));
      expect(await appState.didPopRoute(), true);
      await tester.pumpAndSettle();
      expect(find.byType(OnBoardingStartPage), findsOneWidget);
    });
  });
}
