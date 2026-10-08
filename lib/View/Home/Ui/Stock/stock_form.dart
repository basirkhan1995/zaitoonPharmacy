import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/z_dialog.dart';
import 'package:zpharmacy/Features/Widgets/ztextfield.dart';
import 'package:zpharmacy/Features/zdropdown.dart';
import 'package:zpharmacy/View/Home/Ui/Stock/stoc_item_row.dart';
import '../../../../Features/Date/zdate_picker.dart';
import '../Medicine/model/medicine_model.dart';
import '../Organization/model/org_model.dart';       // ← Organization type
import '../Organization/org_dropdown.dart';
import 'bloc/stock_bloc.dart';
import 'model/stock_model.dart';


class StockFormDialog extends StatefulWidget {
  final StockInvoice? existing;
  const StockFormDialog({super.key, this.existing});

  @override
  State<StockFormDialog> createState() => _StockFormDialogState();
}

class _StockFormDialogState extends State<StockFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _invoiceNoCtrl = TextEditingController();
  final _noteCtrl      = TextEditingController();

  String _movementType = 'RECEIVE';
  Organization? _selectedOrg;      // ← was int? _orgId
  String _invoiceDate = '';
  bool _itemsPrefilled = false;

  final List<StockItemDraft> _drafts = [];

  bool get _isEdit => widget.existing != null;
  bool get _isInbound =>
      _movementType == 'RECEIVE' || _movementType == 'DONATION_IN';
  bool get _needsOrg => _isInbound || _movementType == 'DONATION_OUT';

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    if (_isEdit) {
      final e = widget.existing!;
      _invoiceNoCtrl.text = e.invoiceNo;
      _invoiceDate        = e.invoiceDate;
      _noteCtrl.text      = e.note ?? '';
      _movementType       = e.movementType;

      // Prefill selected org from the invoice (id + name only)
      if (e.orgId != null) {
        _selectedOrg = Organization(
          orgId:   e.orgId!,
          orgName: e.orgName ?? '',
        );
      }

      _prefillItems(e);
    } else {
      _invoiceDate = fmt(today);
      _addItemRow();
    }
  }

  void _prefillItems(StockInvoice inv) {
    if (_itemsPrefilled) return;
    if (inv.items.isEmpty) return;

    for (final d in _drafts) {
      d.dispose();
    }
    _drafts.clear();

    for (final it in inv.items) {
      final d = StockItemDraft();
      d.qtyCtrl.text  = '${it.quantity.abs()}';
      d.noteCtrl.text = it.note ?? '';

      if (_isInbound) {
        d.medicine = Medicine(
          medId:   it.medId ?? 0,
          medName: it.medName ?? '',
          unit:    it.unit ?? '',
          dosage:  it.dosage,
          catId:   0,
          catName: '',
        );
        d.batchNoCtrl.text = it.batchNo ?? '';
        d.expiryDate = it.expiryDate ?? '';
      } else {
        d.batchOption = StockBatchOption(
          batchId: it.batchId ?? 0,
          medId:   it.medId ?? 0,
          medName: it.medName ?? '',
          unit:    it.unit,
          dosage:  it.dosage,
          batchNo: it.batchNo ?? '',
          expiryDate: it.expiryDate ?? '',
          quantityRemaining: it.quantityRemaining ?? 0,
        );
        d.isNegative = it.quantity < 0;
      }
      _drafts.add(d);
    }

    if (_drafts.isEmpty) _addItemRow();
    _itemsPrefilled = true;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _invoiceNoCtrl.dispose();
    _noteCtrl.dispose();
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  void _addItemRow() => setState(() => _drafts.add(StockItemDraft()));

  void _removeItemRow(int i) {
    setState(() {
      _drafts[i].dispose();
      _drafts.removeAt(i);
    });
  }


  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_invoiceDate.isEmpty) {
      _toast('Pick an invoice date');
      return;
    }
    if (_needsOrg && _selectedOrg == null) {
      _toast('Pick an organization');
      return;
    }

    final items = <StockInvoiceItemRequest>[];

    for (int i = 0; i < _drafts.length; i++) {
      final d = _drafts[i];
      final qty = int.tryParse(d.qtyCtrl.text.trim());
      if (qty == null || qty == 0) {
        _toast('Row ${i + 1}: enter a valid quantity');
        return;
      }

      if (_isInbound) {
        if (d.medicine == null) {
          _toast('Row ${i + 1}: pick a medicine');
          return;
        }
        if (d.batchNoCtrl.text.trim().isEmpty) {
          _toast('Row ${i + 1}: enter batch number');
          return;
        }
        if (d.expiryDate.isEmpty) {
          _toast('Row ${i + 1}: pick expiry date');
          return;
        }
        if (qty <= 0) {
          _toast('Row ${i + 1}: quantity must be positive');
          return;
        }
        items.add(StockInvoiceItemRequest(
          medId:      d.medicine!.medId,
          batchNo:    d.batchNoCtrl.text.trim(),
          expiryDate: d.expiryDate,
          quantity:   qty,
          note: d.noteCtrl.text.trim().isEmpty ? null : d.noteCtrl.text.trim(),
        ));
      } else {
        if (d.batchOption == null) {
          _toast('Row ${i + 1}: pick a batch');
          return;
        }
        final signed = _movementType == 'ADJUSTMENT'
            ? (d.isNegative ? -qty.abs() : qty.abs())
            : qty.abs();
        items.add(StockInvoiceItemRequest(
          batchId:  d.batchOption!.batchId,
          quantity: signed,
          note: d.noteCtrl.text.trim().isEmpty ? null : d.noteCtrl.text.trim(),
        ));
      }
    }

    if (items.isEmpty) {
      _toast('Add at least one item');
      return;
    }

    final req = StockInvoiceRequest(
      invoiceNo:    _invoiceNoCtrl.text.trim(),
      invoiceDate:  _invoiceDate,
      movementType: _movementType,
      orgId:        _needsOrg ? _selectedOrg!.orgId : null,
      note:         _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      items:        items,
    );

    final bloc = context.read<StockBloc>();
    if (_isEdit) {
      bloc.add(StockUpdateRequested(widget.existing!.invoiceId, req));
    } else {
      bloc.add(StockCreateRequested(req));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StockBloc, StockState>(
      listenWhen: (p, c) =>
      c is StockActionSuccess ||
          (c is StockLoaded && c.selected != null && !_itemsPrefilled),
      listener: (context, state) {
        if (state is StockActionSuccess) {
          Navigator.of(context).pop(true);
        }
        if (state is StockLoaded &&
            state.selected != null &&
            !_itemsPrefilled) {
          _prefillItems(state.selected!);
        }
      },
      child: BlocBuilder<StockBloc, StockState>(
        buildWhen: (p, c) => (p is StockSaving) != (c is StockSaving),
        builder: (context, state) {
          final saving = state is StockSaving;

          return ZFormDialog(
            title: _isEdit ? 'Edit Invoice' : 'New Stock Invoice',
            icon: Icons.medical_information_outlined,
            width: MediaQuery.of(context).size.width * 0.65,
            padding: const EdgeInsets.all(16),
            isButtonEnabled: !saving,
            onAction: saving ? null : _submit,
            actionLabel: saving
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(_isEdit ? 'Save' : 'Record'),
            child: AbsorbPointer(
              absorbing: saving,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ---------------- Header ----------------
                      Row(children: [
                        Expanded(
                          child: ZTextFieldEntitled(
                            title: 'Invoice number *',
                            controller: _invoiceNoCtrl,
                            validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ZDropdown<String>(
                            title: 'Movement type *',
                            items: const [
                              'Received',
                              'Donation In',
                              'Donation Out',
                              'Damage',
                              'Expired',
                              'Adjustment',
                            ],
                            itemLabel: (v) => v,
                            selectedItem: _movementLabel(_movementType),
                            initialValue: 'Received',
                            radius: 4,
                            height: 40,
                            onItemSelected: _isEdit
                                ? (_) {}
                                : (v) {
                              setState(() {
                                _movementType = _movementFromLabel(v);
                                for (final d in _drafts) {
                                  d.dispose();
                                }
                                _drafts.clear();
                                _addItemRow();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _needsOrg
                              ? OrganizationPickerField(
                            title: 'Organization *',
                            selected: _selectedOrg,
                            onSelected: (org) =>
                                setState(() => _selectedOrg = org),
                          )
                              : const SizedBox.shrink(),
                        ),

                      ]),
                      const SizedBox(height: 12),

                      // ------------- Movement + Org -------------
                      Row(
                          children: [
                        Expanded(
                          child: GenericDatePicker(
                            label: 'Invoice date *',
                            initialGregorianDate: _invoiceDate,
                            onDateChanged: (date) {
                              setState(() {
                                _invoiceDate = date;
                              });
                            },
                          ),
                        ),
                            const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: ZTextFieldEntitled(
                              title: 'Note', controller: _noteCtrl),
                        ),
                      ]),

                      const SizedBox(height: 10),

                      // ---------------- Items ----------------
                      Row(children: [
                        Text(
                          'ITEMS',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addItemRow,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add item'),
                        ),
                      ]),
                      const SizedBox(height: 4),

                      ...List.generate(_drafts.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: StockItemRow(
                            key: ValueKey(_drafts[i]),
                            draft: _drafts[i],
                            index: i + 1,
                            isInbound: _isInbound,
                            isAdjustment: _movementType == 'ADJUSTMENT',
                            onRemove: _drafts.length > 1
                                ? () => _removeItemRow(i)
                                : null,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
    return 'Received';
  }

  String _movementFromLabel(String l) {
    switch (l) {
      case 'Received':     return 'RECEIVE';
      case 'Donation In':  return 'DONATION_IN';
      case 'Donation Out': return 'DONATION_OUT';
      case 'Damage':       return 'DAMAGE';
      case 'Expired':      return 'EXPIRED';
      case 'Adjustment':   return 'ADJUSTMENT';
    }
    return 'RECEIVE';
  }
}

// =====================================================================
// Draft
// =====================================================================
class StockItemDraft {
  final qtyCtrl     = TextEditingController();
  final noteCtrl    = TextEditingController();
  final batchNoCtrl = TextEditingController();

  Medicine? medicine;
  StockBatchOption? batchOption;
  String expiryDate = '';
  bool isNegative = false;

  void dispose() {
    qtyCtrl.dispose();
    noteCtrl.dispose();
    batchNoCtrl.dispose();
  }
}
