import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/toast.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';
import 'package:zpharmacy/Features/Widgets/ztextfield.dart';
import 'bloc/forgot_password_bloc.dart';
import 'model/security_model.dart';


class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ForgotPasswordBody();
  }
}

class _ForgotPasswordBody extends StatefulWidget {
  const _ForgotPasswordBody();

  @override
  State<_ForgotPasswordBody> createState() => _ForgotPasswordBodyState();
}

class _ForgotPasswordBodyState extends State<_ForgotPasswordBody> {
  final _usernameCtrl = TextEditingController();
  final _a1Ctrl       = TextEditingController();
  final _a2Ctrl       = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool _obscurePass = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _a1Ctrl.dispose();
    _a2Ctrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _onStart() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ForgotPasswordBloc>().add(
      ForgotPasswordStartRequested(_usernameCtrl.text.trim()),
    );
  }

  void _onVerify(int userId) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passCtrl.text != _confirmCtrl.text) {
      ToastManager.show(
        context: context,
        title: 'Error',
        message: 'Passwords do not match',
        type: ToastType.error,
      );
      return;
    }

    context.read<ForgotPasswordBloc>().add(
      ForgotPasswordVerifyRequested(
        userId:      userId,
        answer1:     _a1Ctrl.text,
        answer2:     _a2Ctrl.text,
        newPassword: _passCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listener: (context, state) {
        if (state is ForgotPasswordFailure) {
          ToastManager.show(
            context: context,
            title: 'Error',
            message: state.message,
            type: ToastType.error,
          );
        }
        if (state is ForgotPasswordSuccess) {
          ToastManager.show(
            context: context,
            title: 'Success',
            message: state.message,
            type: ToastType.success,
          );
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final loading = state is ForgotPasswordLoading;

        // The two steps share a Form — swap what's inside it.
        final Widget body;
        if (state is ForgotPasswordQuestionsLoaded) {
          body = _step2(
            scheme,
            userId:    state.userId,
            questions: state.questions,
            loading:   loading,
          );
        } else {
          body = _step1(scheme, loading: loading);
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Forgot password')),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [body],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =================================================================
  // Step 1 — username
  // =================================================================
  Widget _step1(ColorScheme scheme, {required bool loading}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Reset your password',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your username to continue.',
          style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 22),
        ZTextFieldEntitled(
          controller: _usernameCtrl,
          title: 'Username',
          isRequired: true,
          onSubmit: (_) => _onStart(),
          validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 46,
          child: ZOutlineButton(
            onPressed: loading ? null : _onStart,
            isActive: true,
            label: loading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Continue'),
          ),
        ),
      ],
    );
  }

  // =================================================================
  // Step 2 — answers + new password
  // =================================================================
  Widget _step2(
      ColorScheme scheme, {
        required int userId,
        required List<SecurityQuestion> questions,
        required bool loading,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Answer your security questions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Answers are case-insensitive.',
          style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 22),

        // Question 1
        Text(
          questions.isNotEmpty ? questions[0].text : '',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        ZTextFieldEntitled(
          controller: _a1Ctrl,
          title: '',
          isRequired: true,
          validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 14),

        // Question 2
        Text(
          questions.length > 1 ? questions[1].text : '',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        ZTextFieldEntitled(
          controller: _a2Ctrl,
          title: '',
          isRequired: true,
          validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 14),

        // New password
        Stack(
          children: [
            ZTextFieldEntitled(
              controller: _passCtrl,
              title: 'New password',
              isRequired: true,
              securePassword: _obscurePass,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 6) return 'At least 6 characters';
                return null;
              },
            ),
            Positioned(
              right: 8,
              top: 26,
              child: IconButton(
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _obscurePass = !_obscurePass),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Confirm
        ZTextFieldEntitled(
          controller: _confirmCtrl,
          title: 'Confirm password',
          isRequired: true,
          securePassword: _obscurePass,
          validator: (v) =>
          (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 18),

        SizedBox(
          height: 46,
          child: ZOutlineButton(
            onPressed: loading ? null : () => _onVerify(userId),
            isActive: true,
            label: loading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Reset password'),
          ),
        ),
      ],
    );
  }
}