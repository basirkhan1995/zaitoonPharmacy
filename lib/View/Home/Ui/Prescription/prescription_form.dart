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

  // -----------------------------------------------------------------
  // Header controllers + focus nodes
  // -----------------------------------------------------------------
  final _registerNo  = TextEditingController();
  final _patientName = TextEditingController();
  final _age         = TextEditingController();
  final _address     = TextEditingController();
  final _doctorName  = TextEditingController();
  final _diagnosis   = TextEditingController();
  final _note        = TextEditingController();
  String _gender = 'Male';

  final _regFocus       = FocusNode(debugLabel: 'regNo');
  final _nameFocus      = FocusNode(debugLabel: 'patientName');
  final _ageFocus       = FocusNode(debugLabel: 'age');
  final _addressFocus   = FocusNode(debugLabel: 'address');
  final _doctorFocus    = FocusNode(debugLabel: 'doctor');
  final _diagnosisFocus = FocusNode(debugLabel: 'diagnosis');
  final _noteFocus      = FocusNode(debugLabel: 'note');

  // Items (only used in add mode)
  final List<PrescriptionItemDraft> _drafts = [];

  List<PrescriptionItem> _existingItems = const [];

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
      _existingItems    = e.items;
    } else {
      _addItemRow(focusAfterBuild: false);
    }

    if (!_isEdit) {
      context.read<MedicineBloc>().add(const MedicineLoadRequested());
    }

    // Autofocus the register field once the dialog has painted.
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
    _ageFocus.dispose();
    _addressFocus.dispose();
    _doctorFocus.dispose();
    _diagnosisFocus.dispose();
    _noteFocus.dispose();
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  // -----------------------------------------------------------------
  // Rows
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

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // -----------------------------------------------------------------
  // Submit
  // -----------------------------------------------------------------
  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final header = PrescriptionRequest(
      registerNo:  _registerNo.text.trim(),
      patientName: _patientName.text.trim(),
      gender:      _gender,
      age:         int.tryParse(_age.text.trim()) ?? 0,
      address:     _address.text.trim().isEmpty ? null : _address.text.trim(),
      doctorName:  _doctorName.text.trim().isEmpty ? null : _doctorName.text.trim(),
      diagnosis:   _diagnosis.text.trim().isEmpty ? null : _diagnosis.text.trim(),
      note:        _note.text.trim().isEmpty ? null : _note.text.trim(),
      items:       const [],
    );

    if (_isEdit) {
      context.read<PrescriptionBloc>().add(
        PrescriptionUpdateRequested(widget.existing!.prescriptionId, header),
      );
      return;
    }

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
      final days = d.days.text.trim().isEmpty
          ? null
          : int.tryParse(d.days.text.trim());
      items.add(PrescriptionItemRequest(
        medId:             d.medicine!.medId,
        quantity:          qty,
        dosageInstruction: d.instruction.text.trim().isEmpty
            ? null
            : d.instruction.text.trim(),
        durationDays:      days,
      ));
    }
    if (items.isEmpty) {
      _toast('Add at least one medicine');
      return;
    }

    final createReq = PrescriptionRequest(
      registerNo:  header.registerNo,
      patientName: header.patientName,
      gender:      header.gender,
      age:         header.age,
      address:     header.address,
      doctorName:  header.doctorName,
      diagnosis:   header.diagnosis,
      note:        header.note,
      items:       items,
    );

    context.read<PrescriptionBloc>().add(PrescriptionCreateRequested(createReq));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PrescriptionBloc, PrescriptionState>(
      listener: (context, state) {
        if (state is PrescriptionActionSuccess) {
          Navigator.of(context).pop(true);
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
            padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isEdit) _infoBanner(context),

                      _sectionTitle(context, AppLocalizations.of(context)!.patient),
                      const SizedBox(height: 8),

                      // ---------------- Header row 1 ----------------
                      Row(children: [
                        Expanded(
                          child: ZTextFieldEntitled(
                            title: AppLocalizations.of(context)!.regNo,
                            isRequired: true,
                            controller: _registerNo,
                            focusNode: _regFocus,
                            inputAction: TextInputAction.next,
                            onSubmit: (_) => _nameFocus.requestFocus(),
                            validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ZTextFieldEntitled(
                            title: AppLocalizations.of(context)!.patientName,
                            isRequired: true,
                            controller: _patientName,
                            focusNode: _nameFocus,
                            inputAction: TextInputAction.next,
                            onSubmit: (_) => _ageFocus.requestFocus(),
                            validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ZTextFieldEntitled(
                            title: AppLocalizations.of(context)!.age,
                            isRequired: true,
                            controller: _age,
                            focusNode: _ageFocus,
                            inputAction: TextInputAction.next,
                            onSubmit: (_) => _addressFocus.requestFocus(),
                            validator: (v) {
                              final n = int.tryParse(v?.trim() ?? '');
                              return (n == null || n < 0 || n > 150)
                                  ? '0–150'
                                  : null;
                            },
                          ),
                        ),
                      ]),
                      const SizedBox(height: 18),

                      // ---------------- Header row 2 ----------------
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 2,
                            child: ZTextFieldEntitled(
                              title: 'Address',
                              controller: _address,
                              focusNode: _addressFocus,
                              inputAction: TextInputAction.next,
                              onSubmit: (_) => _doctorFocus.requestFocus(),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ---------------- Header row 3 ----------------
                      Row(children: [
                        Expanded(
                          flex: 2,
                          child: ZTextFieldEntitled(
                            title: 'Doctor',
                            controller: _doctorName,
                            focusNode: _doctorFocus,
                            inputAction: TextInputAction.next,
                            onSubmit: (_) => _diagnosisFocus.requestFocus(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ZTextFieldEntitled(
                            title: 'Diagnosis',
                            controller: _diagnosis,
                            focusNode: _diagnosisFocus,
                            onSubmit: (_) => _noteFocus.requestFocus(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: ZTextFieldEntitled(
                            title: 'Note',
                            controller: _note,
                            focusNode: _noteFocus,
                            inputAction: TextInputAction.done,
                            onSubmit: (_) {
                              if (!_isEdit && _drafts.isNotEmpty) {
                                _drafts.first.medicineFocus.requestFocus();
                              }
                            },
                          ),
                        ),
                      ]),

                      const SizedBox(height: 20),

                      if (_isEdit)
                        _editItemsSection(context)
                      else
                        _addItemsSection(context),
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

  // -----------------------------------------------------------------
  // Sections
  // -----------------------------------------------------------------
  Widget _infoBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(Icons.info_outline, size: 18, color: scheme.onTertiaryContainer),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Only patient details can be edited. To change the medicines, cancel this prescription and create a new one.',
            style: TextStyle(fontSize: 12, color: scheme.onTertiaryContainer),
          ),
        ),
      ]),
    );
  }

  Widget _addItemsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: _sectionTitle(context, 'Medicines')),
          TextButton.icon(
            onPressed: () => _addItemRow(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add medicine'),
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
              onRemove: _drafts.length > 1 ? () => _removeItemRow(i) : null,
              onSubmitLastField: () => _addItemRow(),
            ),
          );
        }),
      ],
    );
  }

  Widget _editItemsSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, 'Medicines'),
        const SizedBox(height: 8),
        if (_existingItems.isEmpty)
          const Text('Loading items…')
        else
          ..._existingItems.map((it) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${it.medName}'
                          '${it.dosage != null && it.dosage!.isNotEmpty ? " · ${it.dosage}" : ""}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (it.dosageInstruction != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        it.dosageInstruction!,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                'x${it.quantity}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ]),
          )),
      ],
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
// Draft — PUBLIC so PrescriptionItemRow can reference it in its API
// =====================================================================
class PrescriptionItemDraft {
  final qty         = TextEditingController();
  final instruction = TextEditingController();
  final days        = TextEditingController();
  Medicine? medicine;

  final medicineFocus    = FocusNode(debugLabel: 'row-medicine');
  final qtyFocus         = FocusNode(debugLabel: 'row-qty');
  final daysFocus        = FocusNode(debugLabel: 'row-days');
  final instructionFocus = FocusNode(debugLabel: 'row-instruction');

  void dispose() {
    qty.dispose();
    instruction.dispose();
    days.dispose();
    medicineFocus.dispose();
    qtyFocus.dispose();
    daysFocus.dispose();
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

  /// Called when the user presses Enter in the last field (Instruction).
  /// The parent responds by adding a new row and focusing its medicine field.
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
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              '${widget.index}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ----- Medicine picker -----
          Expanded(
            flex: 2,
            child: MedicineSearchField(
              initial: draft.medicine,
              focusNode: draft.medicineFocus,
              nextFocusNode: draft.qtyFocus,
              hintText: 'Search medicine',
              onSelected: (m) {
                setState(() => draft.medicine = m);
              },
            ),
          ),
          const SizedBox(width: 8),

          // ----- Qty -----
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: draft.qty,
              focusNode: draft.qtyFocus,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => draft.daysFocus.requestFocus(),
              decoration: _fieldDecoration(
                  scheme, AppLocalizations.of(context)!.qty),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                return (n == null || n <= 0) ? '> 0' : null;
              },
            ),
          ),
          const SizedBox(width: 8),

          // ----- Days -----
          SizedBox(
            width: 90,
            child: TextFormField(
              controller: draft.days,
              focusNode: draft.daysFocus,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => draft.instructionFocus.requestFocus(),
              decoration: _fieldDecoration(
                  scheme, AppLocalizations.of(context)!.days),
            ),
          ),
          const SizedBox(width: 8),

          // ----- Instruction (last field) -----
          Expanded(
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
            const SizedBox(width: 6),
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
      color: scheme.outline.withValues(alpha: 0.5),
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
        borderSide: BorderSide(color: scheme.primary, width: 1.2),
      ),
    );
  }
}