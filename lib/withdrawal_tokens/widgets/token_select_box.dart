import 'package:altme/app/app.dart';
import 'package:altme/dashboard/dashboard.dart';
import 'package:altme/theme/theme.dart';
import 'package:altme/withdrawal_tokens/withdrawal_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TokenSelectBoxView extends StatelessWidget {
  const TokenSelectBoxView({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final TokenSelectBoxController controller;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TokenSelectBoxCubit>(
      create: (_) => TokenSelectBoxCubit(
        controller: controller,
      ),
      child: const _TokenSelectBox(),
    );
  }
}

class _TokenSelectBox extends StatefulWidget {
  const _TokenSelectBox({Key? key}) : super(key: key);

  @override
  State<_TokenSelectBox> createState() => _TokenSelectBoxState();
}

class _TokenSelectBoxState extends State<_TokenSelectBox> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final selectedToken = await SelectTokenBottomSheet.show(context);
        if (selectedToken != null) {
          context
              .read<TokenSelectBoxCubit>()
              .setSelectedToken(tokenModel: selectedToken);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(Sizes.spaceSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).hoverColor,
          borderRadius: const BorderRadius.all(
            Radius.circular(Sizes.normalRadius),
          ),
        ),
        child: BlocBuilder<TokenSelectBoxCubit, TokenSelectBoxState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(Sizes.smallRadius),
                      ),
                      child: SizedBox(
                        width: Sizes.icon2x,
                        height: Sizes.icon2x,
                        child: CachedImageFromNetwork(
                          state.selectedToken.iconUrl ?? '',
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: Sizes.spaceXSmall,
                    ),
                    MyText(
                      state.selectedToken.name.isEmpty
                          ? state.selectedToken.symbol
                          : state.selectedToken.name,
                      maxLength: 10,
                      style: Theme.of(context).textTheme.listTileTitle,
                      minFontSize: 10,
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(
                      width: Sizes.spaceXSmall,
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_outlined,
                      size: Sizes.icon,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    const Spacer(
                      flex: 1,
                    ),
                    MyText(
                      state.selectedToken.calculatedBalance,
                      minFontSize: 10,
                      maxLength: 15,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                    MyText(
                      state.selectedToken.symbol,
                      minFontSize: 10,
                      maxLength: 10,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                MyText(
                  // TODO(Taleb): show usd value of token
                  '\$--.--',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.greyText,
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
