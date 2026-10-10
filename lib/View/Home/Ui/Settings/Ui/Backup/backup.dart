import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/shimmer.dart';
import 'package:zpharmacy/Features/Widgets/toast.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';

import 'bloc/backup_bloc.dart';

class BackupView extends StatefulWidget {
  const BackupView({super.key});

  @override
  State<BackupView> createState() => _BackupViewState();
}

class _BackupViewState extends State<BackupView> {
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BackupBloc>().add(const LoadBackupsEvent());
    });
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      context.read<BackupBloc>().add(const CheckCanCreateBackupEvent());
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  // ===================================================================
  // Actions
  // ===================================================================
  void _reload() {
    context.read<BackupBloc>().add(const LoadBackupsEvent());
  }

  void _createBackup() {
    context.read<BackupBloc>().add(const CreateBackupEvent());
  }

  Future<void> _pickAndRestore() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['sql'],
    );
    if (result == null || result.path == null) return;
    if (!mounted) return;

    final ok = await _confirm(
      title: 'Restore from file?',
      message: 'This will replace ALL current data with the contents of '
          '"${result.name}". A safety backup is created automatically '
          'before restoring.',
      confirmLabel: 'Restore',
      danger: true,
    );
    if (!ok || !mounted) return;

    context.read<BackupBloc>().add(const PickAndRestoreBackupEvent());
  }

  Future<void> _restore(BackupEntry entry) async {
    final ok = await _confirm(
      title: 'Restore "${entry.fileName}"?',
      message: 'This will replace ALL current data with the contents of '
          'this backup. A safety backup is created automatically first.',
      confirmLabel: 'Restore',
      danger: true,
    );
    if (!ok || !mounted) return;
    context.read<BackupBloc>().add(RestoreBackupEvent(entry.fileName));
  }

  Future<void> _delete(BackupEntry entry) async {
    final ok = await _confirm(
      title: 'Delete "${entry.fileName}"?',
      message: 'This backup file will be permanently removed from the '
          'server. This action cannot be undone.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!ok || !mounted) return;
    context.read<BackupBloc>().add(DeleteBackupEvent(entry.fileName));
  }

  void _download(BackupEntry entry) {
    context.read<BackupBloc>().add(DownloadBackupEvent(entry.fileName));
  }

  void _openFolder() {
    context.read<BackupBloc>().add(const OpenBackupFolderEvent());
  }

  Future<void> _rename(BackupEntry entry) async {
    // Strip .sql for the editable portion
    final baseName = entry.fileName.toLowerCase().endsWith('.sql')
        ? entry.fileName.substring(0, entry.fileName.length - 4)
        : entry.fileName;

    final ctrl = TextEditingController(text: baseName);
    ctrl.selection = TextSelection(
      baseOffset: 0,
      extentOffset: ctrl.text.length,
    );

    final newBase = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          elevation: 0,
          backgroundColor: scheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          title: const Text('Rename backup'),
          content: SizedBox(
            width: 360,
            child: TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'File name',
                suffixText: '.sql',
                suffixStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(
                    color: scheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(
                    color: scheme.primary,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () {
                      final base = ctrl.text
                          .trim()
                          .replaceAll(
                        RegExp(r'\.sql$', caseSensitive: false),
                        '',
                      );

                      if (base.isEmpty) return;

                      if (RegExp(r'[\\/:*?"<>|]').hasMatch(base)) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Name cannot contain  \\ / : * ? " < > |',
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.of(ctx).pop(base);
                    },
                    child: const Text('Rename'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (newBase == null) return;
    if (newBase == baseName) return;
    if (!mounted) return;

    context.read<BackupBloc>().add(
      RenameBackupEvent(entry.fileName, '$newBase.sql'),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool danger = false,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        elevation: 0,
        backgroundColor: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        title: Text(title),
        content: Text(message),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                    danger ? scheme.error : scheme.primary,
                    foregroundColor:
                    danger ? scheme.onError : scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return result == true;
  }

  // ===================================================================
  // Helpers
  // ===================================================================
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  static String _formatDate(DateTime d) {
    final y = d.year;
    final mo = d.month.toString().padLeft(2, '0');
    final da = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$y-$mo-$da  $h:$mi';
  }

  // ===================================================================
  // Build
  // ===================================================================
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocListener<BackupBloc, BackupState>(
        listener: (context, state) {
          if (state is BackupActionSuccess) {
            ToastManager.show(
              context: context,
              title: 'Success',
              message: state.message,
              type: ToastType.success,
            );
          }
          if (state is BackupDownloaded) {
            ToastManager.show(
              context: context,
              title: 'Downloaded',
              message: 'Saved to ${state.savedPath}',
              type: ToastType.info,
            );
          }
          if (state is BackupFailure) {
            ToastManager.show(
              context: context,
              title: 'Failed',
              message: state.message,
              type: ToastType.error,
            );
          }
        },
        child: Column(
          children: [
            // ── Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.storage_outlined,
                      size: 26,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Backup & Restore',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          'Create, download, and restore database backups',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  BlocBuilder<BackupBloc, BackupState>(
                    builder: (context, state) {
                      final creating = state is BackupLoading ||
                          state is BackupInProgress;
                      final canCreate = _canCreate(state);

                      return Row(
                        spacing: 8,
                        children: [
                          ZOutlineButton(
                            onPressed: creating ? null : _reload,
                            icon: Icons.refresh,
                            label: const Text('Refresh'),
                          ),
                          ZOutlineButton(
                            onPressed: creating ? null : _pickAndRestore,
                            icon: Icons.upload_file_outlined,
                            label: const Text('Restore from file'),
                          ),
                          Tooltip(
                            message: canCreate
                                ? 'Create a new backup of the database'
                                : 'No changes since last backup',
                            child: ZOutlineButton(
                              onPressed: (canCreate && !creating)
                                  ? _createBackup
                                  : null,
                              icon: Icons.cloud_upload_outlined,
                              isActive: true,
                              label: const Text('Create Backup'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── List
            Expanded(
              child: BlocBuilder<BackupBloc, BackupState>(
                builder: (context, state) {
                  if (state is BackupLoading) {
                    return UniversalShimmer.dataList(
                      itemCount: 10,
                      numberOfColumns: 5,
                    );
                  }
                  if (state is BackupInProgress) {
                    return _ProgressView(message: state.message);
                  }
                  if (state is BackupFailure) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: _reload,
                    );
                  }

                  final backups = _extractBackups(state);
                  if (backups == null) {
                    return UniversalShimmer.dataList(
                      itemCount: 10,
                      numberOfColumns: 2,
                    );
                  }
                  if (backups.isEmpty) {
                    return _EmptyView(onCreate: _createBackup);
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: backups.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _BackupCard(
                          entry:        backups[i],
                          onDownload:   () => _download(backups[i]),
                          onRestore:    () => _restore(backups[i]),
                          onRename:     () => _rename(backups[i]),
                          onOpenFolder: _openFolder,
                          onDelete:     () => _delete(backups[i]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canCreate(BackupState state) => switch (state) {
    BackupsLoaded s        => s.canCreate,
    BackupActionSuccess s  => s.canCreate,
    BackupDownloaded s     => s.canCreate,
    _                      => true,
  };

  List<BackupEntry>? _extractBackups(BackupState state) => switch (state) {
    BackupsLoaded s        => s.backups,
    BackupActionSuccess s  => s.backups,
    BackupDownloaded s     => s.backups,
    _                      => null,
  };
}

// =====================================================================
// Backup card
// =====================================================================
class _BackupCard extends StatefulWidget {
  final BackupEntry entry;
  final VoidCallback onDownload;
  final VoidCallback onRestore;
  final VoidCallback onRename;
  final VoidCallback onOpenFolder;
  final VoidCallback onDelete;

  const _BackupCard({
    required this.entry,
    required this.onDownload,
    required this.onRestore,
    required this.onRename,
    required this.onOpenFolder,
    required this.onDelete,
  });

  @override
  State<_BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends State<_BackupCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final e = widget.entry;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered
              ? scheme.surfaceContainer
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: _hovered
                ? scheme.primary.withValues(alpha: 0.35)
                : scheme.outline.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.dns_outlined,
                  size: 20,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.data_usage_outlined,
                          size: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _BackupViewState._formatBytes(e.sizeBytes),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.schedule_outlined,
                          size: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _BackupViewState._formatDate(e.modified),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Download to device',
                onPressed: widget.onDownload,
                icon: Icon(
                  Icons.download_outlined,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ),

              PopupMenuButton<_BackupMenu>(
                tooltip: 'More',
                icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                elevation: 2,
                position: PopupMenuPosition.under,
                onSelected: (a) {
                  switch (a) {
                    case _BackupMenu.restore:
                      widget.onRestore();
                      break;
                    case _BackupMenu.download:
                      widget.onDownload();
                      break;
                    case _BackupMenu.rename:
                      widget.onRename();
                      break;
                    case _BackupMenu.folder:
                      widget.onOpenFolder();
                      break;
                    case _BackupMenu.delete:
                      widget.onDelete();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: _BackupMenu.restore,
                    child: Row(
                      children: [
                        Icon(Icons.restore_rounded,
                            size: 18, color: Colors.orange),
                        SizedBox(width: 10),
                        Text('Restore'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: _BackupMenu.download,
                    child: Row(
                      children: [
                        Icon(Icons.download_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Download to device'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: _BackupMenu.rename,
                    child: Row(
                      children: [
                        Icon(Icons.drive_file_rename_outline, size: 18),
                        SizedBox(width: 10),
                        Text('Rename'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: _BackupMenu.folder,
                    child: Row(
                      children: [
                        Icon(Icons.folder_open_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Show in folder'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _BackupMenu.delete,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: scheme.error),
                        const SizedBox(width: 10),
                        Text(
                          'Delete',
                          style: TextStyle(color: scheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _BackupMenu { restore, download, rename, folder, delete }

// =====================================================================
// Progress view
// =====================================================================
class _ProgressView extends StatelessWidget {
  final String message;
  const _ProgressView({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Empty view
// =====================================================================
class _EmptyView extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyView({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storage_outlined,
              size: 56,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
            Text(
              'No backups yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap "Create Backup" to make your first one',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ZOutlineButton(
              onPressed: onCreate,
              icon: Icons.cloud_upload_outlined,
              isActive: true,
              label: const Text('Create Backup'),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Error view
// =====================================================================
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: scheme.error),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}