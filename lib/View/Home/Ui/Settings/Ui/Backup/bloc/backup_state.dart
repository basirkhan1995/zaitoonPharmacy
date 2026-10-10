part of 'backup_bloc.dart';

class BackupEntry {
  final String fileName;
  final int sizeBytes;
  final DateTime modified;

  const BackupEntry({
    required this.fileName,
    required this.sizeBytes,
    required this.modified,
  });

  factory BackupEntry.fromJson(Map<String, dynamic> j) => BackupEntry(
    fileName:  j['fileName']  as String,
    sizeBytes: (j['sizeBytes'] as num).toInt(),
    modified:  DateTime.parse(j['modified'].toString()),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is BackupEntry &&
              other.fileName == fileName &&
              other.sizeBytes == sizeBytes &&
              other.modified == modified);

  @override
  int get hashCode => Object.hash(fileName, sizeBytes, modified);
}

sealed class BackupState extends Equatable {
  const BackupState();

  @override
  List<Object?> get props => [];
}

final class BackupInitial extends BackupState {
  const BackupInitial();
}

final class BackupLoading extends BackupState {
  const BackupLoading();
}

final class BackupInProgress extends BackupState {
  final String message;
  const BackupInProgress(this.message);

  @override
  List<Object?> get props => [message];
}

final class BackupsLoaded extends BackupState {
  final List<BackupEntry> backups;
  final bool canCreate;
  final String? reason;

  const BackupsLoaded(
      this.backups, {
        this.canCreate = true,
        this.reason,
      });

  @override
  List<Object?> get props => [backups, canCreate, reason];
}

final class BackupActionSuccess extends BackupState {
  final List<BackupEntry> backups;
  final String message;
  final bool canCreate;
  final String? reason;

  const BackupActionSuccess(
      this.backups,
      this.message, {
        this.canCreate = true,
        this.reason,
      });

  @override
  List<Object?> get props => [backups, message, canCreate, reason];
}

final class BackupDownloaded extends BackupState {
  final List<BackupEntry> backups;
  final String savedPath;
  final bool canCreate;
  final String? reason;

  const BackupDownloaded(
      this.backups,
      this.savedPath, {
        this.canCreate = true,
        this.reason,
      });

  @override
  List<Object?> get props => [backups, savedPath, canCreate, reason];
}

final class BackupFailure extends BackupState {
  final String message;
  const BackupFailure(this.message);

  @override
  List<Object?> get props => [message];
}

final class MysqlStatus extends BackupState {
  final bool connected;
  final String message;

  const MysqlStatus(this.connected, this.message);

  @override
  List<Object?> get props => [connected, message];
}