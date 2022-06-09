import 'package:altme/app/app.dart';
import 'package:altme/app/shared/enum/issuer_verification_registry.dart';
import 'package:altme/home/home.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';
import 'package:secure_storage/secure_storage.dart';

part 'profile_cubit.g.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required this.secureStorageProvider})
      : super(ProfileState(model: ProfileModel.empty())) {
    load();
  }

  final SecureStorageProvider secureStorageProvider;

  Future<void> load() async {
    emit(state.loading());
    final log = Logger('altme-wallet/profile/load');
    try {
      final firstName =
          await secureStorageProvider.get(SecureStorageKeys.firstNameKey) ?? '';
      final lastName =
          await secureStorageProvider.get(SecureStorageKeys.lastNameKey) ?? '';
      final phone =
          await secureStorageProvider.get(SecureStorageKeys.phoneKey) ?? '';
      final location =
          await secureStorageProvider.get(SecureStorageKeys.locationKey) ?? '';
      final email =
          await secureStorageProvider.get(SecureStorageKeys.emailKey) ?? '';
      final companyName =
          await secureStorageProvider.get(SecureStorageKeys.companyName) ?? '';
      final companyWebsite =
          await secureStorageProvider.get(SecureStorageKeys.companyWebsite) ??
              '';
      final jobTitle =
          await secureStorageProvider.get(SecureStorageKeys.jobTitle) ?? '';
      final issuerVerificationUrl = await secureStorageProvider
              .get(SecureStorageKeys.issuerVerificationUrlKey) ??
          Urls.checkIssuerTalaoUrl;
      final isEnterprise = (await secureStorageProvider
              .get(SecureStorageKeys.isEnterpriseUser)) ==
          'true';

      final profileModel = ProfileModel(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        location: location,
        email: email,
        issuerVerificationUrl: issuerVerificationUrl,
        companyName: companyName,
        companyWebsite: companyWebsite,
        jobTitle: jobTitle,
        isEnterprise: isEnterprise,
      );

      emit(state.success(model: profileModel));
    } catch (e) {
      log.severe('something went wrong', e);
      emit(
        state.error(
          messageHandler: ResponseMessage(
            ResponseString.RESPONSE_STRING_FAILED_TO_LOAD_PROFILE,
          ),
        ),
      );
    }
  }

  Future<void> resetProfile() async {
    emit(state.loading());
    await secureStorageProvider.delete(SecureStorageKeys.firstNameKey);
    await secureStorageProvider.delete(SecureStorageKeys.lastNameKey);
    await secureStorageProvider.delete(SecureStorageKeys.phoneKey);
    await secureStorageProvider.delete(SecureStorageKeys.locationKey);
    await secureStorageProvider.delete(SecureStorageKeys.emailKey);
    await secureStorageProvider.delete(SecureStorageKeys.jobTitle);
    await secureStorageProvider.delete(SecureStorageKeys.companyWebsite);
    await secureStorageProvider.delete(SecureStorageKeys.companyName);
    await secureStorageProvider
        .delete(SecureStorageKeys.issuerVerificationUrlKey);
    await secureStorageProvider.delete(SecureStorageKeys.isEnterpriseUser);
    emit(state.success(model: ProfileModel.empty()));
  }

  Future<void> update(ProfileModel profileModel) async {
    emit(state.loading());
    final log = Logger('altme-wallet/profile/update');

    try {
      await secureStorageProvider.set(
        SecureStorageKeys.firstNameKey,
        profileModel.firstName,
      );
      await secureStorageProvider.set(
        SecureStorageKeys.lastNameKey,
        profileModel.lastName,
      );
      await secureStorageProvider.set(
        SecureStorageKeys.phoneKey,
        profileModel.phone,
      );
      await secureStorageProvider.set(
        SecureStorageKeys.locationKey,
        profileModel.location,
      );
      await secureStorageProvider.set(
        SecureStorageKeys.emailKey,
        profileModel.email,
      );
      await secureStorageProvider.set(
        SecureStorageKeys.companyName,
        profileModel.companyName,
      );
      await secureStorageProvider.set(
        SecureStorageKeys.companyWebsite,
        profileModel.companyWebsite,
      );
      await secureStorageProvider.set(
        SecureStorageKeys.jobTitle,
        profileModel.jobTitle,
      );
      await secureStorageProvider.set(
        SecureStorageKeys.issuerVerificationUrlKey,
        profileModel.issuerVerificationUrl,
      );

      await secureStorageProvider.set(
        SecureStorageKeys.isEnterpriseUser,
        profileModel.isEnterprise.toString(),
      );

      emit(state.success(model: profileModel));
    } catch (e) {
      log.severe('something went wrong', e);

      emit(
        state.error(
          messageHandler: ResponseMessage(
            ResponseString.RESPONSE_STRING_FAILED_TO_SAVE_PROFILE,
          ),
        ),
      );
    }
  }

  Future<void> updateIssuerVerificationUrl(
    IssuerVerificationRegistry registry,
  ) async {
    Logger('talao-wallet/profile/updateIssuerVerificationUrl');
    var _issuerVerificationUrl = Urls.checkIssuerTalaoUrl;
    switch (registry) {
      case IssuerVerificationRegistry.EBSI:
        _issuerVerificationUrl = Urls.checkIssuerEbsiUrl;
        break;
      case IssuerVerificationRegistry.None:
        _issuerVerificationUrl = '';
        break;
      case IssuerVerificationRegistry.Talao:
        _issuerVerificationUrl = Urls.checkIssuerTalaoUrl;
        break;
    }
    final _newModel =
        state.model.copyWith(issuerVerificationUrl: _issuerVerificationUrl);
    await update(_newModel);
  }
}
