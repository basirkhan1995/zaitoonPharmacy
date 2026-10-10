
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Date/shamsi_converter.dart';
import 'package:zpharmacy/Features/Date/z_range_picker.dart';
import 'package:zpharmacy/Features/Widgets/toast.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';
import 'package:zpharmacy/l10n/app_localizations.dart';
import '../../../../../Features/Widgets/shimmer.dart';
import '../../Settings/Ui/Category/category_drop.dart';
import '../../Settings/Ui/Category/model/med_category_model.dart';
import 'bloc/tally_sheet_bloc.dart';
import 'model/tally_sheet_model.dart';

class TallySheetView extends StatefulWidget {
  const TallySheetView({super.key});

  @override
  State<TallySheetView> createState() => _TallySheetViewState();
}

class _TallySheetViewState extends State<TallySheetView> {
  Category? _category;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reload();
    });
  }

  void _reload() {
    if (_from.isEmpty || _to.isEmpty) return;
    context.read<TallySheetBloc>().add(TallySheetLoadRequested(
      from:  _from,
      to:    _to,
      catId: _category?.catId,
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

  void _onCategoryChanged(Category? cat) {
    setState(() => _category = cat);
    _reload();
  }

  void _clearCategory() {
    setState(() => _category = null);
    _reload();
  }

  void _setQuickRange(String key) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (key) {
      case 'all':
        start = DateTime(2020, 1, 1);
        end   = now;
        break;
      case 'last30':
        start = now.subtract(const Duration(days: 30));
        end   = now;
        break;
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        end   = now;
        break;
      default:
        return;
    }

    setState(() {
      _pickerStart = _fmt(start);
      _pickerEnd   = _fmt(end);
      _from        = _pickerStart;
      _to          = _pickerEnd;
    });
    _reload();
  }

  String? _activeQuickRange() {
    final now    = DateTime.now();
    final today  = _fmt(DateTime(now.year, now.month, now.day));
    final last30 = _fmt(now.subtract(const Duration(days: 30)));
    final nowStr = _fmt(now);

    if (_from == last30 && _to == nowStr) return 'last30';
    if (_from == today && _to == nowStr)   return 'today';
    if (_from == '2020-01-01' && _to == nowStr) return 'all';
    return null;
  }

  // ── Export: dispatch the event; the bloc handles the rest
  void _onExport() {
    if (_from.isEmpty || _to.isEmpty) return;
    context.read<TallySheetBloc>().add(TallySheetExportRequested(
      from:  _from,
      to:    _to,
      catId: _category?.catId,
    ));
  }

  Future<void> _saveExportedFile(TallySheetExported s) async {
    final result = await FilePicker.saveFile(
      dialogTitle: 'Save tally sheet',
      fileName: s.fileName,
      bytes: Uint8List.fromList(s.bytes),   // ← pass bytes here
    );

    if (result == null || !mounted) return;

    // Some versions return String, some return Uri — handle both
    final savedPath = result.toFilePath();

    ToastManager.show(context: context,title: "Export Success", message: 'Saved to $savedPath', type: ToastType.info);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    final activeQuick = _activeQuickRange();

    return BlocListener<TallySheetBloc, TallySheetState>(
      listener: (context, state) {
        // Reset the button flag whenever we leave "exporting"
        if (state is! TallySheetExporting && _isExporting) {
          setState(() => _isExporting = false);
        }

        if (state is TallySheetExporting) {
          setState(() => _isExporting = true);
        }

        if (state is TallySheetExported) {
          _saveExportedFile(state);
        }

        if (state is TallySheetExportFailed) {
          ToastManager.show(context: context,title: "Export Failed", message: 'Failed to export Excel', type: ToastType.error);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tally Sheet'),
          titleSpacing: 0,
          actionsPadding: EdgeInsets.all(10),
          actions: [
            ZOutlineButton(
              icon: Icons.refresh,
              label: Text("Refresh"),
              toolTip: 'Refresh',
              onPressed: _reload,
            ),
            const SizedBox(width: 8),
            ZOutlineButton(
              isActive: true,
              onPressed: _isExporting ? null : _onExport,
              icon: Icons.file_download_outlined,
              label: Text(_isExporting ? 'Exporting…' : 'Export Excel'),
            ),
          ],
        ),
        body: Column(
          children: [
            // ── FILTER BAR (same as before)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 8,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _QuickChip(
                          label: 'All time',
                          icon: Icons.all_inclusive,
                          selected: activeQuick == 'all',
                          onTap: () => _setQuickRange('all'),
                          scheme: scheme,
                        ),
                        _QuickChip(
                          label: 'Last 30 days',
                          icon: Icons.calendar_view_month_outlined,
                          selected: activeQuick == 'last30',
                          onTap: () => _setQuickRange('last30'),
                          scheme: scheme,
                        ),
                        _QuickChip(
                          label: 'Today',
                          icon: Icons.today_outlined,
                          selected: activeQuick == 'today',
                          onTap: () => _setQuickRange('today'),
                          scheme: scheme,
                        ),
                        if (_category != null)
                          InputChip(
                            avatar: Icon(Icons.category_outlined,
                                size: 16,
                                color: scheme.onPrimaryContainer),
                            label: Text(
                              _category!.catName,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                            backgroundColor: scheme.primaryContainer,
                            deleteIcon: Icon(Icons.close,
                                size: 16,
                                color: scheme.onPrimaryContainer),
                            deleteIconColor: scheme.onPrimaryContainer,
                            onDeleted: _clearCategory,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: scheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            side: BorderSide(
                              color: scheme.primary.withValues(alpha: 0.3),
                            ),
                            materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: MedicineCategoryDropView(
                      title: tr.category,
                      hint: 'All categories',
                      selected: _category,
                      enabled: !_isExporting,
                      onSelected: _onCategoryChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        if (_pickerStart.isNotEmpty &&
                            _pickerEnd.isNotEmpty) {
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
              child: BlocBuilder<TallySheetBloc, TallySheetState>(
                builder: (context, state) {
                  if (state is TallySheetInitial) {
                    return const _EmptyPrompt();
                  }
                  if (state is TallySheetLoading) {
                    return UniversalShimmer.dataList(
                      itemCount: 15,
                      numberOfColumns: 5,
                    );
                  }
                  if (state is TallySheetFailure) {
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

                  // All three carry the rows
                  final rows = switch (state) {
                    TallySheetLoaded s        => s.rows,
                    TallySheetExporting s     => s.rows,
                    TallySheetExported s      => s.rows,
                    TallySheetExportFailed s  => s.rows,
                    _                         => const <TallySheetRow>[],
                  };

                  if (rows.isEmpty) {
                    return const _EmptyPrompt(
                      message: 'No out movements in this range',
                    );
                  }
                  return _ReportBody(rows: rows);
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
// Quick date-range chip
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
    final bg = selected
        ? scheme.secondaryContainer
        : scheme.surfaceContainerLow;
    final fg = selected
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;
    final border = selected
        ? scheme.secondary.withValues(alpha: 0.4)
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
// Report body
// =====================================================================
class _ReportBody extends StatelessWidget {
  final List<TallySheetRow> rows;
  const _ReportBody({required this.rows});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final totalMeds  = rows.length;
    final totalUnits = rows.fold<int>(0, (s, r) => s + r.total.abs());
    final totalMoves = rows.fold<int>(0, (s, r) => s + r.outs.length);

    return Column(
      children: [
        // -------- Summary strip --------
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
                Icon(Icons.receipt_long_outlined,
                    size: 18, color: scheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tally Summary',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                _pill(scheme, 'Medicines', '$totalMeds',
                    scheme.surfaceContainerHighest,
                    scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                _pill(scheme, 'Movements', '$totalMoves',
                    scheme.secondaryContainer,
                    scheme.onSecondaryContainer),
                const SizedBox(width: 6),
                _pill(scheme, 'Units Out', '-$totalUnits',
                    scheme.errorContainer, scheme.onErrorContainer),
              ],
            ),
          ),
        ),

        // -------- Table header --------
        _TableHeader(scheme: scheme),

        // -------- Rows --------
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: rows.length,
            itemBuilder: (_, i) => _RowTile(
              index: i + 1,
              row: rows[i],
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
          _h('Medicine', null, flex: 2),
          _h('Outs', null, flex: 4),
          _h('Total', 80, align: TextAlign.right),
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
  final TallySheetRow row;
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
    final hasDosage = (row.dosage ?? '').trim().isNotEmpty;
    final hasCategory = row.catName.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: isOdd
            ? scheme.surfaceContainerLow.withValues(alpha: 0.6)
            : Colors.transparent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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

          Expanded(
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    row.medName.isNotEmpty
                        ? row.medName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        row.medName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasDosage || hasCategory) ...[
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (hasDosage) row.dosage!,
                            if (hasCategory) row.catName,
                          ].join('  •  '),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 4,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final o in row.outs) _OutChip(out: o, scheme: scheme),
              ],
            ),
          ),

          SizedBox(
            width: 80,
            child: Text(
              '${row.total}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: scheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Out chip
// =====================================================================
class _OutChip extends StatelessWidget {
  final TallyOut out;
  final ColorScheme scheme;

  const _OutChip({required this.out, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(out.type, scheme);

    return Tooltip(
      message: '${style.label}\n${out.date.toFormattedDate()}',
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: style.bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: style.fg.withValues(alpha: 0.25)),
        ),
        child: Text(
          '${out.quantity}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            color: style.fg,
          ),
        ),
      ),
    );
  }

  _ChipStyle _styleFor(String type, ColorScheme scheme) {
    switch (type) {
      case 'DISPENSE':
        return _ChipStyle(
            'Prescribed', scheme.primaryContainer, scheme.onPrimaryContainer);
      case 'DONATION_OUT':
        return _ChipStyle('Donation Out', scheme.secondaryContainer,
            scheme.onSecondaryContainer);
      case 'EXPIRED':
        return _ChipStyle(
            'Expired', scheme.errorContainer, scheme.onErrorContainer);
      case 'DAMAGE':
        return _ChipStyle(
            'Damage', scheme.errorContainer, scheme.onErrorContainer);
      case 'ADJUSTMENT':
        return _ChipStyle('Adjustment', scheme.surfaceContainerHighest,
            scheme.onSurfaceVariant);
      default:
        return _ChipStyle(type, scheme.surfaceContainerHighest,
            scheme.onSurfaceVariant);
    }
  }
}

class _ChipStyle {
  final String label;
  final Color bg;
  final Color fg;
  _ChipStyle(this.label, this.bg, this.fg);
}

// =====================================================================
// Empty prompt
// =====================================================================
class _EmptyPrompt extends StatelessWidget {
  final String message;
  const _EmptyPrompt({
    this.message = 'Pick a date range to see the tally sheet',
  });

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
              Icons.receipt_long_outlined,
              size: 56,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
            Text(
              message,
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