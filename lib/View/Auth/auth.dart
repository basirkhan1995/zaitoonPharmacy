import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';
import 'package:zpharmacy/Features/Widgets/znavigator.dart';
import 'package:zpharmacy/Features/Widgets/ztextfield.dart';
import 'package:zpharmacy/Services/credential_store.dart';
import 'package:zpharmacy/Themes/Ui/theme_selector.dart';
import 'package:zpharmacy/l10n/app_localizations.dart';
import 'package:zpharmacy/l10n/locale_selector.dart';

import '../Home/home.dart';
import 'bloc/auth_bloc.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _usrName    = TextEditingController();
  final _usrPass    = TextEditingController();
  final _usrPassFn  = FocusNode();
  final _formKey    = GlobalKey<FormState>();
  bool _rememberMe  = false;
  bool _obscurePass = true;
  bool _bootstrapped = false;

  /// Inline error shown below the button (login failure / session expired).
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final saved = await CredentialStore.load();
    if (!mounted) return;
    setState(() {
      if (saved.username != null) {
        _usrName.text = saved.username!;
      }
      if (saved.password != null) {
        _usrPass.text = saved.password!;
        _rememberMe = true;
      }
      _bootstrapped = true;
    });
  }

  @override
  void dispose() {
    _usrName.dispose();
    _usrPass.dispose();
    _usrPassFn.dispose();
    super.dispose();
  }

  void _submit() {
    // Clear any previous error before attempting again
    setState(() => _inlineError = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        username:   _usrName.text.trim(),
        password:   _usrPass.text,
        rememberMe: _rememberMe,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Show session-expired message inline (once)
          if (state is AuthUnauthenticated &&
              state.message != null &&
              _inlineError == null) {
            setState(() => _inlineError = state.message);
          }

          // Show login failures inline
          if (state is AuthFailure) {
            setState(() => _inlineError = state.message);
          }

          // Navigate on success
          if (state is AuthAuthenticated) {
            ZNavigator.gotoReplacement(context: context, HomeView());
          }
        },
        child: Stack(
          children: [
            // ── Selectors top-right
            Positioned(
              top: 12,
              right: 12,
              child: SafeArea(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LocaleSelector(width: 130),
                    const SizedBox(width: 8),
                    ThemeSelector(width: 130),
                  ],
                ),
              ),
            ),

            // ── Login card
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 80),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _LoginCard(
                    formKey:          _formKey,
                    usrName:          _usrName,
                    usrPass:          _usrPass,
                    usrPassFn:        _usrPassFn,
                    rememberMe:       _rememberMe,
                    obscurePass:      _obscurePass,
                    bootstrapped:     _bootstrapped,
                    inlineError:      _inlineError,
                    onToggleRemember: (v) =>
                        setState(() => _rememberMe = v),
                    onToggleObscure: () => setState(
                            () => _obscurePass = !_obscurePass),
                    onSubmit:         _submit,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Login card
// =====================================================================
class _LoginCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usrName;
  final TextEditingController usrPass;
  final FocusNode usrPassFn;
  final bool rememberMe;
  final bool obscurePass;
  final bool bootstrapped;
  final String? inlineError;
  final ValueChanged<bool> onToggleRemember;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _LoginCard({
    required this.formKey,
    required this.usrName,
    required this.usrPass,
    required this.usrPassFn,
    required this.rememberMe,
    required this.obscurePass,
    required this.bootstrapped,
    required this.inlineError,
    required this.onToggleRemember,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final tr     = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Logo
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/images/zaitoonLogo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.local_pharmacy_outlined,
                    size: 40,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Title
            Text(
              tr.loginTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Sign in to continue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.outline,
              ),
            ),
            const SizedBox(height: 26),

            // ── Username
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: bootstrapped ? 1.0 : 0.0,
              child: ZTextFieldEntitled(
                controller: usrName,
                title:      tr.usrName,
                isRequired: true,
                onSubmit:   (_) => usrPassFn.requestFocus(),
                validator:  (value) {
                  if (value == null || value.isEmpty) {
                    return tr.required(tr.usrName);
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),

            // ── Password with eye toggle
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: bootstrapped ? 1.0 : 0.0,
              child: _PasswordField(
                controller:      usrPass,
                focusNode:       usrPassFn,
                label:           tr.usrPass,
                obscure:         obscurePass,
                onToggleObscure: onToggleObscure,
                onSubmit:        (_) => onSubmit(),
                validator:       (value) {
                  if (value == null || value.isEmpty) {
                    return tr.required(tr.usrPass);
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),

            // ── Remember me
            InkWell(
              onTap: () => onToggleRemember(!rememberMe),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 4, horizontal: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: rememberMe,
                        onChanged: (v) =>
                            onToggleRemember(v ?? false),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      tr.rememberMe,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Sign-in button
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final loading = state is AuthLoading;
                return SizedBox(
                  height: 46,
                  child: ZOutlineButton(
                    width: double.infinity,
                    label: loading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : Text(tr.loginTitle),
                    isActive: true,
                    onPressed: loading ? () {} : onSubmit,
                  ),
                );
              },
            ),

            // ── Inline error — text only, under the button
            if (inlineError != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1.5),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 15,
                      color: scheme.error,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      inlineError!,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: scheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // ── Forgot password (functionality wired later)
            Center(
              child: TextButton(
                onPressed: () {
                  // TODO: handle "forgot password" flow
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Password field with eye toggle
// =====================================================================
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final ValueChanged<String> onSubmit;
  final String? Function(String?) validator;

  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        ZTextFieldEntitled(
          controller:     controller,
          focusNode:      focusNode,
          title:          label,
          isRequired:     true,
          securePassword: obscure,
          onSubmit:       onSubmit,
          validator:      validator,
        ),
        Positioned(
          right: 8,
          top: 26,
          child: IconButton(
            tooltip: obscure ? 'Show' : 'Hide',
            icon: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            onPressed: onToggleObscure,
            splashRadius: 18,
          ),
        ),
      ],
    );
  }
}