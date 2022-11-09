import 'dart:async';
import 'dart:convert';

import 'package:altme/app/app.dart';
import 'package:altme/dashboard/dashboard.dart';
import 'package:altme/did/cubit/did_cubit.dart';
import 'package:altme/wallet/cubit/wallet_cubit.dart';
import 'package:bloc/bloc.dart';
import 'package:crypto/crypto.dart';
import 'package:did_kit/did_kit.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:passbase_flutter/passbase_flutter.dart';
import 'package:secure_storage/secure_storage.dart';
import 'package:web3dart/crypto.dart';
import 'package:workmanager/workmanager.dart';

part 'home_cubit.g.dart';
part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required this.client,
    required this.didCubit,
    required this.secureStorageProvider,
  }) : super(const HomeState());

  final DioClient client;
  final DIDCubit didCubit;
  final SecureStorageProvider secureStorageProvider;

  final log = getLogger('HomeCubit');

  Future<void> aiSelfiValidation({
    required CredentialSubjectType credentialType,
    required List<int> imageBytes,
  }) async {
    final logger = getLogger('HomeCubit - aiSelfiValidation');
    emit(state.loading());
    try {
      final String url = credentialType == CredentialSubjectType.over13
          ? Urls.over13aiValidationUrl
          : Urls.over18aiValidationUrl;
      final verificationMethod =
          await secureStorageProvider.get(SecureStorageKeys.verificationMethod);

      final base64EncodedImage = base64Encode(imageBytes);

      final challenge =
          bytesToHex(sha256.convert(utf8.encode(base64EncodedImage)).bytes);

      final options = <String, dynamic>{
        'verificationMethod': verificationMethod,
        'proofPurpose': 'authentication',
        'challenge': challenge,
        'domain': 'issuer.talao.co',
      };

      final key = (await secureStorageProvider.get(SecureStorageKeys.ssiKey))!;
      final did = (await secureStorageProvider.get(SecureStorageKeys.did))!;

      final DIDKitProvider didKitProvider = DIDKitProvider();
      final String did_auth = await didKitProvider.didAuth(
        did,
        jsonEncode(options),
        key,
      );

      final data = <String, dynamic>{
        'base64_encoded_string': base64EncodedImage,
        'vp': did_auth,
        'did': did,
      };

      final dynamic response = await client.post(
        url,
        headers: <String, dynamic>{
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'X-API-KEY': '5f691f41-b7ef-456e-b53d-7351b2798b4e'
        },
        data: data,
      );
      emit(
        state.copyWith(
          status: AppStatus.success,
        ),
      );
      logger.i('response : $response');
    } catch (e, s) {
      emit(
        state.error(
          messageHandler: ResponseMessage(
            ResponseString.RESPONSE_STRING_SOMETHING_WENT_WRONG_TRY_AGAIN_LATER,
          ),
        ),
      );
      logger.e('error: $e , stack: $s');
      if (e is NetworkException) {
        logger.e('error message: ${e.message}');
      }
    }
  }

  Future<void> emitHasWallet() async {
    final String? passbaseStatusFromStorage = await secureStorageProvider.get(
      SecureStorageKeys.passBaseStatus,
    );
    if (passbaseStatusFromStorage != null) {
      final passBaseStatus = getPassBaseStatusFromString(
        passbaseStatusFromStorage,
      );
      if (passBaseStatus == PassBaseStatus.pending) {
        getPassBaseStatusBackground();
      }
    }

    emit(
      state.copyWith(
        status: AppStatus.populate,
        homeStatus: HomeStatus.hasWallet,
      ),
    );
  }

  void emitHasNoWallet() {
    emit(
      state.copyWith(
        status: AppStatus.populate,
        homeStatus: HomeStatus.hasNoWallet,
      ),
    );
  }

  Future<void> launchUrl({String? link}) async {
    await LaunchUrl.launch(link ?? state.link!);
  }

  Future<void> checkForPassBaseStatusThenLaunchUrl({
    required String link,
  }) async {
    log.i('Checking PassbaseStatus');
    emit(state.loading());

    late PassBaseStatus passBaseStatus;

    /// check if status is already approved in DB
    final String? passbaseStatusFromStorage = await secureStorageProvider.get(
      SecureStorageKeys.passBaseStatus,
    );

    if (passbaseStatusFromStorage != null) {
      passBaseStatus = getPassBaseStatusFromString(passbaseStatusFromStorage);
    } else {
      passBaseStatus = PassBaseStatus.undone;
    }

    if (passBaseStatus != PassBaseStatus.approved) {
      try {
        final did = didCubit.state.did!;
        passBaseStatus = await getPassBaseStatus(did);
        await secureStorageProvider.set(
          SecureStorageKeys.passBaseStatus,
          passBaseStatus.name,
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: AppStatus.populate,
            passBaseStatus: PassBaseStatus.declined,
            link: link,
          ),
        );
      }
    }

    if (passBaseStatus == PassBaseStatus.approved) {
      await launchUrl(link: link);
    }

    if (passBaseStatus == PassBaseStatus.pending) {
      getPassBaseStatusBackground();
    }

    log.i(passBaseStatus);

    emit(
      state.copyWith(
        status: AppStatus.populate,
        passBaseStatus: passBaseStatus,
        link: link,
      ),
    );
  }

  void startPassbaseVerification(WalletCubit walletCubit) {
    final log = getLogger('HomeCubit - startPassbaseVerification');
    final did = didCubit.state.did!;
    emit(state.loading());
    PassbaseSDK.startVerification(
      onFinish: (identityAccessKey) async {
        // IdentityAccessKey to run the process manually:
        // 22a363e6-2f93-4dd3-9ac8-6cba5a046acd

        unawaited(
          getMutipleCredentials(
            identityAccessKey,
            client,
            walletCubit,
            secureStorageProvider,
          ),
        );

        /// Do not remove: Following POST tell backend the relation between DID
        /// and passbase token.
        try {
          final dynamic response = await client.post(
            '/wallet/webhook',
            headers: <String, dynamic>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer mytoken',
            },
            data: <String, dynamic>{
              'identityAccessKey': identityAccessKey,
              'DID': did,
            },
          );

          if (response == 'ok') {
            emit(
              state.copyWith(
                status: AppStatus.idle,
                passBaseStatus: PassBaseStatus.complete,
              ),
            );
          } else {
            throw Exception();
          }
        } catch (e) {
          emit(
            state.copyWith(
              status: AppStatus.populate,
              passBaseStatus: PassBaseStatus.declined,
            ),
          );
        }
      },
      onError: (e) {
        if (e == 'CANCELLED_BY_USER') {
          log.e('Cancelled by user');
        } else {
          log.e('Unknown error');
        }
        emit(
          state.copyWith(
            status: AppStatus.idle,
            passBaseStatus: PassBaseStatus.idle,
          ),
        );
      },
    );
  }

  /// Give user metadata to KYC. Currently we are just sending user DID.
  bool setKYCMetadata(WalletCubit walletCubit) {
    final selectedCredentials = <CredentialModel>[];
    for (final credentialModel in walletCubit.state.credentials) {
      final credentialTypeList = credentialModel.credentialPreview.type;

      ///credential and issuer provided in claims
      if (credentialTypeList.contains('EmailPass')) {
        final credentialSubjectModel = credentialModel
            .credentialPreview.credentialSubjectModel as EmailPassModel;
        if (credentialSubjectModel.passbaseMetadata != '') {
          selectedCredentials.add(credentialModel);
        }
      }
    }
    if (selectedCredentials.isNotEmpty) {
      final firstEmailPassCredentialSubject =
          selectedCredentials.first.credentialPreview.credentialSubjectModel;
      if (firstEmailPassCredentialSubject is EmailPassModel) {
        /// Give user email from first EmailPass to KYC. When KYC is successful
        /// this email is used to send the over18 credential link to user.

        PassbaseSDK.prefillUserEmail = firstEmailPassCredentialSubject.email;
        PassbaseSDK.metaData = firstEmailPassCredentialSubject.passbaseMetadata;
        return true;
      }
    }
    return false;
  }

  @override
  Future<void> close() {
    return super.close();
  }

  void getPassBaseStatusBackground() {
    final did = didCubit.state.did!;
    Workmanager().registerOneOffTask(
      'getPassBaseStatusBackground',
      'getPassBaseStatusBackground',
      inputData: <String, dynamic>{'did': did},
    );
    periodicCheckPassBaseStatus();
  }

  Future<void> periodicCheckPassBaseStatus() async {
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      final String? passbaseStatusFromStorage = await secureStorageProvider.get(
        SecureStorageKeys.passBaseStatus,
      );

      if (passbaseStatusFromStorage != null) {
        final passBaseStatus = getPassBaseStatusFromString(
          passbaseStatusFromStorage,
        );
        if (passBaseStatus == PassBaseStatus.approved) {
          emit(
            state.copyWith(
              status: AppStatus.populate,
              passBaseStatus: PassBaseStatus.approved,
            ),
          );
        }
      }
    });
  }

  Future<void> periodicCheckReward({
    required List<String> walletAddresses,
  }) async {
    if (walletAddresses.isEmpty) return;
    try {
      await checkRewards(walletAddresses);
      Timer.periodic(const Duration(minutes: 1), (timer) async {
        await checkRewards(walletAddresses);
      });
    } catch (e, s) {
      getLogger('HomeCubit')
          .e('error in checking for reward , error: $e, stack: $s');
    }
  }

  Future<void> checkRewards(List<String> walletAddresses) async {
    for (int i = 0; i < walletAddresses.length; i++) {
      await checkUNOReward(walletAddresses[i]);
      await checkXTZReward(walletAddresses[i]);
    }
  }

  Future<void> checkUNOReward(String walletAddress) async {
    getLogger('HomeCubit').i('check for UNO reward');
    final response = await client.get(
      '${Urls.tzktMainnetUrl}/v1/tokens/transfers',
      queryParameters: <String, dynamic>{
        'from': 'tz1YtKsJMx5FqhULTDzNxs9r9QYHBGsmz58o', // tezotopia
        'to': walletAddress,
        'token.contract.eq': 'KT1ErKVqEhG9jxXgUG2KGLW3bNM7zXHX8SDF', // UNO
        'sort.desc': 'timestamp'
      },
    ) as List<dynamic>;

    if (response.isEmpty) {
      return;
    }

    final operations = response
        .map(
          (dynamic e) => OperationModel.fromFa2Json(e as Map<String, dynamic>),
        )
        .toList();

    final String? lastNotifiedRewardId = await secureStorageProvider.get(
      SecureStorageKeys.lastNotifiedUNORewardId + walletAddress,
    );

    final lastOperation = operations.first; //operations sorted by time in api
    if (lastOperation.id.toString() == lastNotifiedRewardId) {
      return;
    } else {
      // save the operation id to storage
      await secureStorageProvider.set(
        SecureStorageKeys.lastNotifiedUNORewardId + walletAddress,
        lastOperation.id.toString(),
      );

      emit(
        state.copyWith(
          status: AppStatus.gotTokenReward,
          tokenReward: TokenReward(
            amount: lastOperation.calcAmount(
              decimal: 9, //UNO
              value: lastOperation.amount.toString(),
            ),
            txId: lastOperation.hash,
            counter: lastOperation.counter,
            account: walletAddress,
            origin:
                'Tezotopia Membership Card', // TODO(all): dynamic text later
            symbol: 'UNO',
            name: 'Unobtanium',
          ),
        ),
      );
    }
  }

  Future<void> checkXTZReward(String walletAddress) async {
    getLogger('HomeCubit').i('check for XTZ reward');

    final result = await client.get(
      '${Urls.tzktMainnetUrl}/v1/operations/transactions',
      queryParameters: <String, dynamic>{
        'sender': 'tz1YtKsJMx5FqhULTDzNxs9r9QYHBGsmz58o', // tezotopia
        'target': walletAddress,
        'amount.gt': 0,
      },
    ) as List<dynamic>;

    if (result.isEmpty) {
      return;
    }

    final operations = result
        .map(
          (dynamic e) => OperationModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
    //sort for last transaction at first
    operations.sort(
      (a, b) => b.dateTime.compareTo(a.dateTime),
    );

    final String? lastNotifiedRewardId = await secureStorageProvider.get(
      SecureStorageKeys.lastNotifiedXTZRewardId + walletAddress,
    );

    final lastOperation = operations.first; //operations sorted by time in api
    if (lastOperation.id.toString() == lastNotifiedRewardId) {
      return;
    } else {
      // save the operation id to storage
      await secureStorageProvider.set(
        SecureStorageKeys.lastNotifiedXTZRewardId + walletAddress,
        lastOperation.id.toString(),
      );

      emit(
        state.copyWith(
          status: AppStatus.gotTokenReward,
          tokenReward: TokenReward(
            amount: lastOperation.calcAmount(
              decimal: 6, //XTZ
              value: lastOperation.amount.toString(),
            ),
            account: walletAddress,
            txId: lastOperation.hash,
            counter: lastOperation.counter,
            origin:
                'Tezotopia Membership Card', // TODO(all): dynamic text later
            symbol: 'XTZ',
            name: 'Tezos',
          ),
        ),
      );
    }
  }
}

Future<PassBaseStatus> getPassBaseStatus(String did) async {
  try {
    final client = DioClient(Urls.issuerBaseUrl, Dio());
    final dynamic response = await client.get(
      '/passbase/check/$did',
      headers: <String, dynamic>{
        'Accept': 'application/json',
        'Authorization': 'Bearer mytoken',
      },
    );
    final PassBaseStatus passBaseStatus = getPassBaseStatusFromString(
      response as String,
    );
    return passBaseStatus;
  } catch (e) {
    return PassBaseStatus.undone;
  }
}

PassBaseStatus getPassBaseStatusFromString(String? string) {
  late PassBaseStatus passBaseStatus;
  switch (string) {
    case 'approved':
      passBaseStatus = PassBaseStatus.approved;
      break;
    case 'declined':
      passBaseStatus = PassBaseStatus.declined;
      break;
    case 'verified':
      passBaseStatus = PassBaseStatus.verified;
      break;
    case 'pending':
      passBaseStatus = PassBaseStatus.pending;
      break;
    case 'undone':
      passBaseStatus = PassBaseStatus.undone;
      break;
    case 'notdone':
      passBaseStatus = PassBaseStatus.undone;
      break;
    case 'complete':
      passBaseStatus = PassBaseStatus.complete;
      break;
    case 'idle':
    default:
      passBaseStatus = PassBaseStatus.idle;
  }
  return passBaseStatus;
}
