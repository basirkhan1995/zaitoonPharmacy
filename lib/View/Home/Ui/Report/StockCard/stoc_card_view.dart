import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Date/z_range_picker.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';
import '../../../../../Features/Widgets/shimmer.dart';
import '../../../../../Features/Widgets/toast.dart';
import '../../Medicine/bloc/medicine_bloc.dart';
import '../../Medicine/medcine_field.dart';
import '../../Medicine/model/medicine_model.dart';
import 'bloc/stock_card_bloc.dart';
import 'model/stock_card_model.dart';

class StockCardView extends StatefulWidget {
  final Medicine? initialMedicine;

  const StockCardView({super.key, this.initialMedicine});

  @override
  State<StockCardView> createState() => _StockCardViewState();
}

class _StockCardViewState extends State<StockCardView> {
  Medicine? _medicine;
  final _batchCtrl = TextEditingController();

  late String _pickerStart;
  late String _pickerEnd;
  String _from = '';
  String _to   = '';

  bool _isExporting = false;

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();

    final now   = DateTime.now();
    final start = now.subtract(const Duration(days: 30));

    _pickerStart = _fmt(start);
    _pickerEnd   = _fmt(now);
    _from        = _pickerStart;
    _to          = _pickerEnd;

    _medicine = widget.initialMedicine;

    context.read<MedicineBloc>().add(const MedicineLoadRequested());

    if (_medicine != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _reload();
      });
    }
  }

  @override
  void dispose() {
    _batchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    if (_medicine == null) return;
    if (_from.isEmpty || _to.isEmpty) return;

    context.read<StockCardBloc>().add(StockCardLoadRequested(
      medId:   _medicine!.medId,
      from:    _from,
      to:      _to,
      batchNo: _batchCtrl.text.trim().isEmpty
          ? null
          : _batchCtrl.text.trim(),
    ));
  }

  void _onMedicineChanged(Medicine? m) {
    setState(() {
      _medicine = m;
      _batchCtrl.clear();
    });
    if (m != null) {
      _reload();
    } else {
      context.read<StockCardBloc>().add(const StockCardClear());
    }
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

  void _clearBatch() {
    _batchCtrl.clear();
    setState(() {});
    _reload();
  }

  // ── Export
  void _onExport() {
    if (_medicine == null || _from.isEmpty || _to.isEmpty) return;
    context.read<StockCardBloc>().add(StockCardExportRequested(
      medId:   _medicine!.medId,
      from:    _from,
      to:      _to,
      batchNo: _batchCtrl.text.trim().isEmpty
          ? null
          : _batchCtrl.text.trim(),
    ));
  }

  Future<void> _saveExportedFile(StockCardExported s) async {
    final result = await FilePicker.saveFile(
      dialogTitle: 'Save stock card',
      fileName: s.fileName,
      bytes: Uint8List.fromList(s.bytes),
    );
    if (result == null || !mounted) return;

    final path = result.toFilePath();
    ToastManager.show(context: context,title: "Export Success", message: 'Saved to $path', type: ToastType.info);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocListener<StockCardBloc, StockCardState>(
      listener: (context, state) {
        // Sync `_isExporting` with bloc state
        if (state is! StockCardExporting && _isExporting) {
          setState(() => _isExporting = false);
        }
        if (state is StockCardExporting) {
          setState(() => _isExporting = true);
        }

        if (state is StockCardExported) {
          _saveExportedFile(state);
        }
        if (state is StockCardExportFailed) {
          ToastManager.show(context: context,title: "Export Failed", message: 'Failed to export Excel', type: ToastType.error);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: const Text('Stock Card'),
          actionsPadding: const EdgeInsets.all(10),
          actions: [
            ZOutlineButton(
              icon: Icons.refresh,
              label: const Text('Refresh'),
              onPressed: _isExporting ? null : _reload,
            ),
            const SizedBox(width: 8),
            ZOutlineButton(
              backgroundHover: Theme.of(context).colorScheme.secondary,
              onPressed: (_medicine == null || _isExporting)
                  ? null
                  : _onExport,
              isActive: true,
              icon: Icons.file_download_outlined,
              label: Text(_isExporting ? 'Exporting…' : 'Export Excel'),
            ),
          ],
        ),
        body: Column(
          children: [
            // =====================================================
            // FILTER BAR
            // =====================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Medicine
                  Expanded(
                    flex: 7,
                    child: MedicineSearchField(
                      initial: _medicine,
                      label: 'Medicine *',
                      hintText: 'Search medicine',
                      onSelected: _onMedicineChanged,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Date range
                  Expanded(
                    flex: 3,
                    child: ZRangeDatePicker(
                      height: 40,
                      label: 'Date range',
                      initialStartDate: DateTime.tryParse(_pickerStart),
                      initialEndDate: DateTime.tryParse(_pickerEnd),
                      startValue: _pickerStart,
                      endValue: _pickerEnd,
                      onStartDateChanged: (s) =>
                          setState(() => _pickerStart = s),
                      onEndDateChanged: (e) {
                        setState(() => _pickerEnd = e);
                        if (_pickerStart.isNotEmpty && _pickerEnd.isNotEmpty) {
                          _onDateChanged(_pickerStart, _pickerEnd);
                        }
                      },
                      minYear: 2020,
                      maxYear: 2100,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Batch filter
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batch (optional)',
                          style: TextStyle(fontSize: 12, color: scheme.outline),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _batchCtrl,
                          onSubmitted: (_) => _reload(),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'RQ980',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 12),
                            prefixIcon: const Icon(Icons.qr_code_2_outlined,
                                size: 18),
                            suffixIcon: _batchCtrl.text.isEmpty
                                ? null
                                : IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              tooltip: 'Clear',
                              onPressed: _clearBatch,
                            ),
                            filled: true,
                            fillColor: scheme.surfaceContainerLow,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                  color: scheme.outline.withValues(alpha: 0.4)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                  color: scheme.outline.withValues(alpha: 0.4)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                  color: scheme.primary, width: 1.2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // =====================================================
            // REPORT
            // =====================================================
            Expanded(
              child: BlocBuilder<StockCardBloc, StockCardState>(
                builder: (context, state) {
                  if (state is StockCardInitial) {
                    return const _EmptyPrompt();
                  }
                  if (state is StockCardLoading) {
                    return UniversalShimmer.dataList(
                      itemCount: 15,
                      numberOfColumns: 5,
                    );
                  }
                  if (state is StockCardFailure) {
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

                  // All export states carry the report — keep showing the table
                  final report = switch (state) {
                    StockCardLoaded s         => s.report,
                    StockCardExporting s      => s.report,
                    StockCardExported s       => s.report,
                    StockCardExportFailed s   => s.report,
                    _                         => null,
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
// Report body
// =====================================================================
class _ReportBody extends StatelessWidget {
  final StockCardReport report;
  const _ReportBody({required this.report});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final med = report.medicine;

    return Column(
      children: [
        // -------- Medicine header --------
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med['med_name']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if ((med['dosage'] ?? '').toString().isNotEmpty)
                            med['dosage'].toString(),
                          if ((med['cat_name'] ?? '').toString().isNotEmpty)
                            med['cat_name'].toString(),
                          if ((med['company_brand'] ?? '')
                              .toString()
                              .isNotEmpty)
                            med['company_brand'].toString(),
                        ].join('  •  '),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${report.fromDate}  →  ${report.toDate}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant
                              .withValues(alpha: 0.75),
                        ),
                      ),
                      if (report.batchFilter != null) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(Icons.qr_code_2_outlined,
                              size: 12, color: scheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Batch filter: ${report.batchFilter}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: scheme.primary,
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _pill(scheme, 'Opening', '${report.openingBalance}',
                        scheme.surfaceContainerHighest,
                        scheme.onSurfaceVariant),
                    const SizedBox(height: 4),
                    _pill(
                        scheme,
                        'In ${report.totalIn}',
                        'Out ${report.totalOut}',
                        scheme.secondaryContainer,
                        scheme.onSecondaryContainer),
                    const SizedBox(height: 4),
                    _pill(scheme, 'Closing', '${report.closingBalance}',
                        scheme.primaryContainer,
                        scheme.onPrimaryContainer),
                  ],
                ),
              ],
            ),
          ),
        ),

        // -------- Batch summary (only when filtered) --------
        if (report.batchSummary != null && report.batchSummary!.isNotEmpty)
          _BatchSummaryStrip(batches: report.batchSummary!),

        // -------- Table header --------
        _TableHeader(scheme: scheme),

        // -------- Rows --------
        Expanded(
          child: report.movements.isEmpty
              ? const Center(child: Text('No movements in this range'))
              : ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: report.movements.length,
            itemBuilder: (_, i) => _RowTile(
              row: report.movements[i],
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
// Batch summary strip
// =====================================================================
class _BatchSummaryStrip extends StatelessWidget {
  final List<BatchSummary> batches;
  const _BatchSummaryStrip({required this.batches});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: scheme.tertiary.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.qr_code_2_outlined,
                  size: 14, color: scheme.onTertiaryContainer),
              const SizedBox(width: 6),
              Text(
                'Matching batches',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onTertiaryContainer,
                  letterSpacing: 0.4,
                ),
              ),
            ]),
            const SizedBox(height: 6),
            ...batches.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      b.batchNo,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: Row(children: [
                      Icon(Icons.event_busy_outlined,
                          size: 11, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        b.expiryDate,
                        style: TextStyle(
                            fontSize: 11.5,
                            color: scheme.onSurfaceVariant),
                      ),
                    ]),
                  ),
                  SizedBox(
                    width: 130,
                    child: Text(
                      'Recv ${b.receivedDate}',
                      style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${b.quantityRemaining} / ${b.quantityReceived}',
                      style: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: b.status == 'ACTIVE'
                          ? scheme.secondaryContainer
                          : scheme.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      b.status,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: b.status == 'ACTIVE'
                            ? scheme.onSecondaryContainer
                            : scheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
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
          _h('Date', 80),
          _h('Type', 130),
          _h('Batch / Expiry', 140),
          _h('Org / Ref', null, flex: 1),
          _h('In', 60, align: TextAlign.right),
          _h('Out', 60, align: TextAlign.right),
          _h('Bal', 65, align: TextAlign.right),
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
// Row
// =====================================================================
class _RowTile extends StatelessWidget {
  final StockCardRow row;
  final ColorScheme scheme;
  final bool isOdd;

  const _RowTile({
    required this.row,
    required this.scheme,
    required this.isOdd,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _typeStyle(row.type, scheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: isOdd
            ? scheme.surfaceContainerLow.withValues(alpha: 0.6)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          // Date
          SizedBox(
            width: 80,
            child: Text(row.date, style: const TextStyle(fontSize: 11.5)),
          ),

          // Type
          SizedBox(
            width: 130,
            child: Row(
              children: [
                Icon(meta.icon, size: 13, color: meta.color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    meta.label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: meta.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Batch + Expiry
          SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.batchNo ?? '—',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (row.expiryDate != null && row.expiryDate!.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "EXP",
                        style: TextStyle(fontSize: 10,color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        row.expiryDate!,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: scheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Org / Ref
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (row.orgName != null && row.orgName!.isNotEmpty)
                  Text(row.orgName!,
                      style: const TextStyle(fontSize: 11.5),
                      overflow: TextOverflow.ellipsis),
                if (row.reference != null)
                  Text(row.reference!,
                      style: TextStyle(
                          fontSize: 10.5, color: scheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis),
                if (row.patientName != null)
                  Text(row.patientName!,
                      style: TextStyle(
                          fontSize: 10.5, color: scheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          // In
          SizedBox(
            width: 60,
            child: Text(
              row.inQty > 0 ? '${row.inQty}' : '',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.secondary,
              ),
            ),
          ),

          // Out
          SizedBox(
            width: 60,
            child: Text(
              row.outQty > 0 ? '${row.outQty}' : '',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.error,
              ),
            ),
          ),

          // Balance
          SizedBox(
            width: 65,
            child: Text(
              '${row.balance}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _TypeStyle _typeStyle(String type, ColorScheme scheme) {
    switch (type) {
      case 'RECEIVE':
        return _TypeStyle(
            'Received', Icons.move_to_inbox_outlined, scheme.primary);
      case 'DONATION_IN':
        return _TypeStyle('Donation In',
            Icons.volunteer_activism_outlined, scheme.tertiary);
      case 'DONATION_OUT':
        return _TypeStyle(
            'Donation Out', Icons.outbox_outlined, scheme.secondary);
      case 'DISPENSE':
        return _TypeStyle('Prescribed',
            Icons.receipt_long_outlined, scheme.primary);
      case 'ADJUSTMENT':
        return _TypeStyle('Adjustment', Icons.tune_outlined,
            scheme.onSurfaceVariant);
      case 'EXPIRED':
        return _TypeStyle('Expired', Icons.schedule_outlined, scheme.error);
      case 'DAMAGE':
        return _TypeStyle('Damage',
            Icons.report_gmailerrorred_outlined, scheme.error);
      case 'RETURN':
        return _TypeStyle('Return', Icons.undo_outlined, scheme.tertiary);
      default:
        return _TypeStyle(
            type, Icons.circle_outlined, scheme.onSurfaceVariant);
    }
  }
}

class _TypeStyle {
  final String label;
  final IconData icon;
  final Color color;
  _TypeStyle(this.label, this.icon, this.color);
}

// =====================================================================
// Empty prompt
// =====================================================================
class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assessment_outlined,
                size: 56,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 14),
            Text(
              'Pick a medicine to see its stock card',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}