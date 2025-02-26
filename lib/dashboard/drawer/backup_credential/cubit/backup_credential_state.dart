part of 'backup_credential_cubit.dart';

@JsonSerializable()
class BackupCredentialState extends Equatable {
  const BackupCredentialState({
    this.status = AppStatus.init,
    this.message,
    this.filePath = '',
    this.mnemonic,
  });

  factory BackupCredentialState.fromJson(Map<String, dynamic> json) =>
      _$BackupCredentialStateFromJson(json);

  final AppStatus status;
  final StateMessage? message;
  final String filePath;
  final List<String>? mnemonic;

  BackupCredentialState loading() {
    return BackupCredentialState(
      status: AppStatus.loading,
      filePath: filePath,
      mnemonic: mnemonic,
    );
  }

  BackupCredentialState error({
    required MessageHandler messageHandler,
  }) {
    return BackupCredentialState(
      status: AppStatus.error,
      filePath: filePath,
      message: StateMessage.error(messageHandler: messageHandler),
      mnemonic: mnemonic,
    );
  }

  BackupCredentialState success({
    MessageHandler? messageHandler,
    String? filePath,
  }) {
    return BackupCredentialState(
      status: AppStatus.success,
      filePath: filePath ?? this.filePath,
      message: messageHandler == null
          ? null
          : StateMessage.success(messageHandler: messageHandler),
      mnemonic: mnemonic,
    );
  }

  BackupCredentialState setMnemonics({List<String>? mnemonic}) {
    return BackupCredentialState(
      status: AppStatus.populate,
      filePath: filePath,
      mnemonic: mnemonic ?? this.mnemonic,
    );
  }

  Map<String, dynamic> toJson() => _$BackupCredentialStateToJson(this);

  @override
  List<Object?> get props => [status, filePath, message, mnemonic];
}
