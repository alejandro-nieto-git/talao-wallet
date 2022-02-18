import 'package:talao/app/pages/on_boarding/gen_phrase.dart';
import 'package:talao/app/pages/on_boarding/recovery.dart';
import 'package:talao/app/shared/widget/base/button.dart';
import 'package:talao/app/shared/widget/base/page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OnBoardingKeyPage extends StatelessWidget {
  static Route route() => MaterialPageRoute(
        builder: (context) => OnBoardingKeyPage(),
    settings: RouteSettings(name: '/onBoardingKeyPage'),
      );

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return WillPopScope(
      onWillPop: () async => false,
      child: BasePage(
        title: localizations.onBoardingKeyTitle,
        scrollView: false,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    localizations.keyRecoveryTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  const SizedBox(height: 32.0),
                  Text(
                    localizations.keyRecoveryText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                  const SizedBox(height: 20.0),
                  BaseButton.primary(
                    context: context,
                    onPressed: () {
                      Navigator.of(context)
                          .push(OnBoardingRecoveryPage.route());
                    },
                    child: Text(localizations.onBoardingKeyRecover),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    localizations.keyGenerateTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  const SizedBox(height: 32.0),
                  Text(
                    localizations.keyGenerateText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                  const SizedBox(height: 20.0),
                  BaseButton.primary(
                    context: context,
                    onPressed: () {
                      Navigator.of(context)
                          .push(OnBoardingGenPhrasePage.route());
                    },
                    child: Text(localizations.onBoardingKeyGenerate),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
