import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/ztextfield.dart';

import '../../../../../Features/Widgets/z_dialog.dart';
import '../Organization/bloc/organization_bloc.dart';
import '../Organization/model/org_model.dart';
import 'bloc/staff_bloc.dart';
import 'model/staff_model.dart';

class AddEditStaffForm extends StatefulWidget {
  final Staff? staff;

  const AddEditStaffForm({super.key, this.staff});

  @override
  State<AddEditStaffForm> createState() => _AddEditStaffFormState();
}

class _AddEditStaffFormState extends State<AddEditStaffForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;

  int? _orgId;
  String _role   = 'PHARMACIST';
  String _gender = 'Male';
  String? _hireDate;
  bool _isActive = true;


  bool get _isEdit => widget.staff != null;

  static const _roles   = ['PHARMACIST', 'ASSISTANT', 'ADMIN'];
  static const _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();

    final s = widget.staff;
    _nameCtrl    = TextEditingController(text: s?.fullName ?? '');
    _phoneCtrl   = TextEditingController(text: s?.phone ?? '');
    _emailCtrl   = TextEditingController(text: s?.email ?? '');
    _addressCtrl = TextEditingController(text: s?.address ?? '');

    _orgId    = s?.orgId;
    _role     = s?.role ?? 'PHARMACIST';
    _gender   = s?.gender ?? 'Male';
    _hireDate = s?.hireDate;
    _isActive = s?.isActive ?? true;

    _loadOrgs();
  }

  Future<void> _loadOrgs() async {
    try {
      // Uses the OrganizationBloc provided at app root — no new bloc needed.
      await context.read<dynamic>();
      // (placeholder — replaced below)
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_orgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an organization')),
      );
      return;
    }

    final req = StaffRequest(
      orgId:    _orgId!,
      fullName: _nameCtrl.text.trim(),
      role:     _role,
      gender:   _gender,
      phone:    _phoneCtrl.text.trim().isEmpty
          ? null
          : _phoneCtrl.text.trim(),
      email:    _emailCtrl.text.trim().isEmpty
          ? null
          : _emailCtrl.text.trim(),
      address:  _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      hireDate: _hireDate,
      isActive: _isActive,
    );

    final bloc = context.read<StaffBloc>();
    if (_isEdit) {
      bloc.add(StaffUpdateRequested(widget.staff!.staffId, req));
    } else {
      bloc.add(StaffCreateRequested(req));
    }
  }

  Future<void> _pickHireDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _hireDate == null
          ? now
          : DateTime.tryParse(_hireDate!) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _hireDate = '${picked.year}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StaffBloc, StaffState>(
      listener: (context, state) {
        if (state is StaffActionSuccess) {
          Navigator.of(context).pop(true);
        }
      },
      child: BlocBuilder<StaffBloc, StaffState>(
        buildWhen: (prev, curr) =>
        (prev is StaffSaving) != (curr is StaffSaving),
        builder: (context, state) {
          final saving = state is StaffSaving;

          return ZFormDialog(
            title: _isEdit ? 'Edit Staff' : 'New Staff',
            icon: Icons.badge_outlined,
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
                      // ── Full Name
                      ZTextFieldEntitled(
                        title: 'Full Name *',
                        controller: _nameCtrl,
                        validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // ── Organization + Role
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _OrgDropdown(
                              selected: _orgId,
                              onChanged: (v) =>
                                  setState(() => _orgId = v),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: _role,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Role *',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 12),
                                border: OutlineInputBorder(),
                              ),
                              items: _roles
                                  .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r),
                              ))
                                  .toList(),
                              onChanged: saving
                                  ? null
                                  : (v) => setState(
                                      () => _role = v ?? 'PHARMACIST'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Gender + Hire date
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _gender,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Gender *',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 12),
                                border: OutlineInputBorder(),
                              ),
                              items: _genders
                                  .map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g),
                              ))
                                  .toList(),
                              onChanged: saving
                                  ? null
                                  : (v) => setState(
                                      () => _gender = v ?? 'Male'),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: saving ? null : _pickHireDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Hire Date',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 12),
                                  border: OutlineInputBorder(),
                                  suffixIcon:
                                  Icon(Icons.calendar_today_outlined,
                                      size: 18),
                                ),
                                child: Text(
                                  _hireDate ?? '—',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _hireDate == null
                                        ? Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Phone + Email
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: ZTextFieldEntitled(
                              title: 'Phone',
                              controller: _phoneCtrl,
                            ),
                          ),
                          Expanded(
                            child: ZTextFieldEntitled(
                              title: 'Email',
                              controller: _emailCtrl,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Address
                      ZTextFieldEntitled(
                        title: 'Address',
                        controller: _addressCtrl,
                      ),
                      const SizedBox(height: 6),

                      // ── Active toggle
                      SwitchListTile.adaptive(
                        value: _isActive,
                        onChanged: saving
                            ? null
                            : (v) => setState(() => _isActive = v),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active',
                            style: TextStyle(fontSize: 14)),
                        subtitle: Text(
                          _isActive
                              ? 'Staff is currently active'
                              : 'Staff is inactive',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
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

// =====================================================================
// Org dropdown — reads from OrganizationBloc
// =====================================================================
class _OrgDropdown extends StatelessWidget {
  final int? selected;
  final ValueChanged<int?> onChanged;

  const _OrgDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationBloc, OrganizationState>(
      builder: (context, state) {
        final orgs = state is OrganizationWithItems
            ? state.items
            : const <Organization>[];

        return DropdownButtonFormField<int>(
          initialValue: selected,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Organization *',
            isDense: true,
            contentPadding:
            EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            border: OutlineInputBorder(),
          ),
          items: orgs
              .map((o) => DropdownMenuItem<int>(
            value: o.orgId,
            child: Text(o.orgName,
                overflow: TextOverflow.ellipsis),
          ))
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}