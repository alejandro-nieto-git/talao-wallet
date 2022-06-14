import 'package:altme/app/app.dart';
import 'package:altme/home/home.dart';
import 'package:altme/l10n/l10n.dart';
import 'package:flutter/material.dart';

class DisplayDescriptionCard extends StatelessWidget {
  const DisplayDescriptionCard(
      {Key? key,
      required this.credentialModel,
      required this.style,
      this.heightFactor = 0.4})
      : super(key: key);
  final CredentialModel credentialModel;
  final TextStyle style;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final nameValue = getDescription(context);
    return FractionallySizedBox(
      heightFactor: heightFactor,
      child: MyText(
        nameValue,
        maxLines: 5,
        overflow: TextOverflow.fade,
        style: style,
      ),
    );
  }

  String getDescription(BuildContext context) {
    var _nameValue = GetTranslation.getTranslation(
      credentialModel.credentialPreview.description,
      context.l10n,
    );
    if (_nameValue == '') {
      _nameValue = credentialModel.display.descriptionFallback;
    }

    return _nameValue;
  }
}
