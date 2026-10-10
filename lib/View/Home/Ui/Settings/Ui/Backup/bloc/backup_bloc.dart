import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../../../../Services/repository.dart';

part 'backup_event.dart';
part 'backup_state.dart';

class BackupBloc extends Bloc<BackupEvent, BackupState> {
  final Repositories _repo;

  BackupBloc(this._repo) : super(const BackupInitial()) {
    on<LoadBackupsEvent>(_onLoad);
    on<CheckCanCreateBackupEvent>(_onCheck);
    on<CreateBackupEvent>(_onCreate);
    on<DownloadBackupEvent>(_onDownload);
    on<DeleteBackupEvent>(_onDelete);
    on<RestoreBackupEvent>(_onRestore);
    on<PickAndRestoreBackupEvent>(_onPickAndRestore);
    on<CheckMysqlConnectionEvent>(_onCheckMysql);
    on<RenameBackupEvent>(_onRename);
    on<OpenBackupFolderEvent>(_onOpenFolder);
  }


  Future<void> _onRename(
      RenameBackupEvent e, Emitter<BackupState> emit) async {
    emit(const BackupInProgress('Renaming backup…'));
    try {
      final result = await _repo.renameBackup(e.fileName, e.newName);
      if (result['ok'] == false) {
        emit(BackupFailure((result['error'] ?? 'Rename failed').toString()));
        return;
      }
      final list = await _fetchList();
      final check = await _repo.canCreateBackup();
      emit(BackupActionSuccess(
        list,
        'Backup renamed',
        canCreate: check['canCreate'] == true,
        reason:    check['reason'] as String?,
      ));
    } catch (err) {
      emit(BackupFailure(err.toString()));
    }
  }

  Future<void> _onOpenFolder(
      OpenBackupFolderEvent e, Emitter<BackupState> emit) async {
    try {
      await _repo.openBackupFolder();
      // No state change — the folder opened on the server.
    } catch (err) {
      emit(BackupFailure('Could not open folder: ${err.toString()}'));
    }
  }

  // =================================================================
  // Helpers
  // =================================================================
  Future<List<BackupEntry>> _fetchList() async {
    final raw = await _repo.getBackupList();
    return raw.map(BackupEntry.fromJson).toList();
  }

  List<BackupEntry> _currentList() {
    return switch (state) {
      BackupsLoaded s        => s.backups,
      BackupActionSuccess s  => s.backups,
      BackupDownloaded s     => s.backups,
      _                      => const [],
    };
  }

  // =================================================================
  // Load list + check can-create
  // =================================================================
  Future<void> _onLoad(
      LoadBackupsEvent e, Emitter<BackupState> emit) async {
    emit(const BackupLoading());
    try {
      final list = await _fetchList();
      await Future.delayed(Duration(milliseconds: 500));
      final check = await _repo.canCreateBackup();
      emit(BackupsLoaded(
        list,
        canCreate: check['canCreate'] == true,
        reason:    check['reason'] as String?,
      ));
    } catch (err) {
      emit(BackupFailure(err.toString()));
    }
  }

  // =================================================================
  // Only re-check can-create; keep the list we already have
  // =================================================================
  Future<void> _onCheck(
      CheckCanCreateBackupEvent e, Emitter<BackupState> emit) async {
    try {
      final check = await _repo.canCreateBackup();
      final list = _currentList();
      emit(BackupsLoaded(
        list,
        canCreate: check['canCreate'] == true,
        reason:    check['reason'] as String?,
      ));
    } catch (_) {
      // Fail-open — leave can-create on, keep the list
      emit(BackupsLoaded(_currentList(), canCreate: true));
    }
  }

  // =================================================================
  // Create
  // =================================================================
  Future<void> _onCreate(
      CreateBackupEvent e, Emitter<BackupState> emit) async {
    emit(const BackupInProgress('Creating backup on server…'));
    try {
      final result = await _repo.createBackup();
      final skipped = result['skipped'] == true;

      final list = await _fetchList();
      final check = await _repo.canCreateBackup();

      emit(BackupActionSuccess(
        list,
        skipped ? 'No changes — backup skipped' : 'Backup created',
        canCreate: check['canCreate'] == true,
        reason:    check['reason'] as String?,
      ));
    } catch (err) {
      emit(BackupFailure(err.toString()));
    }
  }

  // =================================================================
  // Download
  // =================================================================
  Future<void> _onDownload(
      DownloadBackupEvent e, Emitter<BackupState> emit) async {
    emit(const BackupInProgress('Downloading backup…'));
    try {
      final file = await _repo.downloadBackup(e.fileName);
      final list = await _fetchList();
      final check = await _repo.canCreateBackup();

      emit(BackupDownloaded(
        list,
        file.path,
        canCreate: check['canCreate'] == true,
        reason:    check['reason'] as String?,
      ));
    } catch (err) {
      emit(BackupFailure(err.toString()));
    }
  }

  // =================================================================
  // Delete
  // =================================================================
  Future<void> _onDelete(
      DeleteBackupEvent e, Emitter<BackupState> emit) async {
    emit(const BackupInProgress('Deleting backup…'));
    try {
      await _repo.deleteBackup(e.fileName);
      final list = await _fetchList();
      final check = await _repo.canCreateBackup();

      emit(BackupActionSuccess(
        list,
        'Backup deleted',
        canCreate: check['canCreate'] == true,
        reason:    check['reason'] as String?,
      ));
    } catch (err) {
      emit(BackupFailure(err.toString()));
    }
  }

  // =================================================================
  // Restore (server-side backup)
  // =================================================================
  Future<void> _onRestore(
      RestoreBackupEvent e, Emitter<BackupState> emit) async {
    emit(const BackupInProgress('Creating safety backup…'));
    try {
      // Safety backup before restore — server may skip if nothing changed
      await _repo.createBackup();

      emit(const BackupInProgress('Restoring database…'));
      await _repo.restoreBackupFromServer(e.fileName);

      final list = await _fetchList();
      final check = await _repo.canCreateBackup();

      emit(BackupActionSuccess(
        list,
        'Database restored successfully',
        canCreate: check['canCreate'] == true,
        reason:    check['reason'] as String?,
      ));
    } catch (err) {
      emit(BackupFailure(err.toString()));
    }
  }

  // =================================================================
  // Pick a .sql from the device, upload, restore
  // =================================================================
  Future<void> _onPickAndRestore(
      PickAndRestoreBackupEvent e, Emitter<BackupState> emit) async {
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['sql'],
      );
      if (result == null || result.path == null) return; // cancelled

      emit(const BackupInProgress('Creating safety backup…'));
      await _repo.createBackup();

      emit(const BackupInProgress('Uploading and restoring…'));
      await _repo.restoreBackupFromUpload(File(result.path!));

      final list = await _fetchList();
      final check = await _repo.canCreateBackup();

      emit(BackupActionSuccess(
        list,
        'Database restored from file',
        canCreate: check['canCreate'] == true,
        reason:    check['reason'] as String?,
      ));
    } catch (err) {
      emit(BackupFailure(err.toString()));
    }
  }

  // =================================================================
  // MySQL check
  // =================================================================
  Future<void> _onCheckMysql(
      CheckMysqlConnectionEvent e, Emitter<BackupState> emit) async {
    emit(const BackupLoading());
    try {
      final data = await _repo.checkMysqlConnection();
      emit(MysqlStatus(
        data['connected'] == true,
        (data['message'] ?? '').toString(),
      ));
      final list = await _fetchList();
      final check = await _repo.canCreateBackup();
      emit(BackupsLoaded(
        list,
        canCreate: check['canCreate'] == true,
        reason:    check['reason'] as String?,
      ));
    } catch (err) {
      emit(BackupFailure(err.toString()));
    }
  }
}