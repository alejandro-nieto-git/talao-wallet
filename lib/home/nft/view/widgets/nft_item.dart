import 'package:altme/app/app.dart';
import 'package:flutter/material.dart';

class NftItem extends StatelessWidget {
  const NftItem({
    Key? key,
    required this.assetUrl,
    required this.description,
    required this.assetValue,
  }) : super(key: key);

  final String assetUrl;
  final String description;
  final String assetValue;

  @override
  Widget build(BuildContext context) {
    return BackgroundCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.05,
            child: Expanded(
              child: Image.network(assetUrl, fit: BoxFit.fill),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.caption,
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            assetValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyText1,
          )
        ],
      ),
    );
  }
}
