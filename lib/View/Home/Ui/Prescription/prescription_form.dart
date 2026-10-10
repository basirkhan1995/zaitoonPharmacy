import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/ztextfield.dart';
import 'package:zpharmacy/l10n/app_localizations.dart';

import '../../../../Features/Widgets/z_dialog.dart';
import '../../../../Features/zdropdown.dart';
import '../Medicine/bloc/medicine_bloc.dart';
import '../Medicine/medcine_field.dart';
import '../Medicine/model/medicine_model.dart';
import 'bloc/prescription_bloc.dart';
import 'model/prescription_model.dart';


class AddEditPrescriptionForm extends StatefulWidget {
  final Prescription? existing;

  const AddEditPrescriptionForm({super.key, this.existing});

  @override
  State<AddEditPrescriptionForm> createState() =>
      _AddEditPrescriptionFormState();
}

class _AddEditPrescriptionFormState extends State<AddEditPrescriptionForm> {
  final _formKey = GlobalKey<FormState>();
  bool _itemsPrefilled = false;

  // ---------------- Header controllers ----------------
  final _registerNo  = TextEditingController();
  final _patientName = TextEditingController();
  final _age         = TextEditingController();
  final _address     = TextEditingController();
  final _doctorName  = TextEditingController();
  final _diagnosis   = TextEditingController();
  final _note        = TextEditingController();
  String _gender = 'Male';

  // Focus nodes that participate in the auto-chain.
  final _regFocus  = FocusNode(debugLabel: 'regNo');
  final _nameFocus = FocusNode(debugLabel: 'patientName');

  // Items
  final List<PrescriptionItemDraft> _drafts = [];

  // -----------------------------------------------------------------
  // Item prefill (edit mode)
  // -----------------------------------------------------------------
  void _prefillItems(Prescription p) {
    if (_itemsPrefilled) return;
    if (p.items.isEmpty) return;

    for (final d in _drafts) {
      d.dispose();
    }
    _drafts.clear();

    for (final it in p.items) {
      final draft = PrescriptionItemDraft();
      draft.medicine = Medicine(
        medId:   it.medId,
        medName: it.medName,
        unit:    it.unit ?? '',
        dosage:  it.dosage,
        catId:   0,
        catName: '',
      );
      draft.qty.text         = '${it.quantity}';
      draft.instruction.text = it.dosageInstruction ?? '';
      _drafts.add(draft);
    }

    if (_drafts.isEmpty) {
      _addItemRow(focusAfterBuild: false);
    }

    _itemsPrefilled = true;
    if (mounted) setState(() {});
  }

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final e = widget.existing;
    if (e != null) {
      _registerNo.text  = e.registerNo;
      _patientName.text = e.patientName;
      _age.text         = '${e.age}';
      _address.text     = e.address ?? '';
      _doctorName.text  = e.doctorName ?? '';
      _diagnosis.text   = e.diagnosis ?? '';
      _note.text        = e.note ?? '';
      _gender           = e.gender;

      _prefillItems(e);
    } else {
      _addItemRow(focusAfterBuild: false);
    }

    context.read<MedicineBloc>().add(const MedicineLoadRequested());

    // Autofocus the register field.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _regFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _registerNo.dispose();
    _patientName.dispose();
    _age.dispose();
    _address.dispose();
    _doctorName.dispose();
    _diagnosis.dispose();
    _note.dispose();
    _regFocus.dispose();
    _nameFocus.dispose();
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  // -----------------------------------------------------------------
  // Item rows
  // -----------------------------------------------------------------
  void _addItemRow({bool focusAfterBuild = true}) {
    final draft = PrescriptionItemDraft();
    _drafts.add(draft);

    if (focusAfterBuild) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && draft.medicineFocus.canRequestFocus) {
          draft.medicineFocus.requestFocus();
        }
      });
    } else {
      setState(() {});
    }
  }

  void _removeItemRow(int index) {
    setState(() {
      _drafts[index].dispose();
      _drafts.removeAt(index);
    });
  }

  void _focusFirstMedicine() {
    if (_drafts.isNotEmpty) {
      _drafts.first.medicineFocus.requestFocus();
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // -----------------------------------------------------------------
  // Submit
  // -----------------------------------------------------------------
  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final items = <PrescriptionItemRequest>[];
    for (int i = 0; i < _drafts.length; i++) {
      final d = _drafts[i];
      if (d.medicine == null) {
        _toast('Row ${i + 1}: pick a medicine');
        return;
      }
      final qty = int.tryParse(d.qty.text.trim());
      if (qty == null || qty <= 0) {
        _toast('Row ${i + 1}: enter a valid quantity');
        return;
      }

      items.add(PrescriptionItemRequest(
        medId:             d.medicine!.medId,
        quantity:          qty,
        dosageInstruction: d.instruction.text.trim().isEmpty
            ? null
            : d.instruction.text.trim(),
        durationDays:      null,
      ));
    }

    if (items.isEmpty) {
      _toast('Add at least one medicine');
      return;
    }

    final req = PrescriptionRequest(
      registerNo:  _registerNo.text.trim(),
      patientName: _patientName.text.trim(),
      gender:      _gender,
      age:         int.tryParse(_age.text.trim()) ?? 0,
      address:     _address.text.trim().isEmpty ? null : _address.text.trim(),
      doctorName:  _doctorName.text.trim().isEmpty ? null : _doctorName.text.trim(),
      diagnosis:   _diagnosis.text.trim().isEmpty ? null : _diagnosis.text.trim(),
      note:        _note.text.trim().isEmpty ? null : _note.text.trim(),
      items:       items,
    );

    final bloc = context.read<PrescriptionBloc>();
    if (_isEdit) {
      bloc.add(PrescriptionUpdateRequested(widget.existing!.prescriptionId, req));
    } else {
      bloc.add(PrescriptionCreateRequested(req));
    }
  }

  // -----------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return BlocListener<PrescriptionBloc, PrescriptionState>(
      listenWhen: (prev, curr) => curr is PrescriptionActionSuccess,
      listener: (context, state) {
        Navigator.of(context).pop(true);
      },
      child: BlocListener<PrescriptionBloc, PrescriptionState>(
        listenWhen: (prev, curr) =>
        _isEdit &&
            !_itemsPrefilled &&
            curr is PrescriptionLoaded &&
            curr.selected != null &&
            curr.selected!.items.isNotEmpty,
        listener: (context, state) {
          if (state is PrescriptionLoaded && state.selected != null) {
            _prefillItems(state.selected!);
          }
        },
        child: BlocBuilder<PrescriptionBloc, PrescriptionState>(
          buildWhen: (p, c) =>
          (p is PrescriptionSaving) != (c is PrescriptionSaving),
          builder: (context, state) {
            final saving = state is PrescriptionSaving;

            return ZFormDialog(
              title: _isEdit ? 'Edit Prescription' : 'New Prescription',
              icon: Icons.receipt_long_outlined,
              width: MediaQuery.of(context).size.width * .6,
              isButtonEnabled: !saving,
              onAction: saving ? null : _submit,
              actionLabel: saving
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(_isEdit ? 'Save' : 'Dispense'),
              child: AbsorbPointer(
                absorbing: saving,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // -------- Patient section --------
                          _sectionTitle(
                              context, AppLocalizations.of(context)!.patient),
                          const SizedBox(height: 8),

                          Row(children: [
                            // ----- Register No (required + autofocus) -----
                            Expanded(
                              child: ZTextFieldEntitled(
                                title: AppLocalizations.of(context)!.regNo,
                                isRequired: true,
                                controller: _registerNo,
                                focusNode: _regFocus,
                                inputAction: TextInputAction.next,
                                // Enter → jump to Patient Name
                                onSubmit: (_) => _nameFocus.requestFocus(),
                                validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // ----- Patient Name (required) -----
                            Expanded(
                              child: ZTextFieldEntitled(
                                title: AppLocalizations.of(context)!.patientName,
                                isRequired: true,
                                controller: _patientName,
                                focusNode: _nameFocus,
                                inputAction: TextInputAction.next,
                                // Enter → jump to first medicine
                                onSubmit: (_) => _focusFirstMedicine(),
                                validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // ----- Age (optional) -----
                            Expanded(
                              child: ZTextFieldEntitled(
                                title: AppLocalizations.of(context)!.age,
                                controller: _age,
                                inputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  final n = int.tryParse(v.trim());
                                  if (n == null || n < 0 || n > 150) {
                                    return '0–150';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),

                            // ----- Gender -----
                            Expanded(
                              child: ZDropdown<String>(
                                title: 'Gender',
                                items: const ['Male', 'Female'],
                                itemLabel: (v) => v,
                                selectedItem: _gender,
                                initialValue: 'Select gender',
                                radius: 4,
                                height: 40,
                                onItemSelected: (v) =>
                                    setState(() => _gender = v),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 10),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                flex: 2,
                                child: ZTextFieldEntitled(
                                  title: 'Address',
                                  controller: _address,
                                  inputAction: TextInputAction.next,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ZTextFieldEntitled(
                                  title: 'Doctor',
                                  controller: _doctorName,
                                  inputAction: TextInputAction.next,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: ZTextFieldEntitled(
                                  title: 'Diagnosis',
                                  controller: _diagnosis,
                                  inputAction: TextInputAction.done,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // -------- Medicines section --------
                          Row(
                              children: [
                            Expanded(child: _sectionTitle(context, 'Medicines')),
                            TextButton.icon(
                              onPressed: () => _addItemRow(),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Medicine'),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          ...List.generate(_drafts.length, (i) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: PrescriptionItemRow(
                                key: ValueKey(_drafts[i]),
                                draft: _drafts[i],
                                index: i + 1,
                                onRemove: _drafts.length > 1
                                    ? () => _removeItemRow(i)
                                    : null,
                                onSubmitLastField: () => _addItemRow(),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w700,
        color: scheme.primary,
      ),
    );
  }
}

// =====================================================================
// Draft
// =====================================================================
class PrescriptionItemDraft {
  final qty         = TextEditingController();
  final instruction = TextEditingController();
  Medicine? medicine;

  final medicineFocus    = FocusNode(debugLabel: 'row-medicine');
  final qtyFocus         = FocusNode(debugLabel: 'row-qty');
  final instructionFocus = FocusNode(debugLabel: 'row-instruction');

  void dispose() {
    qty.dispose();
    instruction.dispose();
    medicineFocus.dispose();
    qtyFocus.dispose();
    instructionFocus.dispose();
  }
}

// =====================================================================
// Row
// =====================================================================
class PrescriptionItemRow extends StatefulWidget {
  final PrescriptionItemDraft draft;
  final int index;
  final VoidCallback? onRemove;

  final VoidCallback? onSubmitLastField;

  const PrescriptionItemRow({
    super.key,
    required this.draft,
    required this.index,
    this.onRemove,
    this.onSubmitLastField,
  });

  @override
  State<PrescriptionItemRow> createState() => _PrescriptionItemRowState();
}

class _PrescriptionItemRowState extends State<PrescriptionItemRow> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final draft = widget.draft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: scheme.primaryContainer.withValues(alpha: .5),
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

          Expanded(
            flex: 3,
            child: MedicineSearchField(
              initial: draft.medicine,
              focusNode: draft.medicineFocus,
              nextFocusNode: draft.qtyFocus,
              hintText: 'Medicine',
              onSelected: (m) {
                setState(() => draft.medicine = m);
              },
            ),
          ),
          const SizedBox(width: 8),

          SizedBox(
            width: 100,
            child: TextFormField(
              controller: draft.qty,
              focusNode: draft.qtyFocus,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => draft.instructionFocus.requestFocus(),
              decoration: _fieldDecoration(scheme, AppLocalizations.of(context)!.qty),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                return (n == null || n <= 0) ? '> 0' : null;
              },
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            flex: 2,
            child: TextFormField(
              controller: draft.instruction,
              focusNode: draft.instructionFocus,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                widget.onSubmitLastField?.call();
              },
              decoration: _fieldDecoration(
                  scheme, AppLocalizations.of(context)!.instruction),
            ),
          ),
          const SizedBox(width: 8),

          if (widget.onRemove != null) ...[
            IconButton(
              onPressed: widget.onRemove,
              icon: Icon(Icons.close, size: 18, color: scheme.error),
              tooltip: 'Remove',
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(ColorScheme scheme, String label) {
    final side = BorderSide(
      color: scheme.outline.withValues(alpha: 0.3),
      width: 1.2,
    );
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: side,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: side,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: scheme.primary, width: 1.1),
      ),
    );
  }
}