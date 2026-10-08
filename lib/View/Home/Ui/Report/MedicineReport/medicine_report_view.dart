import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Date/z_range_picker.dart';

import 'bloc/medicine_report_bloc.dart';
import 'model/medicine_report_model.dart';

class MedicineReportView extends StatefulWidget {
  const MedicineReportView({super.key});

  @override
  State<MedicineReportView> createState() => _MedicineReportViewState();
}

class _MedicineReportViewState extends State<MedicineReportView> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  late String _pickerStart;
  late String _pickerEnd;
  String _from = '';
  String _to   = '';

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

    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<MedicineReportBloc>().add(MedicineReportLoadRequested(
      from:   _from,
      to:     _to,
      search: _searchCtrl.text.trim().isEmpty
          ? null
          : _searchCtrl.text.trim(),
    ));
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _reload);
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicines Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _reload,
          ),
          const SizedBox(width: 8),
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 6,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _reload(),
                    decoration: InputDecoration(
                      hintText: 'Search by name, brand, category, dosage',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                          _reload();
                        },
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      filled: true,
                      fillColor: scheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: scheme.outline.withValues(alpha: 0.4),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: scheme.outline.withValues(alpha: 0.4),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: scheme.primary,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
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
                      if (_pickerStart.isNotEmpty && _pickerEnd.isNotEmpty) {
                        _onDateChanged(_pickerStart, _pickerEnd);
                      }
                    },
                    minYear: 2020,
                    maxYear: 2100,
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
            child: BlocBuilder<MedicineReportBloc, MedicineReportState>(
              builder: (context, state) {
                if (state is MedicineReportInitial) {
                  return const Center(child: Text('Loading…'));
                }
                if (state is MedicineReportLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is MedicineReportFailure) {
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
                if (state is MedicineReportLoaded) {
                  return _ReportBody(report: state.report);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Report body
// =====================================================================
class _ReportBody extends StatelessWidget {
  final MedicineReport report;
  const _ReportBody({required this.report});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // -------- Summary header --------
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
                      const Text(
                        'Medicines Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
                      if (report.search != null) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(Icons.search,
                              size: 12, color: scheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Filter: "${report.search}"',
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
                    _pill(
                      scheme,
                      'Medicines',
                      '${report.medicineCount}',
                      scheme.surfaceContainerHighest,
                      scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    _pill(
                      scheme,
                      'In ${report.grandTotalIn}',
                      'Out ${report.grandTotalOut}',
                      scheme.secondaryContainer,
                      scheme.onSecondaryContainer,
                    ),
                    const SizedBox(height: 4),
                    _pill(
                      scheme,
                      'Balance',
                      '${report.grandBalance}',
                      scheme.primaryContainer,
                      scheme.onPrimaryContainer,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // -------- Table header --------
        _TableHeader(scheme: scheme),

        // -------- Rows --------
        Expanded(
          child: report.medicines.isEmpty
              ? const Center(child: Text('No medicines match the filter'))
              : ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: report.medicines.length,
            itemBuilder: (_, i) => _RowTile(
              row: report.medicines[i],
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
                  fontSize: 10,
                  color: fg,
                  fontWeight: FontWeight.w600)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  color: fg,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// =====================================================================
// Table header — new column order
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
          _h('Medicine', null, flex: 4),
          _h('Category', 130),
          _h('Organizations', null, flex: 3),
          _h('In', 60, align: TextAlign.right),
          _h('Out', 60, align: TextAlign.right),
          _h('Balance', 80, align: TextAlign.right),
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
// Row — same column order
// =====================================================================
class _RowTile extends StatelessWidget {
  final MedicineReportRow row;
  final ColorScheme scheme;
  final bool isOdd;

  const _RowTile({
    required this.row,
    required this.scheme,
    required this.isOdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: isOdd
            ? scheme.surfaceContainerLow.withValues(alpha: 0.5)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          // ---------- Medicine + meta ----------
          Expanded(
            flex: 4,
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
                const SizedBox(height: 2),
                Text(
                  [
                    if (row.dosage != null && row.dosage!.isNotEmpty)
                      row.dosage!,
                    row.unit,
                    if (row.companyBrand != null &&
                        row.companyBrand!.isNotEmpty)
                      row.companyBrand!,
                  ].join('  ·  '),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ---------- Category ----------
          SizedBox(
            width: 130,
            child: Text(
              row.catName,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ---------- Organizations (moved up) ----------
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                row.organizations ?? '—',
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),

          // ---------- In ----------
          SizedBox(
            width: 60,
            child: Text(
              row.totalIn > 0 ? '${row.totalIn}' : '',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.secondary,
              ),
            ),
          ),

          // ---------- Out ----------
          SizedBox(
            width: 60,
            child: Text(
              row.totalOut > 0 ? '${row.totalOut}' : '',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.error,
              ),
            ),
          ),

          // ---------- Balance (now at the very end) ----------
          SizedBox(
            width: 80,
            child: Text(
              '${row.balance}',
              textAlign: TextAlign.right,
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