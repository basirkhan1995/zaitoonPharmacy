import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Date/z_range_picker.dart';
import 'package:zpharmacy/Features/Widgets/toast.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';
import '../../../../../Features/Widgets/shimmer.dart';
import 'bloc/expiry_alert_bloc.dart';
import 'model/med_batch_model.dart';

class ExpiryAlertView extends StatefulWidget {
  const ExpiryAlertView({super.key});

  @override
  State<ExpiryAlertView> createState() => _ExpiryAlertViewState();
}

class _ExpiryAlertViewState extends State<ExpiryAlertView> {
  late String _pickerStart;
  late String _pickerEnd;
  String _from = '';
  String _to   = '';

  bool _onlyExpiring = true;
  bool _isExporting  = false;

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();

    // Default: "All" = 2020-01-01 → today + 6 months
    final now = DateTime.now();
    final end = DateTime(now.year, now.month + 6, now.day);
    _pickerStart = '2020-01-01';
    _pickerEnd   = _fmt(end);
    _from        = _pickerStart;
    _to          = _pickerEnd;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reload();
    });
  }

  void _reload() {
    context.read<ExpiryAlertBloc>().add(ExpiryAlertLoadRequested(
      from:         _onlyExpiring ? _from : null,
      to:           _onlyExpiring ? _to   : null,
      onlyExpiring: _onlyExpiring,
    ));
  }

  void _onDateChanged(String start, String end) {
    setState(() {
      _pickerStart = start;
      _pickerEnd   = end;
      _from        = start;
      _to          = end;
    });
    _reload();
  }

  void _setQuickRange(String key) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (key) {
      case 'all':
      // Covers expired + 3m + 6m
        start = DateTime(2020, 1, 1);
        end   = DateTime(now.year, now.month + 6, now.day);
        break;
      case '3m':
        start = now;
        end   = DateTime(now.year, now.month + 3, now.day);
        break;
      case '6m':
        start = now;
        end   = DateTime(now.year, now.month + 6, now.day);
        break;
      case 'expired':
        start = DateTime(2020, 1, 1);
        end   = now;
        break;
      default:
        return;
    }

    setState(() {
      _onlyExpiring = true;
      _pickerStart  = _fmt(start);
      _pickerEnd    = _fmt(end);
      _from         = _pickerStart;
      _to           = _pickerEnd;
    });
    _reload();
  }

  String? _activeQuickRange() {
    final now   = DateTime.now();
    final today = _fmt(now);

    // "All" = 2020-01-01 → today + 6m
    final allEnd = _fmt(DateTime(now.year, now.month + 6, now.day));
    if (_from == '2020-01-01' && _to == allEnd) return 'all';

    if (_from == today) {
      final d3 = DateTime(now.year, now.month + 3, now.day);
      final d6 = DateTime(now.year, now.month + 6, now.day);
      if (_to == _fmt(d3)) return '3m';
      if (_to == _fmt(d6)) return '6m';
    }
    if (_from == '2020-01-01' && _to == today) return 'expired';
    return null;
  }

  void _onExport() {
    context.read<ExpiryAlertBloc>().add(ExpiryAlertExportRequested(
      from:         _onlyExpiring ? _from : null,
      to:           _onlyExpiring ? _to   : null,
      onlyExpiring: _onlyExpiring,
    ));
  }

  Future<void> _saveExportedFile(ExpiryAlertExported s) async {
    final result = await FilePicker.saveFile(
      dialogTitle: 'Save expiry report',
      fileName: s.fileName,
      bytes: Uint8List.fromList(s.bytes),
    );
    if (result == null || !mounted) return;

    final path = result.toFilePath();
    ToastManager.show(
      context: context,
      title: 'Export Success',
      message: 'Saved to $path',
      type: ToastType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeQuick = _activeQuickRange();

    return BlocListener<ExpiryAlertBloc, ExpiryAlertState>(
      listener: (context, state) {
        if (state is! ExpiryAlertExporting && _isExporting) {
          setState(() => _isExporting = false);
        }
        if (state is ExpiryAlertExporting) {
          setState(() => _isExporting = true);
        }
        if (state is ExpiryAlertExported) {
          _saveExportedFile(state);
        }
        if (state is ExpiryAlertExportFailed) {
          ToastManager.show(
            context: context,
            title: 'Export Failed',
            message: state.message,
            type: ToastType.error,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expiry Alert'),
          actionsPadding: const EdgeInsets.all(10),
          actions: [
            ZOutlineButton(
              icon: Icons.refresh,
              label: const Text('Refresh'),
              onPressed: _isExporting ? null : _reload,
            ),
            const SizedBox(width: 8),
            ZOutlineButton(
              onPressed: _isExporting ? null : _onExport,
              isActive: true,
              icon: Icons.file_download_outlined,
              label: Text(_isExporting ? 'Exporting…' : 'Export Excel'),
            ),
          ],
        ),
        body: Column(
          children: [
            // ── FILTER BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 6,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // ── All (default)
                        _QuickChip(
                          label: 'All',
                          icon: Icons.all_inclusive,
                          selected: activeQuick == 'all',
                          onTap: () => _setQuickRange('all'),
                          scheme: scheme,
                        ),
                        // ── Expiring in 3 months
                        _QuickChip(
                          label: 'Expiring in 3 months',
                          icon: Icons.calendar_view_week_outlined,
                          selected: activeQuick == '3m',
                          onTap: () => _setQuickRange('3m'),
                          scheme: scheme,
                        ),
                        // ── Expiring in 6 months
                        _QuickChip(
                          label: 'Expiring in 6 months',
                          icon: Icons.calendar_view_month_outlined,
                          selected: activeQuick == '6m',
                          onTap: () => _setQuickRange('6m'),
                          scheme: scheme,
                        ),
                        // ── Already expired
                        _QuickChip(
                          label: 'Already expired',
                          icon: Icons.error_outline,
                          selected: activeQuick == 'expired',
                          onTap: () => _setQuickRange('expired'),
                          scheme: scheme,
                        ),
                        // ── Only expiring toggle — now in the same wrap
                        _ToggleSwitch(
                          value: _onlyExpiring,
                          label: 'Only expiring',
                          scheme: scheme,
                          onChanged: (v) {
                            setState(() => _onlyExpiring = v);
                            _reload();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Date range picker
                  Expanded(
                    flex: 2,
                    child: Opacity(
                      opacity: _onlyExpiring ? 1 : 0.5,
                      child: IgnorePointer(
                        ignoring: !_onlyExpiring,
                        child: ZRangeDatePicker(
                          height: 43,
                          label: 'Date range',
                          initialStartDate: DateTime.tryParse(_pickerStart),
                          initialEndDate: DateTime.tryParse(_pickerEnd),
                          startValue: _pickerStart,
                          endValue: _pickerEnd,
                          onStartDateChanged: (s) =>
                              setState(() => _pickerStart = s),
                          onEndDateChanged: (e) {
                            setState(() => _pickerEnd = e);
                            if (_pickerStart.isNotEmpty &&
                                _pickerEnd.isNotEmpty) {
                              _onDateChanged(_pickerStart, _pickerEnd);
                            }
                          },
                          minYear: 2020,
                          maxYear: 2100,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── REPORT
            Expanded(
              child: BlocBuilder<ExpiryAlertBloc, ExpiryAlertState>(
                builder: (context, state) {
                  if (state is ExpiryAlertInitial) {
                    return const Center(child: Text('Loading…'));
                  }
                  if (state is ExpiryAlertLoading) {
                    return UniversalShimmer.dataList(
                      itemCount: 15,
                      numberOfColumns: 5,
                    );
                  }
                  if (state is ExpiryAlertFailure) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                    );
                  }

                  final report = switch (state) {
                    ExpiryAlertLoaded s        => s.report,
                    ExpiryAlertExporting s     => s.report,
                    ExpiryAlertExported s      => s.report,
                    ExpiryAlertExportFailed s  => s.report,
                    _                          => null,
                  };

                  if (report != null) {
                    return _ReportBody(report: report);
                  }
                  return const SizedBox.shrink();
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
// Quick chip
// =====================================================================
class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _QuickChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? scheme.errorContainer : scheme.surfaceContainerLow;
    final fg = selected ? scheme.onErrorContainer : scheme.onSurfaceVariant;
    final border = selected
        ? scheme.error.withValues(alpha: 0.4)
        : scheme.outline.withValues(alpha: 0.25);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Toggle switch
// =====================================================================
class _ToggleSwitch extends StatelessWidget {
  final bool value;
  final String label;
  final ColorScheme scheme;
  final ValueChanged<bool> onChanged;

  const _ToggleSwitch({
    required this.value,
    required this.label,
    required this.scheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value
                ? scheme.primary.withValues(alpha: 0.4)
                : scheme.outline.withValues(alpha: 0.25),
          ),
          color: value
              ? scheme.primaryContainer.withValues(alpha: 0.3)
              : scheme.surfaceContainerLow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: value ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: value ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Report body — unchanged from your version
// =====================================================================
class _ReportBody extends StatelessWidget {
  final ExpiryAlertReport report;
  const _ReportBody({required this.report});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final expired = report.rows.where((r) => r.daysLeft < 0).length;
    final under30 = report.rows
        .where((r) => r.daysLeft >= 0 && r.daysLeft <= 30)
        .length;
    final under90 = report.rows
        .where((r) => r.daysLeft > 30 && r.daysLeft <= 90)
        .length;
    final totalQty = report.rows.fold<int>(
      0, (s, r) => s + r.quantityRemaining,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 18, color: scheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.onlyExpiring
                        ? 'Expiry Alert'
                        : 'All Active Batches',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                _pill(scheme, 'Batches', '${report.rows.length}',
                    scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                _pill(scheme, 'Expired', '$expired',
                    scheme.errorContainer, scheme.onErrorContainer),
                const SizedBox(width: 6),
                _pill(scheme, '≤30 days', '$under30',
                    const Color(0xFFFFEDD5), const Color(0xFF9A3412)),
                const SizedBox(width: 6),
                _pill(scheme, '≤90 days', '$under90',
                    const Color(0xFFFEF3C7), const Color(0xFF92400E)),
                const SizedBox(width: 6),
                _pill(scheme, 'Units', '$totalQty',
                    scheme.secondaryContainer, scheme.onSecondaryContainer),
              ],
            ),
          ),
        ),

        _TableHeader(scheme: scheme),

        Expanded(
          child: report.rows.isEmpty
              ? const Center(child: Text('No batches in this range'))
              : ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: report.rows.length,
            itemBuilder: (_, i) => _RowTile(
              index: i + 1,
              row: report.rows[i],
              scheme: scheme,
              isOdd: i.isOdd,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pill(ColorScheme scheme, String label, String value,
      Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label  ',
              style: TextStyle(
                  fontSize: 10, color: fg, fontWeight: FontWeight.w600)),
          Text(value,
              style: TextStyle(
                  fontSize: 12, color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// =====================================================================
// Table header
// =====================================================================
class _TableHeader extends StatelessWidget {
  final ColorScheme scheme;
  const _TableHeader({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          _h('#', 35, align: TextAlign.center),
          _h('Medicine', null, flex: 3),
          _h('Batch', 100),
          _h('Expiry', 90),
          _h('Days', 90, align: TextAlign.center),
          _h('Received From', null, flex: 2),
          _h('Qty', 70, align: TextAlign.right),
        ],
      ),
    );
  }

  Widget _h(String t, double? w,
      {int? flex, TextAlign align = TextAlign.left}) {
    final child = Text(
      t.toUpperCase(),
      textAlign: align,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: scheme.onSurfaceVariant,
      ),
    );
    return flex != null
        ? Expanded(flex: flex, child: child)
        : SizedBox(width: w, child: child);
  }
}

// =====================================================================
// Row — unchanged from your version
// =====================================================================
class _RowTile extends StatelessWidget {
  final int index;
  final ExpiryAlertRow row;
  final ColorScheme scheme;
  final bool isOdd;

  const _RowTile({
    required this.index,
    required this.row,
    required this.scheme,
    required this.isOdd,
  });

  @override
  Widget build(BuildContext context) {
    Color daysBg, daysFg;
    String daysLabel;
    if (row.daysLeft < 0) {
      daysBg = scheme.errorContainer;
      daysFg = scheme.onErrorContainer;
      daysLabel = 'EXPIRED';
    } else if (row.daysLeft <= 30) {
      daysBg = const Color(0xFFFFEDD5);
      daysFg = const Color(0xFF9A3412);
      daysLabel = '${row.daysLeft}d';
    } else if (row.daysLeft <= 90) {
      daysBg = const Color(0xFFFEF3C7);
      daysFg = const Color(0xFF92400E);
      daysLabel = '${row.daysLeft}d';
    } else {
      daysBg = scheme.secondaryContainer;
      daysFg = scheme.onSecondaryContainer;
      daysLabel = '${row.daysLeft}d';
    }

    final meta = [
      if (row.dosage != null && row.dosage!.isNotEmpty) row.dosage!,
      row.unit,
      row.catName,
    ].join('  ·  ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: isOdd
            ? scheme.surfaceContainerLow.withValues(alpha: 0.5)
            : Colors.transparent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 35,
            child: Text(
              '$index',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.medName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          SizedBox(
            width: 100,
            child: Text(
              row.batchNo,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          SizedBox(
            width: 90,
            child: Text(
              row.expiryDate,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: scheme.error,
              ),
            ),
          ),

          SizedBox(
            width: 90,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: daysBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  daysLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: daysFg,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.orgName ?? '—',
                    style: const TextStyle(fontSize: 11.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Received ${row.receivedDate}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(
            width: 70,
            child: Text(
              '${row.quantityRemaining}',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}