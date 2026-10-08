import 'package:flutter/material.dart';
import 'package:zpharmacy/l10n/app_localizations.dart';
import '../../../../Features/Date/zdate_picker.dart';
import '../Medicine/medcine_field.dart';
import 'batch_picker_field.dart';
import 'stock_form.dart';        // for StockItemDraft

class StockItemRow extends StatefulWidget {
  final StockItemDraft draft;
  final int index;
  final bool isInbound;
  final bool isAdjustment;
  final VoidCallback? onRemove;

  const StockItemRow({
    super.key,
    required this.draft,
    required this.index,
    required this.isInbound,
    required this.isAdjustment,
    this.onRemove,
  });

  @override
  State<StockItemRow> createState() => _StockItemRowState();
}

class _StockItemRowState extends State<StockItemRow> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = widget.draft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ------------- Index -------------
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${widget.index}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ------------- Main picker -------------
          Expanded(
            flex: 5,
            child: widget.isInbound
                ? MedicineSearchField(
              initial: d.medicine,
              hintText: AppLocalizations.of(context)!.medicine,
              onSelected: (m) => setState(() => d.medicine = m),
            )
                : BatchPickerField(
              initial: d.batchOption,
              hintText: AppLocalizations.of(context)!.medicine,
              onSelected: (b) => setState(() => d.batchOption = b),
            ),
          ),
          const SizedBox(width: 8),

          // ------------- Inbound extras -------------
          if (widget.isInbound) ...[
            // Expiry — using your GenericDatePicker (single-line variant)
            SizedBox(
              width: 150,
              child: GenericDatePicker(
                label: '',
                height: 44,
                initialGregorianDate: d.expiryDate.isEmpty
                    ? null
                    : d.expiryDate,
                gregorianTextStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                shamsiTextStyle: TextStyle(
                  fontSize: 9.5,
                  color: scheme.primary,
                  fontWeight: FontWeight.w500,
                ),
                onDateChanged: (date) {
                  setState(() => d.expiryDate = date);
                },
              ),
            ),
            const SizedBox(width: 8),
            // Batch no
            SizedBox(
              width: 110,
              child: TextFormField(
                controller: d.batchNoCtrl,
                decoration: _dec(scheme, 'Batch'),
              ),
            ),
            const SizedBox(width: 8),


          ],

          // ------------- Adjustment add/deduct -------------
          if (widget.isAdjustment) ...[
            SizedBox(
              height: 40,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('+'),
                    tooltip: 'Add',
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('−'),
                    tooltip: 'Deduct',
                  ),
                ],
                selected: {d.isNegative},
                onSelectionChanged: (s) =>
                    setState(() => d.isNegative = s.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 10)),
                  textStyle: const WidgetStatePropertyAll(
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // ------------- Quantity -------------
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: d.qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: _dec(scheme, 'Qty'),
            ),
          ),
          const SizedBox(width: 8),

          // ------------- Note -------------
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: d.noteCtrl,
              decoration: _dec(scheme, 'Note'),
            ),
          ),

          // ------------- Remove -------------
          if (widget.onRemove != null) ...[
            const SizedBox(width: 4),
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onRemove,
                icon: Icon(Icons.close, size: 16, color: scheme.error),
                tooltip: 'Remove',
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Shared input decoration — radius 3, no underline
  // -----------------------------------------------------------------
  InputDecoration _dec(ColorScheme scheme, String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: BorderSide(color: scheme.primary, width: 1.2),
      ),
      floatingLabelStyle: TextStyle(
        fontSize: 12,
        color: scheme.primary,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}