import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Date/z_range_picker.dart';
import 'package:zpharmacy/Features/Widgets/toast.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';
import 'package:zpharmacy/Features/zdropdown.dart';
import 'package:zpharmacy/View/Home/Ui/Stock/stock_details.dart';
import 'package:zpharmacy/l10n/app_localizations.dart';

import '../../../../Features/Widgets/shimmer.dart';
import 'bloc/stock_bloc.dart';
import 'model/stock_model.dart';
import 'stock_form.dart';


class StockView extends StatefulWidget {
  const StockView({super.key});
  @override
  State<StockView> createState() => _StockViewState();
}

class _StockViewState extends State<StockView> {
  // ---------------- Filters (what goes to the API) ----------------
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  String _movementLabel = 'All';
  String? _fromDate;   // null = no date filter
  String? _toDate;
  bool _scopeAll = false;

  // ---------------- Picker display (always valid) ----------------
  late String _pickerStart;   // 'YYYY-MM-DD'
  late String _pickerEnd;

  static const _movementOptions = [
    'All',
    'Received',
    'Donation In',
    'Donation Out',
    'Damage',
    'Expired',
    'Adjustment',
  ];

  // -----------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------
  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  String? get _movementValue {
    switch (_movementLabel) {
      case 'Received':     return 'RECEIVE';
      case 'Donation In':  return 'DONATION_IN';
      case 'Donation Out': return 'DONATION_OUT';
      case 'Damage':       return 'DAMAGE';
      case 'Expired':      return 'EXPIRED';
      case 'Adjustment':   return 'ADJUSTMENT';
      default:             return null;
    }
  }

  bool get _hasCustomDates => _fromDate != null && _toDate != null;

  void _reload() {
    context.read<StockBloc>().add(StockLoadRequested(
      search: _searchCtrl.text.trim().isEmpty
          ? null
          : _searchCtrl.text.trim(),
      movementType: _movementValue,
      from: _scopeAll ? null : _fromDate,
      to:   _scopeAll ? null : _toDate,
    ));
  }

  // -----------------------------------------------------------------
  // Lifecycle
  // -----------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    _pickerStart = _fmt(start);
    _pickerEnd   = _fmt(now);
    _fromDate    = _pickerStart;
    _toDate      = _pickerEnd;
    // Initial load: last 30 days
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

  void _setLast30Days() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    setState(() {
      _pickerStart = _fmt(start);
      _pickerEnd   = _fmt(now);
      _fromDate    = _pickerStart;
      _toDate      = _pickerEnd;
      _scopeAll    = false;
    });
    _reload();
  }

  void _setAllTime() {
    setState(() {
      _scopeAll = true;
      _fromDate = null;
      _toDate   = null;
    });
    _reload();
  }

  void _clearDates() {
    _setLast30Days();
  }

  void _onDateRangeChanged(String start, String end) {
    setState(() {
      _pickerStart = start;
      _pickerEnd   = end;
      _fromDate    = start;
      _toDate      = end;
      _scopeAll    = false;
    });
    _reload();
  }

  // -----------------------------------------------------------------
  // Add / View / Edit / Cancel
  // -----------------------------------------------------------------
  Future<void> _openAdd() async {
    final bloc = context.read<StockBloc>();
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const StockFormDialog(),
      ),
    );
    _reload();
  }

  Future<void> _openEdit(StockInvoice inv) async {
    final bloc = context.read<StockBloc>();
    bloc.add(StockInvoiceSelectRequested(inv.invoiceId));
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: StockFormDialog(existing: inv),
      ),
    );
    _reload();
  }

  Future<void> _openDetail(StockInvoice inv) async {
    final bloc = context.read<StockBloc>();
    bloc.add(StockInvoiceSelectRequested(inv.invoiceId));
    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: StockDetailDialog(invoice: inv),
      ),
    );
  }

  Future<void> _confirmDelete(StockInvoice inv) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          elevation: 0,
          backgroundColor: scheme.surfaceContainer,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text('Delete ${inv.invoiceNo}?'),
          content: const Text(
              'This reverses all movements on this invoice. It fails if any inbound batch has been dispensed from.'),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(children: [
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
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Delete'),
                ),
              ),
            ]),
          ],
        );
      },
    );
    if (ok == true && mounted) {
      context.read<StockBloc>().add(StockDeleteRequested(inv.invoiceId));
    }
  }

  // -----------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocListener<StockBloc, StockState>(
        listener: (context, state) {
          if (state is StockFailure) {
            ToastManager.show(
              context: context,
              title: 'Failed',
              message: state.message,
              type: ToastType.error,
            );
          }
          if (state is StockActionSuccess) {
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
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
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
                      AppLocalizations.of(context)!.stock,
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
                        onPressed: _openAdd,
                        icon: Icons.add,
                        isActive: true,
                        label: const Text('New Invoice'),
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
                  // -------- Row: search + date range + movement --------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Search
                      Expanded(
                        flex: 7,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: _onSearchChanged,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _reload(),
                          decoration: InputDecoration(
                            hintText: 'Search invoice or organization',
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

                      // Date range picker
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

                      // Movement type dropdown
                      Expanded(
                        flex: 2,
                        child: ZDropdown<String>(
                          title: 'Type',
                          items: _movementOptions,
                          itemLabel: (v) => v,
                          selectedItem: _movementLabel,
                          initialValue: 'All',
                          radius: 4,
                          height: 40,
                          onItemSelected: (v) {
                            setState(() => _movementLabel = v);
                            _reload();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // -------- Quick chips --------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _Chip(
                        label: 'Last 30 days',
                        icon: Icons.history,
                        selected: _hasCustomDates &&
                            !_scopeAll &&
                            _pickerStart ==
                                _fmt(DateTime.now()
                                    .subtract(const Duration(days: 30))) &&
                            _pickerEnd == _fmt(DateTime.now()),
                        onTap: _setLast30Days,
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        label: 'All time',
                        icon: Icons.all_inclusive,
                        selected: _scopeAll && !_hasCustomDates,
                        onTap: _setAllTime,
                      ),
                      if (_hasCustomDates && !_scopeAll) ...[
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
              child: BlocBuilder<StockBloc, StockState>(
                builder: (context, state) {
                  if (state is StockLoading) {
                    return UniversalShimmer.dataList(
                      itemCount: 15,
                      numberOfColumns: 5,
                    );
                  }
                  if (state is StockFailure) {
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

                  final items = state is StockWithItems
                      ? state.items
                      : const <StockInvoice>[];

                  if (items.isEmpty) {
                    return _EmptyState(
                      search: _searchCtrl.text.trim(),
                      scopeAll: _scopeAll,
                      hasCustomDates: _hasCustomDates,
                      movementLabel: _movementLabel,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: items.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _InvoiceCard(
                          invoice: items[i],
                          onTap: () => _openDetail(items[i]),
                          onEdit: () => _openEdit(items[i]),
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
  final String movementLabel;

  const _EmptyState({
    required this.search,
    required this.scopeAll,
    required this.hasCustomDates,
    required this.movementLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    String message;
    IconData icon;
    if (search.isNotEmpty) {
      message = 'No invoices match "$search"';
      icon = Icons.search_off;
    } else if (movementLabel != 'All') {
      message = 'No "$movementLabel" invoices in this period';
      icon = Icons.filter_alt_off_outlined;
    } else if (hasCustomDates && !scopeAll) {
      message = 'No invoices in this date range';
      icon = Icons.date_range_outlined;
    } else if (scopeAll) {
      message = 'No invoices yet';
      icon = Icons.receipt_long_outlined;
    } else {
      message = 'No invoices in the last 30 days';
      icon = Icons.history;
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
              'Try a different filter',
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
// Invoice card (unchanged)
// =====================================================================
class _InvoiceCard extends StatelessWidget {
  final StockInvoice invoice;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InvoiceCard({
    required this.invoice,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = _styleFor(invoice.movementType, scheme);

    final meta = <String>[
      invoice.invoiceDate,
      '${invoice.itemCount} line${invoice.itemCount == 1 ? '' : 's'}',
      '${invoice.totalQty} units',
      if (invoice.orgName != null && invoice.orgName!.isNotEmpty)
        invoice.orgName!,
    ].join('  ·  ');

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: style.bg.withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.center,
                child: Icon(style.icon, size: 18, color: style.fg.withValues(alpha: .9)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            invoice.invoiceNo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: style.bg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            style.label,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: style.fg),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
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
              SizedBox(
                width: 32,
                height: 32,
                child: PopupMenuButton<_MenuAction>(
                  tooltip: 'More',
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert,
                      size: 18, color: scheme.onSurfaceVariant),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  onSelected: (a) {
                    switch (a) {
                      case _MenuAction.edit:
                        onEdit();
                        break;
                      case _MenuAction.delete:
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: _MenuAction.edit,
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: _MenuAction.delete,
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: scheme.error),
                        const SizedBox(width: 10),
                        Text('Delete',
                            style: TextStyle(color: scheme.error)),
                      ]),
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

  _TypeStyle _styleFor(String type, ColorScheme scheme) {
    switch (type) {
      case 'RECEIVE':
        return _TypeStyle(
          label: 'Received',
          icon: Icons.move_to_inbox_outlined,
          bg: scheme.primaryContainer,
          fg: scheme.onPrimaryContainer,
        );
      case 'DONATION_IN':
        return _TypeStyle(
          label: 'Donation In',
          icon: Icons.volunteer_activism_outlined,
          bg: scheme.tertiaryContainer,
          fg: scheme.onTertiaryContainer,
        );
      case 'DONATION_OUT':
        return _TypeStyle(
          label: 'Donation Out',
          icon: Icons.outbox_outlined,
          bg: scheme.secondaryContainer,
          fg: scheme.onSecondaryContainer,
        );
      case 'ADJUSTMENT':
        return _TypeStyle(
          label: 'Adjustment',
          icon: Icons.tune_outlined,
          bg: scheme.surfaceContainerHighest,
          fg: scheme.onSurfaceVariant,
        );
      case 'EXPIRED':
        return _TypeStyle(
          label: 'Expired',
          icon: Icons.schedule_outlined,
          bg: scheme.errorContainer,
          fg: scheme.onErrorContainer,
        );
      case 'DAMAGE':
      default:
        return _TypeStyle(
          label: 'Damage',
          icon: Icons.report_gmailerrorred_outlined,
          bg: scheme.errorContainer,
          fg: scheme.onErrorContainer,
        );
    }
  }
}

class _TypeStyle {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  _TypeStyle({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });
}

enum _MenuAction { edit, delete }