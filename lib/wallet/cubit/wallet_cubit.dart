import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:talao/app/interop/secure_storage/secure_storage.dart';
import 'package:talao/app/pages/credentials/models/credential_model.dart';
import 'package:talao/app/pages/credentials/repositories/credential.dart';
import 'package:bloc/bloc.dart';
import 'package:talao/app/shared/constants.dart';
import 'package:talao/drawer/drawer.dart';

part 'wallet_state.dart';

part 'wallet_cubit.g.dart';

class WalletCubit extends Cubit<WalletState> {
  final CredentialsRepository repository;
  final SecureStorageProvider secureStorageProvider;
  final ProfileCubit profileCubit;

  WalletCubit({
    required this.repository,
    required this.secureStorageProvider,
    required this.profileCubit,
  }) : super(WalletState()) {
    checkKey();
  }

  Future checkKey() async {
    final key = await SecureStorageProvider.instance.get('key');
    if (key == null) {
      emit(state.copyWith(status: KeyStatus.needsKey));
    } else {
      if (key.isEmpty) {
        emit(state.copyWith(status: KeyStatus.needsKey));
      } else {
        /// When app is initialized, set all credentials with active status to unknown status
        await repository.initializeRevocationStatus();

        /// load all credentials from repository
        await repository.findAll(/* filters */).then((values) {
          emit(state.copyWith(status: KeyStatus.hasKey, credentials: values));
        });
      }
    }
  }

  Future deleteById(String id) async {
    await repository.deleteById(id);
    final credentials = List.of(state.credentials)
      ..removeWhere((element) => element.id == id);
    emit(state.copyWith(credentials: credentials));
  }

  Future updateCredential(CredentialModel credential) async {
    await repository.update(credential);
    final index = state.credentials
        .indexWhere((element) => element.id == credential.id.toString());
    final credentials = List.of(state.credentials)
      ..removeWhere((element) => element.id == credential.id)
      ..insert(index, credential);
    emit(state.copyWith(credentials: credentials));
  }

  Future insertCredential(CredentialModel credential) async {
    await repository.insert(credential);
    final credentials = List.of(state.credentials)..add(credential);
    emit(state.copyWith(credentials: credentials));
  }

  Future resetWallet() async {
    await secureStorageProvider.delete('key');
    await secureStorageProvider.delete('mnemonic');
    await secureStorageProvider.delete('data');
    await secureStorageProvider.delete(Constants.firstNameKey);
    await secureStorageProvider.delete(Constants.lastNameKey);
    await secureStorageProvider.delete(Constants.phoneKey);
    await secureStorageProvider.delete(Constants.locationKey);
    await secureStorageProvider.delete(Constants.emailKey);
    await repository.deleteAll();
    profileCubit.resetProfile();
    emit(state.copyWith(status: KeyStatus.resetKey, credentials: []));
    emit(state.copyWith(status: KeyStatus.init));
  }

  Future<void> recoverWallet(List<CredentialModel> credentials) async {
    await repository.deleteAll();
    credentials
        .forEach((credential) async => await repository.insert(credential));
    emit(state.copyWith(status: KeyStatus.init, credentials: credentials));
  }
}
