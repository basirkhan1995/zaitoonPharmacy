import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/ztextfield.dart';
import '../../../../../../Features/Widgets/z_dialog.dart';
import '../../../Staff/bloc/staff_bloc.dart';
import '../../../Staff/model/staff_model.dart';
import 'bloc/users_bloc.dart';
import 'model/users_model.dart';

class AddEditUsersForm extends StatefulWidget {
  final UserAccount? user;

  const AddEditUsersForm({super.key, this.user});

  @override
  State<AddEditUsersForm> createState() => _AddEditUsersFormState();
}

class _AddEditUsersFormState extends State<AddEditUsersForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;

  int? _staffId;
  bool _isActive = true;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();

    final u = widget.user;
    _usernameCtrl = TextEditingController(text: u?.username ?? '');
    _passwordCtrl = TextEditingController();
    _staffId      = u?.staffId;
    _isActive     = u?.isActive ?? true;

    // Ensure the staff list is loaded (no-op if already loaded)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final staffState = context.read<StaffBloc>().state;
      if (staffState is! StaffWithItems) {
        context.read<StaffBloc>().add(const StaffLoadRequested());
      }
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_staffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a staff member')),
      );
      return;
    }

    final req = UserAccountRequest(
      staffId:  _staffId!,
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text.trim().isEmpty
          ? null
          : _passwordCtrl.text.trim(),
      isActive: _isActive,
    );

    final bloc = context.read<UsersBloc>();
    if (_isEdit) {
      bloc.add(UsersUpdateRequested(widget.user!.userId, req));
    } else {
      bloc.add(UsersCreateRequested(req));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UsersBloc, UsersState>(
      listener: (context, state) {
        if (state is UsersActionSuccess) {
          Navigator.of(context).pop(true);
        }
      },
      child: BlocBuilder<UsersBloc, UsersState>(
        buildWhen: (prev, curr) =>
        (prev is UsersSaving) != (curr is UsersSaving),
        builder: (context, state) {
          final saving = state is UsersSaving;

          return ZFormDialog(
            title: _isEdit ? 'Edit User' : 'New User',
            icon: Icons.manage_accounts_outlined,
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
                : Text(_isEdit ? 'Update' : 'Create'),
            child: AbsorbPointer(
              absorbing: saving,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Staff picker — bound to StaffBloc
                      Text(
                        'Staff Member *',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      BlocBuilder<StaffBloc, StaffState>(
                        builder: (context, staffState) {
                          if (staffState is StaffLoading) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: LinearProgressIndicator(minHeight: 2),
                            );
                          }

                          final staffList = staffState is StaffWithItems
                              ? staffState.items
                              : const <Staff>[];

                          return DropdownButtonFormField<int>(
                            initialValue: _staffId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: staffList.isEmpty
                                  ? 'No staff available'
                                  : 'Select staff',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 12),
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            items: staffList
                                .map<DropdownMenuItem<int>>((s) {
                              return DropdownMenuItem<int>(
                                value: s.staffId,
                                child: Text(
                                  '${s.fullName} · ${s.role}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: saving
                                ? null
                                : (v) => setState(() => _staffId = v),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // ── Username
                      ZTextFieldEntitled(
                        title: 'Username *',
                        controller: _usernameCtrl,
                        validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // ── Password
                      ZTextFieldEntitled(
                        title: _isEdit
                            ? 'New Password (leave empty to keep current)'
                            : 'Password *',
                        controller: _passwordCtrl,
                        securePassword: true,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (!_isEdit && value.isEmpty) return 'Required';
                          if (value.isNotEmpty && value.length < 6) {
                            return 'At least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

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
                              ? 'User can log in'
                              : 'User cannot log in',
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