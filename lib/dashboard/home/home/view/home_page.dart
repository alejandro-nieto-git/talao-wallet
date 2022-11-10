import 'package:altme/app/app.dart';
import 'package:altme/dashboard/dashboard.dart';
import 'package:altme/wallet/cubit/wallet_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeCubit, HomeState>(
      listener: (context, homeState) {
        if (homeState.status == AppStatus.loading) {
          LoadingView().show(context: context);
        } else {
          LoadingView().hide();
        }

        if (homeState.message != null) {
          AlertMessage.showStateMessage(
            context: context,
            stateMessage: homeState.message!,
          );
        }

        if (homeState.status == AppStatus.insertCredential) {
          final credentialModel = homeState.data as CredentialModel;
          context.read<WalletCubit>().insertCredential(credentialModel);
        }

        if (homeState.status == AppStatus.success) {}

        if (homeState.status == AppStatus.gotTokenReward &&
            homeState.tokenReward != null) {
          TokenRewardDialog.show(
            context: context,
            tokenReward: homeState.tokenReward!,
          );
        }
      },
      // TODO(all): Remove IosTabControllerPage when apple accept our NFT #664, https://github.com/TalaoDAO/AltMe/issues/664
      // Setting to hide gallery when on ios
      child: const TabControllerPage(),
    );
  }
}
