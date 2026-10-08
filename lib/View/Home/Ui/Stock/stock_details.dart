import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/z_dialog.dart';

import 'bloc/stock_bloc.dart';
import 'model/stock_model.dart';

class StockDetailDialog extends StatelessWidget {
  final StockInvoice invoice;
  const StockDetailDialog({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<StockBloc, StockState>(
      builder: (context, state) {
        final full = (state is StockLoaded && state.selected != null)
            ? state.selected!
            : invoice;

        return ZFormDialog(
          title: full.invoiceNo,
          icon: Icons.receipt_long_outlined,
          width: 720,
          padding: const EdgeInsets.all(16),
          isActionTrue: false,
          onAction: null,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _kv(scheme, 'Date', full.invoiceDate),
                _kv(scheme, 'Type', _movementLabel(full.movementType)),
                if (full.orgName != null && full.orgName!.isNotEmpty)
                  _kv(scheme, 'Organization', full.orgName!),
                if (full.note != null && full.note!.isNotEmpty)
                  _kv(scheme, 'Note', full.note!),

                const SizedBox(height: 16),
                Row(children: [
                  Text(
                    'ITEMS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${full.items.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),

                if (full.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Loading items…')),
                  )
                else
                  ...full.items.map((it) => _itemCard(context, scheme, it)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _itemCard(BuildContext context, ColorScheme scheme, StockInvoiceItem it) {
    final negative = it.quantity < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  it.medName ?? '—',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Batch ${it.batchNo ?? "—"}  ·  exp ${it.expiryDate ?? "—"}'
                      '${it.quantityRemaining != null ? "  ·  ${it.quantityRemaining} left" : ""}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (it.note != null && it.note!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    it.note!,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: negative
                  ? scheme.errorContainer
                  : scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${negative ? "" : "+"}${it.quantity}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: negative
                    ? scheme.onErrorContainer
                    : scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(ColorScheme scheme, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _movementLabel(String t) {
    switch (t) {
      case 'RECEIVE':      return 'Received';
      case 'DONATION_IN':  return 'Donation In';
      case 'DONATION_OUT': return 'Donation Out';
      case 'DAMAGE':       return 'Damage';
      case 'EXPIRED':      return 'Expired';
      case 'ADJUSTMENT':   return 'Adjustment';
    }
    return t;
  }
}