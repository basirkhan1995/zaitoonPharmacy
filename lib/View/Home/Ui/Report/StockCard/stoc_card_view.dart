import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Date/z_range_picker.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';
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

    _medicine = widget.initialMedicine;

    // Load medicines for the picker
    context.read<MedicineBloc>().add(const MedicineLoadRequested());

    // Auto-load if a medicine was already selected
    if (_medicine != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _reload();
      });
    }
  }

  void _reload() {
    if (_medicine == null) return;
    if (_from.isEmpty || _to.isEmpty) return;

    context.read<StockCardBloc>().add(StockCardLoadRequested(
      medId: _medicine!.medId,
      from:  _from,
      to:    _to,
    ));
  }

  void _onMedicineChanged(Medicine? m) {
    setState(() => _medicine = m);
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Stock Card"),
      ),
      body: Column(
        children: [
          // =====================================================
          // HEADER
          // =====================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(
                  Icons.medical_information_outlined,
                  size: 30,
                  color: scheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Stock Card',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                ZOutlineButton(
                  onPressed: _reload,
                  icon: Icons.refresh,
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),

          // =====================================================
          // FILTER BAR
          // =====================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                Expanded(
                  flex: 2,
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
            child: BlocBuilder<StockCardBloc, StockCardState>(
              builder: (context, state) {
                if (state is StockCardInitial) {
                  return const _EmptyPrompt();
                }
                if (state is StockCardLoading) {
                  return const Center(child: CircularProgressIndicator());
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
                if (state is StockCardLoaded) {
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
  final StockCardReport report;
  const _ReportBody({required this.report});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final med = report.medicine;

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
                          if ((med['company_brand'] ?? '').toString().isNotEmpty)
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
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _pill(scheme, 'Opening', '${report.openingBalance}',
                        scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
                    const SizedBox(height: 4),
                    _pill(scheme, 'In ${report.totalIn}', 'Out ${report.totalOut}',
                        scheme.secondaryContainer, scheme.onSecondaryContainer),
                    const SizedBox(height: 4),
                    _pill(scheme, 'Closing', '${report.closingBalance}',
                        scheme.primaryContainer, scheme.onPrimaryContainer),
                  ],
                ),
              ],
            ),
          ),
        ),
        _TableHeader(scheme: scheme),
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
          _h('Batch', 130),
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
            ? scheme.surfaceContainerLow.withValues(alpha: 2)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(row.date, style: const TextStyle(fontSize: 11.5)),
          ),
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
          SizedBox(
            width: 130,
            child: Text(
              row.batchNo ?? '—',
              style: const TextStyle(fontSize: 11.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
          SizedBox(
            width: 65,
            child: Text(
              '${row.balance}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  _TypeStyle _typeStyle(String type, ColorScheme scheme) {
    switch (type) {
      case 'RECEIVE':
        return _TypeStyle('Received', Icons.move_to_inbox_outlined,
            scheme.primary);
      case 'DONATION_IN':
        return _TypeStyle('Donation In', Icons.volunteer_activism_outlined,
            scheme.tertiary);
      case 'DONATION_OUT':
        return _TypeStyle('Donation Out', Icons.outbox_outlined,
            scheme.secondary);
      case 'DISPENSE':
        return _TypeStyle('Prescribed', Icons.receipt_long_outlined,
            scheme.primary);
      case 'ADJUSTMENT':
        return _TypeStyle('Adjustment', Icons.tune_outlined,
            scheme.onSurfaceVariant);
      case 'EXPIRED':
        return _TypeStyle('Expired', Icons.schedule_outlined,
            scheme.error);
      case 'DAMAGE':
        return _TypeStyle('Damage', Icons.report_gmailerrorred_outlined,
            scheme.error);
      case 'RETURN':
        return _TypeStyle('Return', Icons.undo_outlined, scheme.tertiary);
      default:
        return _TypeStyle(type, Icons.circle_outlined,
            scheme.onSurfaceVariant);
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