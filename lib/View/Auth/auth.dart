import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/toast.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';
import 'package:zpharmacy/Features/Widgets/znavigator.dart';
import 'package:zpharmacy/Features/Widgets/ztextfield.dart';
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
  final usrName = TextEditingController();
  final usrPass = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _rememberMe = false;
  @override
  void dispose() {
    usrName.dispose();
    usrPass.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(formKey.currentState?.validate() ?? false)) return;

    context.read<AuthBloc>().add(
      AuthLoginRequested(
        username: usrName.text.trim(),
        password: usrPass.text,
        rememberMe: _rememberMe,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.loginTitle),
        actionsPadding: const EdgeInsets.all(8),
        actions: [
          LocaleSelector(width: 150),
          const SizedBox(width: 8),
          ThemeSelector(width: 150),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ToastManager.show(context: context,
                title: "Access Denied",
                message: state.message, type: ToastType.error);
          }

          // Navigate on success
          if (state is AuthAuthenticated) {
            ZNavigator.gotoReplacement(context: context, HomeView());
          }
        },
        child: Center(
          child: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  SizedBox(
                    width: 200,
                    child: Image.asset("assets/images/zPharma.png"),
                  ),
                  ZTextFieldEntitled(
                    controller: usrName,
                    title: tr.usrName,
                    onSubmit: (e) => _submit(),
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return tr.required(tr.usrName);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  ZTextFieldEntitled(
                    controller: usrPass,
                    title: tr.usrPass,
                    onSubmit: (e) => _submit(),
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return tr.required(tr.usrPass);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  // Remember me row
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) => setState(() => _rememberMe = value ?? false),
                        visualDensity: VisualDensity.compact,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _rememberMe = !_rememberMe),
                          child: Text(
                            tr.rememberMe,        // add to your l10n
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final loading = state is AuthLoading;
                      return ZOutlineButton(
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
                        onPressed: loading ? () {} : _submit,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}