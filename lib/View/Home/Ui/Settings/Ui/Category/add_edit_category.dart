import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/ztextfield.dart';
import '../../../../../../Features/Widgets/z_dialog.dart';
import 'bloc/category_bloc.dart';
import 'model/med_category_model.dart';

class AddEditCategoryForm extends StatefulWidget {
  final Category? category;

  const AddEditCategoryForm({super.key, this.category});

  @override
  State<AddEditCategoryForm> createState() => _AddEditCategoryFormState();
}

class _AddEditCategoryFormState extends State<AddEditCategoryForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _detailsCtrl;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameCtrl    = TextEditingController(text: c?.catName ?? '');
    _detailsCtrl = TextEditingController(text: c?.catDetails ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final req = CategoryRequest(
      catName:    _nameCtrl.text.trim(),
      catDetails: _detailsCtrl.text.trim().isEmpty
          ? null
          : _detailsCtrl.text.trim(),
    );

    final bloc = context.read<CategoryBloc>();
    if (_isEdit) {
      bloc.add(CategoryUpdateRequested(widget.category!.catId, req));
    } else {
      bloc.add(CategoryCreateRequested(req));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategoryActionSuccess) {
          Navigator.of(context).pop(true);
        }
      },
      child: BlocBuilder<CategoryBloc, CategoryState>(
        buildWhen: (prev, curr) =>
        (prev is CategorySaving) != (curr is CategorySaving),
        builder: (context, state) {
          final saving = state is CategorySaving;

          return ZFormDialog(
            title: _isEdit ? 'Edit Category' : 'New Category',
            icon: Icons.category_outlined,
            width: 460,
            padding: const EdgeInsets.all(16),
            isButtonEnabled: !saving,
            onAction: saving ? null : _submit,
            actionLabel: saving
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(_isEdit ? 'Update' : 'Create'),
            child: AbsorbPointer(
              absorbing: saving,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ZTextFieldEntitled(
                        title: 'Category Name *',
                        controller: _nameCtrl,
                        validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      ZTextFieldEntitled(
                        title: 'Details',
                        controller: _detailsCtrl,
                      ),
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