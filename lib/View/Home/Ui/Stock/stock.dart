import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/toast.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';
import 'package:zpharmacy/View/Home/Ui/Stock/stock_details.dart';
import 'bloc/stock_bloc.dart';
import 'model/stock_model.dart';
import 'stock_form.dart';


class StockView extends StatefulWidget {
  const StockView({super.key});
  @override
  State<StockView> createState() => _StockViewState();
}

class _StockViewState extends State<StockView> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<StockBloc>().add(StockLoadRequested(
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      movementType: _typeFilter,
    ));
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _reload);
  }

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.medical_information_outlined,
                      size: 28, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Stock',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
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

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search invoice or organization',
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
                        borderRadius: BorderRadius.circular(3),
                        borderSide: BorderSide(
                            color: scheme.outline.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _TypeChip(label: 'All',
                            selected: _typeFilter == null,
                            onTap: () { setState(() => _typeFilter = null); _reload(); }),
                        const SizedBox(width: 8),
                        _TypeChip(label: 'Received',
                            icon: Icons.move_to_inbox_outlined,
                            selected: _typeFilter == 'RECEIVE',
                            onTap: () { setState(() => _typeFilter = 'RECEIVE'); _reload(); }),
                        const SizedBox(width: 8),
                        _TypeChip(label: 'Donated In',
                            icon: Icons.volunteer_activism_outlined,
                            selected: _typeFilter == 'DONATION_IN',
                            onTap: () { setState(() => _typeFilter = 'DONATION_IN'); _reload(); }),
                        const SizedBox(width: 8),
                        _TypeChip(label: 'Donated Out',
                            icon: Icons.outbox_outlined,
                            selected: _typeFilter == 'DONATION_OUT',
                            onTap: () { setState(() => _typeFilter = 'DONATION_OUT'); _reload(); }),
                        const SizedBox(width: 8),
                        _TypeChip(label: 'Damage',
                            icon: Icons.report_gmailerrorred_outlined,
                            selected: _typeFilter == 'DAMAGE',
                            onTap: () { setState(() => _typeFilter = 'DAMAGE'); _reload(); }),
                        const SizedBox(width: 8),
                        _TypeChip(label: 'Expired',
                            icon: Icons.schedule_outlined,
                            selected: _typeFilter == 'EXPIRED',
                            onTap: () { setState(() => _typeFilter = 'EXPIRED'); _reload(); }),
                        const SizedBox(width: 8),
                        _TypeChip(label: 'Adjustment',
                            icon: Icons.tune_outlined,
                            selected: _typeFilter == 'ADJUSTMENT',
                            onTap: () { setState(() => _typeFilter = 'ADJUSTMENT'); _reload(); }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: BlocBuilder<StockBloc, StockState>(
                builder: (context, state) {
                  if (state is StockLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is StockFailure) {
                    return Center(child: Text(state.message));
                  }

                  final items = state is StockWithItems
                      ? state.items
                      : const <StockInvoice>[];

                  if (items.isEmpty) {
                    return const Center(child: Text('No stock invoices yet'));
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

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
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
                Icon(icon,
                    size: 14,
                    color: selected
                        ? scheme.onSecondaryContainer
                        : scheme.onSurfaceVariant),
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
            ],
          ),
        ),
      ),
    );
  }
}

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
      if (invoice.orgName != null && invoice.orgName!.isNotEmpty) invoice.orgName!,
    ].join('  ·  ');

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(style.icon, size: 18, color: style.fg),
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
                            borderRadius: BorderRadius.circular(20),
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