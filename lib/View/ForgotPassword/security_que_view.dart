import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/toast.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';
import 'package:zpharmacy/Features/Widgets/znavigator.dart';
import 'package:zpharmacy/Services/repository.dart';
import 'package:zpharmacy/View/Home/home.dart';
import 'model/security_model.dart';

class SecurityQuestionsSetup extends StatefulWidget {
  /// When true, the user was forced here after login because they had no
  /// security questions. Back-navigation is blocked and a successful save
  /// routes into the app instead of popping.
  final bool forceSetup;

  const SecurityQuestionsSetup({super.key, this.forceSetup = false});

  @override
  State<SecurityQuestionsSetup> createState() => _SecurityQuestionsSetupState();
}

class _SecurityQuestionsSetupState extends State<SecurityQuestionsSetup> {
  final _a1Ctrl = TextEditingController();
  final _a2Ctrl = TextEditingController();

  List<SecurityQuestion> _all = const [];
  int? _q1Id;
  int? _q2Id;
  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = context.read<Repositories>();
      final list = await repo.getSecurityQuestions();
      if (!mounted) return;
      setState(() {
        _all     = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _a1Ctrl.dispose();
    _a2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_q1Id == null || _q2Id == null) {
      ToastManager.show(
        context: context,
        title: 'Error',
        message: 'Pick two questions',
        type: ToastType.error,
      );
      return;
    }
    if (_q1Id == _q2Id) {
      ToastManager.show(
        context: context,
        title: 'Error',
        message: 'Questions must be different',
        type: ToastType.error,
      );
      return;
    }
    if (_a1Ctrl.text.trim().isEmpty || _a2Ctrl.text.trim().isEmpty) {
      ToastManager.show(
        context: context,
        title: 'Error',
        message: 'Answers cannot be empty',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = context.read<Repositories>();
      await repo.saveSecurityQuestions(
        q1Id: _q1Id!,
        a1:   _a1Ctrl.text,
        q2Id: _q2Id!,
        a2:   _a2Ctrl.text,
      );
      if (!mounted) return;

      ToastManager.show(
        context: context,
        title: 'Saved',
        message: 'Security questions updated',
        type: ToastType.success,
      );

      if (widget.forceSetup) {
        // Forced flow — enter the app.
        ZNavigator.gotoReplacement(context: context, const HomeView());
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ToastManager.show(
        context: context,
        title: 'Error',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: !widget.forceSetup,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Security questions'),
          automaticallyImplyLeading: !widget.forceSetup,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.forceSetup
                        ? 'Before you continue, set two security questions. '
                        'You will need them if you ever forget your password.'
                        : 'Set two questions you can answer if you forget your password.',
                    style: TextStyle(
                        fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 22),

                  // Question 1
                  DropdownButtonFormField<int>(
                    initialValue: _q1Id,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Question 1',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    items: _all
                        .map((q) => DropdownMenuItem<int>(
                      value: q.id,
                      child: Text(q.text,
                          overflow: TextOverflow.ellipsis),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => _q1Id = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _a1Ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Answer 1',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Question 2
                  DropdownButtonFormField<int>(
                    initialValue: _q2Id,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Question 2',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    items: _all
                        .where((q) => q.id != _q1Id)
                        .map((q) => DropdownMenuItem<int>(
                      value: q.id,
                      child: Text(q.text,
                          overflow: TextOverflow.ellipsis),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => _q2Id = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _a2Ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Answer 2',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 26),

                  SizedBox(
                    height: 46,
                    child: ZOutlineButton(
                      onPressed: _saving ? null : _save,
                      isActive: true,
                      label: _saving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text(widget.forceSetup
                          ? 'Save & continue'
                          : 'Save'),
                    ),
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