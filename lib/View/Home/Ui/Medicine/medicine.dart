import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/toast.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';
import 'package:zpharmacy/l10n/app_localizations.dart';

import '../../../../Features/Widgets/shimmer.dart';
import '../Settings/Ui/Category/bloc/category_bloc.dart';
import 'add_edit_med.dart';
import 'bloc/medicine_bloc.dart';
import 'model/medicine_model.dart';

class MedicineView extends StatefulWidget {
  const MedicineView({super.key});

  @override
  State<MedicineView> createState() => _MedicineViewState();
}

class _MedicineViewState extends State<MedicineView> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _isUploadingExcel = false;

  @override
  void initState() {
    super.initState();
    context.read<MedicineBloc>().add(const MedicineLoadRequested());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final term = value.trim();
      context.read<MedicineBloc>().add(MedicineLoadRequested(search: term));
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {});
    context.read<MedicineBloc>().add(const MedicineLoadRequested());
  }

  void _reload() {
    context.read<MedicineBloc>().add(const MedicineLoadRequested());
  }

  // ===================================================================
  // EXCEL IMPORT
  // ===================================================================
  Future<void> _pickAndUploadExcel() async {
    final PlatformFile? picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    final path = picked?.path;
    if (path == null || !mounted) return;

    setState(() => _isUploadingExcel = true);
    context.read<MedicineBloc>().add(
      MedicineImportExcelRequested(File(path)),
    );
  }

  void _showExcelSummary(MedicineExcelUploadedState state) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasSkipped = state.skipped.isNotEmpty;
    final hasErrors = state.errors.isNotEmpty;
    final isPerfect = !hasSkipped && !hasErrors && state.inserted > 0;

    final accent = isPerfect ? Colors.green.shade600 : scheme.primary;
    final statusIcon =
    isPerfect ? Icons.check_circle_outline : Icons.info_outline;
    final statusText = isPerfect
        ? 'All rows imported successfully'
        : hasErrors
        ? 'Completed with errors'
        : 'Completed with skipped rows';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Column(
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: accent, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              'Import Complete',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: textTheme.bodySmall?.copyWith(color: scheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Stat row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: .35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _statItem(
                      '${state.inserted}',
                      'Inserted',
                      Colors.green.shade600,
                    ),
                    _divider(scheme),
                    _statItem(
                      '${state.skipped.length}',
                      'Skipped',
                      Colors.orange.shade700,
                    ),
                    _divider(scheme),
                    _statItem(
                      '${state.errors.length}',
                      'Errors',
                      scheme.error,
                    ),
                  ],
                ),
              ),

              // ── Detail lists
              if (hasSkipped || hasErrors) ...[
                const SizedBox(height: 14),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: .25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasSkipped) ...[
                          _sectionHeader(
                            'Skipped',
                            Icons.skip_next_rounded,
                            Colors.orange.shade700,
                          ),
                          const SizedBox(height: 4),
                          ...state.skipped.map((s) => _detailRow(
                            'Row ${s['row']}',
                            (s['reason'] ?? '').toString(),
                            textTheme,
                            scheme,
                          )),
                        ],
                        if (hasSkipped && hasErrors)
                          const SizedBox(height: 10),
                        if (hasErrors) ...[
                          _sectionHeader(
                            'Errors',
                            Icons.error_outline_rounded,
                            scheme.error,
                          ),
                          const SizedBox(height: 4),
                          ...state.errors.map((e) => _detailRow(
                            'Row ${e['row']}',
                            (e['error'] ?? '').toString(),
                            textTheme,
                            scheme,
                          )),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ZOutlineButton(
              isActive: true,
              onPressed: () => Navigator.of(dialogCtx).pop(),
              label: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, Color color) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    ),
  );

  Widget _divider(ColorScheme scheme) => Container(
    width: 1,
    height: 32,
    color: scheme.outline.withValues(alpha: .15),
  );

  Widget _sectionHeader(String title, IconData icon, Color color) => Row(
    children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 6),
      Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
          fontSize: 12.5,
        ),
      ),
    ],
  );

  Widget _detailRow(
      String rowLabel,
      String message,
      TextTheme tt,
      ColorScheme scheme,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3, left: 4),
      child: RichText(
        text: TextSpan(
          style: tt.bodySmall?.copyWith(
            color: scheme.onSurface,
            fontSize: 12,
          ),
          children: [
            TextSpan(
              text: '$rowLabel: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: message),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // Add / Edit
  // ===================================================================
  Future<void> _openAddEdit({Medicine? medicine}) async {
    final medicineBloc = context.read<MedicineBloc>();
    final categoryBloc = context.read<CategoryBloc>();

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: medicineBloc),
          BlocProvider.value(value: categoryBloc),
        ],
        child: AddEditMedicineDialog(medicine: medicine),
      ),
    );
  }

  // ===================================================================
  // Confirm delete
  // ===================================================================
  Future<void> _confirmDelete(Medicine m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          elevation: 0,
          backgroundColor: scheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: Text('Delete ${m.medName}?'),
          content: const Text('This action cannot be undone.'),
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
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (ok == true && mounted) {
      context.read<MedicineBloc>().add(MedicineDeleteRequested(m.medId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocListener<MedicineBloc, MedicineState>(
        listener: (context, state) {
          final isTerminalImportState =
              state is MedicineExcelUploadedState || state is MedicineFailure;

          if (isTerminalImportState && _isUploadingExcel) {
            setState(() => _isUploadingExcel = false);
          }
          if (state is MedicineFailure) {
            if (_isUploadingExcel) {
              setState(() => _isUploadingExcel = false);
            }
            ToastManager.show(
              context: context,
              title: AppLocalizations.of(context)!.failed,
              message: state.message,
              type: ToastType.error,
            );
          }
          if (state is MedicineActionSuccess) {
            ToastManager.show(
              context: context,
              title: AppLocalizations.of(context)!.successTitle,
              message: state.message,
              type: ToastType.success,
            );
          }
          // ── Excel summary
          if (state is MedicineExcelUploadedState) {
            if (_isUploadingExcel) {
              setState(() => _isUploadingExcel = false);
            }
            _showExcelSummary(state);
          }
        },
        child: Column(
          children: [
            // =====================================================
            // HEADER
            // =====================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_information_outlined,
                    size: 28,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.medicine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),

                  Row(
                    spacing: 8,
                    children: [
                      ZOutlineButton(
                        onPressed: _reload,
                        icon: Icons.refresh,
                        label: const Text('Refresh'),
                      ),
                      ZOutlineButton(
                        onPressed: _isUploadingExcel
                            ? null
                            : _pickAndUploadExcel,
                        backgroundHover: Colors.lightGreen,
                        icon: Icons.file_upload_outlined,
                        label: Text(
                          _isUploadingExcel ? 'Uploading…' : 'Import Excel',
                        ),
                      ),
                      ZOutlineButton(
                        onPressed: () => _openAddEdit(),
                        icon: Icons.add,
                        isActive: true,
                        label: const Text('New Medicine'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // =====================================================
            // SEARCH BAR
            // =====================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (v) => context
                    .read<MedicineBloc>()
                    .add(MedicineLoadRequested(search: v.trim())),
                decoration: InputDecoration(
                  hintText: 'Search medicine',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Clear',
                    onPressed: _clearSearch,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: BorderSide(
                      color: scheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: BorderSide(
                      color: scheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: BorderSide(
                      color: scheme.primary,
                      width: 1.1,
                    ),
                  ),
                ),
              ),
            ),

            // =====================================================
            // LIST
            // =====================================================
            Expanded(
              child: BlocBuilder<MedicineBloc, MedicineState>(
                builder: (context, state) {
                  if (state is MedicineLoading) {
                    return UniversalShimmer.dataList(
                      itemCount: 15,
                      numberOfColumns: 5,
                    );
                  }
                  if (state is MedicineFailure) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: _reload,
                    );
                  }

                  final items = state is MedicineWithItems
                      ? state.items
                      : const <Medicine>[];

                  if (items.isEmpty) {
                    final hasSearch = _searchCtrl.text.trim().isNotEmpty;
                    return _EmptyView(hasSearch: hasSearch);
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: items.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MedicineCard(
                          medicine: items[i],
                          onTap: () => _openAddEdit(medicine: items[i]),
                          onEdit: () => _openAddEdit(medicine: items[i]),
                          onDelete: () => _confirmDelete(items[i]),
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
}

// =====================================================================
// Card
// =====================================================================
class _MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicineCard({
    required this.medicine,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasStock = medicine.availableStock > 0;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Text(
                  medicine.medName.isNotEmpty
                      ? medicine.medName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.medName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (medicine.dosage != null &&
                            medicine.dosage!.isNotEmpty)
                          medicine.dosage!,
                        medicine.catName,
                        if (medicine.companyBrand != null &&
                            medicine.companyBrand!.isNotEmpty)
                          medicine.companyBrand!,
                      ].join('  •  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: hasStock
                      ? scheme.secondaryContainer
                      : scheme.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hasStock
                      ? '${medicine.availableStock}'
                      : AppLocalizations.of(context)!.noStock,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: hasStock
                        ? scheme.onSecondaryContainer
                        : scheme.onErrorContainer,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              PopupMenuButton<_MenuAction>(
                tooltip: 'More',
                icon: Icon(
                  Icons.more_vert,
                  color: scheme.onSurfaceVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
                position: PopupMenuPosition.under,
                onSelected: (action) {
                  switch (action) {
                    case _MenuAction.edit:
                      onEdit();
                      break;
                    case _MenuAction.delete:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _MenuAction.edit,
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        const Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _MenuAction.delete,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: scheme.error,
                        ),
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

enum _MenuAction { edit, delete }

// =====================================================================
// Empty view
// =====================================================================
class _EmptyView extends StatelessWidget {
  final bool hasSearch;
  const _EmptyView({required this.hasSearch});

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
              hasSearch ? Icons.search_off : Icons.medication_outlined,
              size: 56,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
            Text(
              hasSearch ? 'No matches' : 'No medicines yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasSearch
                  ? 'Try a different search term'
                  : 'Tap "New Medicine" to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
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
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}