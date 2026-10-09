import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/ztextfield.dart';
import 'package:zpharmacy/l10n/app_localizations.dart';

import '../../../../Features/Widgets/z_dialog.dart';
import '../Settings/Ui/Category/category_drop.dart';
import '../Settings/Ui/Category/model/med_category_model.dart';
import 'bloc/medicine_bloc.dart';
import 'model/medicine_model.dart';

class AddEditMedicineDialog extends StatefulWidget {
  final Medicine? medicine;

  const AddEditMedicineDialog({super.key, this.medicine});

  @override
  State<AddEditMedicineDialog> createState() => _AddEditMedicineDialogState();
}

class _AddEditMedicineDialogState extends State<AddEditMedicineDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _dosageCtrl;
  late final TextEditingController _brandCtrl;

  Category? _category;

  bool get _isEdit => widget.medicine != null;

  @override
  void initState() {
    super.initState();

    final m = widget.medicine;
    _nameCtrl   = TextEditingController(text: m?.medName ?? '');
    _unitCtrl   = TextEditingController(text: m?.unit ?? '');
    _dosageCtrl = TextEditingController(text: m?.dosage ?? '');
    _brandCtrl  = TextEditingController(text: m?.companyBrand ?? '');

    if (m != null) {
      _category = Category(catId: m.catId, catName: m.catName);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _dosageCtrl.dispose();
    _brandCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final req = MedicineRequest(
      medName:      _nameCtrl.text.trim(),
      unit:         _unitCtrl.text.trim(),
      dosage:       _dosageCtrl.text.trim().isEmpty
          ? null
          : _dosageCtrl.text.trim(),
      companyBrand: _brandCtrl.text.trim().isEmpty
          ? null
          : _brandCtrl.text.trim(),
      catId:        _category!.catId,
    );

    final bloc = context.read<MedicineBloc>();
    if (_isEdit) {
      bloc.add(MedicineUpdateRequested(widget.medicine!.medId, req));
    } else {
      bloc.add(MedicineCreateRequested(req));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return BlocListener<MedicineBloc, MedicineState>(
      listener: (context, state) {
        if (state is MedicineActionSuccess) {
          Navigator.of(context).pop(true);
        }
      },
      child: BlocBuilder<MedicineBloc, MedicineState>(
        buildWhen: (prev, curr) =>
        (prev is MedicineSaving) != (curr is MedicineSaving),
        builder: (context, state) {
          final saving = state is MedicineSaving;

          return ZFormDialog(
            title: _isEdit ? tr.editMedicine : tr.newMedicine,
            icon: Icons.medical_information_outlined,
            width: 480,
            padding: const EdgeInsets.all(16),
            isButtonEnabled: !saving,
            onAction: saving ? null : _submit,
            actionLabel: saving
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(_isEdit ? tr.update : tr.create),
            child: AbsorbPointer(
              absorbing: saving,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ZTextFieldEntitled(
                        title: tr.medicineName,
                        controller: _nameCtrl,
                        validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: ZTextFieldEntitled(
                              title: tr.unit,
                              controller: _unitCtrl,
                              validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: MedicineCategoryDropView(
                              title: tr.category,
                              hint: tr.selectCategory,
                              selected: _category,
                              enabled: !saving,
                              onSelected: (cat) {
                                setState(() => _category = cat);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ZTextFieldEntitled(
                        title: tr.dosage,
                        controller: _dosageCtrl,
                      ),
                      const SizedBox(height: 12),

                      ZTextFieldEntitled(
                        title: tr.brand,
                        controller: _brandCtrl,
                      ),
                      const SizedBox(height: 12),


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
}