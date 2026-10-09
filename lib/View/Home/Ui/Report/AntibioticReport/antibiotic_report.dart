import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Date/z_range_picker.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';
import '../../../../../Features/Widgets/shimmer.dart';
import 'bloc/antibiotic_report_bloc.dart';
import 'model/antibiotic_model.dart';

class AntibioticReportView extends StatefulWidget {
  const AntibioticReportView({super.key});

  @override
  State<AntibioticReportView> createState() => _AntibioticReportViewState();
}

class _AntibioticReportViewState extends State<AntibioticReportView> {
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
    final start = DateTime(now.year, now.month, 1);
    _pickerStart = _fmt(start);
    _pickerEnd   = _fmt(now);
    _from        = _pickerStart;
    _to          = _pickerEnd;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reload();
    });
  }

  void _reload() {
    if (_from.isEmpty || _to.isEmpty) return;
    context.read<AntibioticReportBloc>().add(
      AntibioticReportLoadRequested(from: _from, to: _to),
    );
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

  void _onExport() {
    if (_from.isEmpty || _to.isEmpty) return;
    context.read<AntibioticReportBloc>().add(
      AntibioticReportExportRequested(from: _from, to: _to),
    );
  }

  Future<void> _saveExportedFile(AntibioticReportExported s) async {
    final result = await FilePicker.saveFile(
      dialogTitle: 'Save antibiotic form',
      fileName: s.fileName,
      bytes: Uint8List.fromList(s.bytes),
    );
    if (result == null || !mounted) return;

    final path = result.toFilePath();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved to $path'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocListener<AntibioticReportBloc, AntibioticReportState>(
      listener: (context, state) {
        if (state is! AntibioticReportExporting && _isExporting) {
          setState(() => _isExporting = false);
        }
        if (state is AntibioticReportExporting) {
          setState(() => _isExporting = true);
        }
        if (state is AntibioticReportExported) {
          _saveExportedFile(state);
        }
        if (state is AntibioticReportExportFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: ${state.message}'),
              backgroundColor: scheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Antibiotic Form'),
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
                children: [
                  const Expanded(flex: 6, child: SizedBox()),
                  Expanded(
                    flex: 4,
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

            // ── REPORT
            Expanded(
              child: BlocBuilder<AntibioticReportBloc, AntibioticReportState>(
                builder: (context, state) {
                  if (state is AntibioticReportInitial) {
                    return const Center(child: Text('Loading…'));
                  }
                  if (state is AntibioticReportLoading) {
                    return UniversalShimmer.dataList(
                      itemCount: 15,
                      numberOfColumns: 5,
                    );
                  }
                  if (state is AntibioticReportFailure) {
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
                    AntibioticReportLoaded s          => s.report,
                    AntibioticReportExporting s       => s.report,
                    AntibioticReportExported s        => s.report,
                    AntibioticReportExportFailed s    => s.report,
                    _                                 => null,
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
  final AntibioticReport report;
  const _ReportBody({required this.report});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = report.totals;

    return Column(
      children: [
        // ── Summary header
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
                        'Antibiotic & Polypharmacy Analysis',
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
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _pill(scheme, 'Total Meds', '${t.totalMedicines}',
                        scheme.surfaceContainerHighest,
                        scheme.onSurfaceVariant),
                    const SizedBox(height: 4),
                    _pill(
                      scheme,
                      'Antibiotics',
                      '${t.antibioticCount}  (${t.antibioticPercent.toStringAsFixed(1)}%)',
                      scheme.primaryContainer,
                      scheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 4),
                    _pill(
                      scheme,
                      'Polypharmacy',
                      '${t.polypharmacyCount}  (${t.polypharmacyPercent.toStringAsFixed(1)}%)',
                      scheme.errorContainer,
                      scheme.onErrorContainer,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        _TableHeader(scheme: scheme),

        Expanded(
          child: report.rows.isEmpty
              ? const Center(child: Text('No prescriptions in this range'))
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
          _h('#', 40, align: TextAlign.center),
          _h('Date', 110),
          _h('Total Meds', null, flex: 2, align: TextAlign.center),
          _h('Antibiotics', null, flex: 2, align: TextAlign.center),
          _h('Abx %', null, flex: 2, align: TextAlign.center),
          _h('Polypharmacy', null, flex: 2, align: TextAlign.center),
          _h('Poly %', null, flex: 2, align: TextAlign.center),
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
  final int index;
  final AntibioticReportRow row;
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: isOdd
            ? scheme.surfaceContainerLow.withValues(alpha: 0.5)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
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
          SizedBox(
            width: 110,
            child: Text(
              row.date,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${row.totalMedicines}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${row.antibioticCount}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${row.antibioticPercent.toStringAsFixed(1)}%',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${row.polypharmacyCount}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: scheme.error,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${row.polypharmacyPercent.toStringAsFixed(1)}%',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}