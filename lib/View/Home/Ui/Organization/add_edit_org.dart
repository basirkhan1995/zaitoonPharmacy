import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/ztextfield.dart';
import '../../../../Features/Widgets/z_dialog.dart';
import '../../../../Services/api_services.dart';
import 'bloc/organization_bloc.dart';
import 'model/org_model.dart';

class AddEditOrganizationDialog extends StatefulWidget {
  final Organization? organization;
  const AddEditOrganizationDialog({super.key, this.organization});

  @override
  State<AddEditOrganizationDialog> createState() =>
      _AddEditOrganizationDialogState();
}

class _AddEditOrganizationDialogState extends State<AddEditOrganizationDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _contact;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _note;

  File? _logoFile;

  bool get _isEdit => widget.organization != null;

  @override
  void initState() {
    super.initState();
    final o = widget.organization;
    _name    = TextEditingController(text: o?.orgName ?? '');
    _email   = TextEditingController(text: o?.email ?? '');
    _contact = TextEditingController(text: o?.contact ?? '');
    _phone   = TextEditingController(text: o?.phone ?? '');
    _address = TextEditingController(text: o?.address ?? '');
    _note    = TextEditingController(text: o?.note ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _contact.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }



  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final req = OrganizationRequest(
      orgName: _name.text.trim(),
      email:   _email.text.trim().isEmpty   ? null : _email.text.trim(),
      contact: _contact.text.trim().isEmpty ? null : _contact.text.trim(),
      phone:   _phone.text.trim().isEmpty   ? null : _phone.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      note:    _note.text.trim().isEmpty    ? null : _note.text.trim(),
      logo:    _logoFile,
    );

    final bloc = context.read<OrganizationBloc>();
    if (_isEdit) {
      bloc.add(OrganizationUpdateRequested(widget.organization!.orgId, req));
    } else {
      bloc.add(OrganizationCreateRequested(req));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocListener<OrganizationBloc, OrganizationState>(
      listener: (context, state) {
        if (state is OrganizationActionSuccess) {
          Navigator.of(context).pop(true);
        }
      },
      child: BlocBuilder<OrganizationBloc, OrganizationState>(
        buildWhen: (p, c) =>
        (p is OrganizationSaving) != (c is OrganizationSaving),
        builder: (context, state) {
          final saving = state is OrganizationSaving;

          return ZFormDialog(
            title: _isEdit ? 'Edit Organization' : 'New Organization',
            icon: Icons.business_outlined,
            width: 520,
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
                      // Logo picker
                      Center(
                        child: GestureDetector(
                          onTap: (){},
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: scheme.outlineVariant,
                                width: 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _logoFile != null
                                ? Image.file(_logoFile!, fit: BoxFit.cover)
                                : (widget.organization?.hasLogo == true
                                ? Image.network(
                              '${ApiServices.baseUrl}/api/organizations/${widget.organization!.orgId}/logo',
                              fit: BoxFit.cover,
                            )
                                : Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined,
                                    size: 28,
                                    color: scheme.onPrimaryContainer),
                                const SizedBox(height: 4),
                                Text(
                                  'Add logo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            )),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      ZTextFieldEntitled(
                        title: 'Organization name',
                        controller: _name,
                        validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      ZTextFieldEntitled(
                        title: 'Contact person',
                        controller: _contact,
                      ),
                      const SizedBox(height: 12),

                      ZTextFieldEntitled(
                        title: 'Phone',
                        controller: _phone,
                      ),
                      const SizedBox(height: 12),

                      ZTextFieldEntitled(
                        title: 'Email',
                        controller: _email,
                      ),
                      const SizedBox(height: 12),

                      ZTextFieldEntitled(
                        title: 'Address',
                        controller: _address,
                      ),
                      const SizedBox(height: 12),

                      ZTextFieldEntitled(
                        title: 'Note',
                        controller: _note,
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