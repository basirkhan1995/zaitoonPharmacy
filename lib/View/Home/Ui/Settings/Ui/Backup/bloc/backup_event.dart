part of 'backup_bloc.dart';

sealed class BackupEvent extends Equatable {
  const BackupEvent();

  @override
  List<Object?> get props => [];
}

class LoadBackupsEvent extends BackupEvent {
  const LoadBackupsEvent();
}

class CheckCanCreateBackupEvent extends BackupEvent {
  const CheckCanCreateBackupEvent();
}

class CreateBackupEvent extends BackupEvent {
  const CreateBackupEvent();
}

class DownloadBackupEvent extends BackupEvent {
  final String fileName;
  const DownloadBackupEvent(this.fileName);

  @override
  List<Object?> get props => [fileName];
}

class DeleteBackupEvent extends BackupEvent {
  final String fileName;
  const DeleteBackupEvent(this.fileName);

  @override
  List<Object?> get props => [fileName];
}

class RestoreBackupEvent extends BackupEvent {
  final String fileName;
  const RestoreBackupEvent(this.fileName);

  @override
  List<Object?> get props => [fileName];
}

class PickAndRestoreBackupEvent extends BackupEvent {
  const PickAndRestoreBackupEvent();
}

class CheckMysqlConnectionEvent extends BackupEvent {
  const CheckMysqlConnectionEvent();
}

class RenameBackupEvent extends BackupEvent {
  final String fileName;
  final String newName;
  const RenameBackupEvent(this.fileName, this.newName);

  @override
  List<Object?> get props => [fileName, newName];
}

class OpenBackupFolderEvent extends BackupEvent {
  const OpenBackupFolderEvent();
}