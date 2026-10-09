import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Date/shamsi_converter.dart';
import 'package:zpharmacy/Features/Widgets/toast.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';
import 'package:zpharmacy/Features/zdropdown.dart';
import 'package:zpharmacy/View/Home/Ui/Prescription/prescription_details.dart';
import 'package:zpharmacy/l10n/app_localizations.dart';
import '../../../../Features/Date/z_range_picker.dart';
import '../../../../Features/Widgets/shimmer.dart';
import 'bloc/prescription_bloc.dart';
import 'model/prescription_model.dart';
import 'prescription_form.dart';

class PrescriptionView extends StatefulWidget {
  const PrescriptionView({super.key});

  @override
  State<PrescriptionView> createState() => _PrescriptionViewState();
}

class _PrescriptionViewState extends State<PrescriptionView> {
  // ---------------- Filters (what goes to the API) ----------------
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  String? _fromDate;   // null = no filter
  String? _toDate;
  String _statusLabel = 'All';
  bool _scopeAll = false;

  // ---------------- Picker display (always valid) ----------------
  late String _pickerStart;   // 'YYYY-MM-DD'
  late String _pickerEnd;

  // -----------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------
  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  String? get _statusValue {
    switch (_statusLabel) {
      case 'Dispensed':
        return 'DISPENSED';
      case 'Cancelled':
        return 'CANCELLED';
      default:
        return null;
    }
  }

  bool get _hasCustomDates => _fromDate != null && _toDate != null;

  void _reload() {
    context.read<PrescriptionBloc>().add(PrescriptionLoadRequested(
      search: _searchCtrl.text.trim().isEmpty
          ? null
          : _searchCtrl.text.trim(),
      from: _hasCustomDates ? _fromDate : null,
      to: _hasCustomDates ? _toDate : null,
      status: _statusValue,
      scopeAll: _scopeAll,
    ));
  }

  // -----------------------------------------------------------------
  // Lifecycle
  // -----------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _pickerStart = _fmt(now);
    _pickerEnd = _fmt(now);
    // Initial load: today (server default)
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // Filter handlers
  // -----------------------------------------------------------------
  void _onSearchChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _reload);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {});
    _reload();
  }

  void _setToday() {
    setState(() {
      final now = DateTime.now();
      _pickerStart = _fmt(now);
      _pickerEnd = _fmt(now);
      _fromDate = null;
      _toDate = null;
      _scopeAll = false;
    });
    _reload();
  }

  void _setAllTime() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _scopeAll = true;
    });
    _reload();
  }

  void _clearDates() {
    setState(() {
      final now = DateTime.now();
      _pickerStart = _fmt(now);
      _pickerEnd = _fmt(now);
      _fromDate = null;
      _toDate = null;
    });
    _reload();
  }

  void _onDateRangeChanged(String start, String end) {
    setState(() {
      _pickerStart = start;
      _pickerEnd = end;
      _fromDate = start;
      _toDate = end;
      _scopeAll = false;
    });
    _reload();
  }

  // -----------------------------------------------------------------
  // Add / View / Edit / Cancel
  // -----------------------------------------------------------------
  Future<void> _openAdd() async {
    final bloc = context.read<PrescriptionBloc>();
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const AddEditPrescriptionForm(),
      ),
    );
    bloc.add(const PrescriptionClearSelection());
    _reload();
  }

  Future<void> _openDetail(Prescription p) async {
    final bloc = context.read<PrescriptionBloc>();
    bloc.add(PrescriptionSelectRequested(p.prescriptionId));
    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: PrescriptionDetails(prescription: p),
      ),
    );
    bloc.add(const PrescriptionClearSelection());
  }

  Future<void> _openEdit(Prescription p) async {
    final bloc = context.read<PrescriptionBloc>();
    bloc.add(PrescriptionSelectRequested(p.prescriptionId));
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AddEditPrescriptionForm(existing: p),
      ),
    );
    bloc.add(const PrescriptionClearSelection());
    _reload();
  }

  Future<void> _confirmCancel(Prescription p) async {
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
          title: Text('Cancel ${p.registerNo}?'),
          content: const Text(
            'The prescription will be marked as CANCELLED and all '
                'dispensed stock will be returned to its batches.',
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Keep'),
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
                    child: const Text('Cancel Rx'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (ok == true && mounted) {
      context
          .read<PrescriptionBloc>()
          .add(PrescriptionCancelRequested(p.prescriptionId));
    }
  }

  // -----------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocListener<PrescriptionBloc, PrescriptionState>(
        listener: (context, state) {
          if (state is PrescriptionFailure) {
            ToastManager.show(
              context: context,
              title: 'Failed',
              message: state.message,
              type: ToastType.error,
            );
          }
          if (state is PrescriptionActionSuccess) {
            ToastManager.show(
              context: context,
              title: 'Success',
              message: state.message,
              type: ToastType.success,
            );
            _reload();
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ---- Icon badge ----
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 28,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),

                  // ---- Title ----
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.prescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),

                  // ---- Actions ----
                  Row(
                    spacing: 8,
                    children: [
                      ZOutlineButton(
                        onPressed: _reload,
                        icon: Icons.refresh,
                        label: Text("Refresh"),
                      ),
                      ZOutlineButton(
                        onPressed: _openAdd,
                        icon: Icons.add,
                        isActive: true,
                        label: Text("New Prescription"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // =====================================================
            // FILTER BAR
            // =====================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 2,
                    children: [
                      // ----- Search -----
                      Expanded(
                        flex: 6,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: _onSearchChanged,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _reload(),
                          decoration: InputDecoration(
                            hintText: 'Search Patient, Register No, Doctor',
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
                                vertical: 10, horizontal: 12),
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
                      const SizedBox(width: 10),

                      // ----- Date range picker -----
                      Expanded(
                        flex: 3,
                        child: ZRangeDatePicker(
                          label: 'Date range',
                          initialStartDate: DateTime.tryParse(_pickerStart),
                          initialEndDate: DateTime.tryParse(_pickerEnd),
                          startValue: _pickerStart,
                          endValue: _pickerEnd,
                          onStartDateChanged: (start) {
                            setState(() => _pickerStart = start);
                          },
                          onEndDateChanged: (end) {
                            setState(() => _pickerEnd = end);
                            if (_pickerStart.isNotEmpty &&
                                _pickerEnd.isNotEmpty) {
                              _onDateRangeChanged(_pickerStart, _pickerEnd);
                            }
                          },
                          minYear: 2020,
                          maxYear: 2100,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // ----- Status dropdown -----
                      Expanded(
                        flex: 2,
                        child: ZDropdown<String>(
                          title: 'Status',
                          items: const ['All', 'Dispensed', 'Cancelled'],
                          itemLabel: (v) => v,
                          selectedItem: _statusLabel,
                          initialValue: 'All',
                          radius: 4,
                          height: 40,
                          onItemSelected: (v) {
                            setState(() => _statusLabel = v);
                            _reload();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ----- Quick chips -----
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _Chip(
                        label: 'Today',
                        icon: Icons.today_outlined,
                        selected: !_hasCustomDates && !_scopeAll,
                        onTap: _setToday,
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        label: 'All time',
                        icon: Icons.all_inclusive,
                        selected: _scopeAll && !_hasCustomDates,
                        onTap: _setAllTime,
                      ),
                      if (_hasCustomDates) ...[
                        const SizedBox(width: 8),
                        _Chip(
                          label: '$_fromDate → $_toDate',
                          icon: Icons.date_range_outlined,
                          selected: true,
                          onTap: () {},
                          trailing: Icon(
                            Icons.close,
                            size: 14,
                            color: scheme.onSecondaryContainer,
                          ),
                          onTrailingTap: _clearDates,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // =====================================================
            // LIST
            // =====================================================
            Expanded(
              child: BlocBuilder<PrescriptionBloc, PrescriptionState>(
                builder: (context, state) {
                  if (state is PrescriptionLoading) {
                    return UniversalShimmer.dataList(
                      itemCount: 15,
                      numberOfColumns: 5,
                    );
                  }
                  if (state is PrescriptionFailure) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                size: 56, color: scheme.error),
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: scheme.error),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _reload,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final items = state is PrescriptionWithItems
                      ? state.items
                      : const <Prescription>[];

                  if (items.isEmpty) {
                    return _EmptyState(
                      search: _searchCtrl.text.trim(),
                      scopeAll: _scopeAll,
                      hasCustomDates: _hasCustomDates,
                      status: _statusLabel,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: items.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PrescriptionCard(
                          prescription: items[i],
                          onTap: () => _openDetail(items[i]),
                          onEdit: () => _openEdit(items[i]),
                          onCancel: items[i].isCancelled
                              ? null
                              : () => _confirmCancel(items[i]),
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
// Chip
// =====================================================================
class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;
  final VoidCallback? onTrailingTap;

  const _Chip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
    this.trailing,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? scheme.secondaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onTrailingTap,
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Empty state
// =====================================================================
class _EmptyState extends StatelessWidget {
  final String search;
  final bool scopeAll;
  final bool hasCustomDates;
  final String status;

  const _EmptyState({
    required this.search,
    required this.scopeAll,
    required this.hasCustomDates,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    String message;
    IconData icon;
    if (search.isNotEmpty) {
      message = 'No prescriptions match "$search"';
      icon = Icons.search_off;
    } else if (hasCustomDates) {
      message = 'No prescriptions in this date range';
      icon = Icons.date_range_outlined;
    } else if (status == 'Cancelled') {
      message = 'No cancelled prescriptions';
      icon = Icons.cancel_outlined;
    } else if (status == 'Dispensed') {
      message = 'No dispensed prescriptions';
      icon = Icons.receipt_long_outlined;
    } else if (scopeAll) {
      message = 'No prescriptions yet';
      icon = Icons.receipt_long_outlined;
    } else {
      message = 'No prescriptions for today';
      icon = Icons.today_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              scopeAll || hasCustomDates
                  ? 'Try a different filter'
                  : 'Tap "New Prescription" to create one',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
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
// Compact card
// =====================================================================
class _PrescriptionCard extends StatelessWidget {
  final Prescription prescription;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onCancel;

  const _PrescriptionCard({
    required this.prescription,
    required this.onTap,
    required this.onEdit,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cancelled = prescription.isCancelled;

    final meta = <String>[
      prescription.registerNo,
      '${prescription.gender[0]}, ${prescription.age}',
      '${prescription.itemCount} item${prescription.itemCount == 1 ? '' : 's'}',
      "${prescription.prescriptionDate.toFormattedDate()} | ${prescription.prescriptionDate.shamsiDateFormatted}",
    ].join('  ·  ');

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cancelled
                      ? scheme.errorContainer
                      : scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  prescription.patientName.isNotEmpty
                      ? prescription.patientName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cancelled
                        ? scheme.onErrorContainer
                        : scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      prescription.patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration:
                        cancelled ? TextDecoration.lineThrough : null,
                        decorationColor: scheme.onSurfaceVariant,
                        color: cancelled
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cancelled ? scheme.error : scheme.secondary,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 32,
                height: 32,
                child: PopupMenuButton<_MenuAction>(
                  tooltip: 'More',
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                  position: PopupMenuPosition.under,
                  onSelected: (a) {
                    switch (a) {
                      case _MenuAction.view:
                        onTap();
                        break;
                      case _MenuAction.edit:
                        onEdit();
                        break;
                      case _MenuAction.cancel:
                        onCancel?.call();
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: _MenuAction.view,
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('View'),
                        ],
                      ),
                    ),
                    if (!cancelled)
                      const PopupMenuItem(
                        value: _MenuAction.edit,
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (onCancel != null)
                      PopupMenuItem(
                        value: _MenuAction.cancel,
                        child: Row(
                          children: [
                            Icon(Icons.cancel_outlined,
                                size: 18, color: scheme.error),
                            const SizedBox(width: 10),
                            Text(
                              'Cancel Rx',
                              style: TextStyle(color: scheme.error),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MenuAction { view, edit, cancel }