import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/toast.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';
import 'package:zpharmacy/Features/Widgets/znavigator.dart';
import 'package:zpharmacy/View/Home/home.dart';
import 'SecurityQuestions/security_questions_bloc.dart';
import 'model/security_model.dart';

class SecurityQuestionsSetup extends StatelessWidget {
  final bool forceSetup;

  const SecurityQuestionsSetup({super.key, this.forceSetup = false});

  @override
  Widget build(BuildContext context) {
    return _SecurityQuestionsBody(forceSetup: forceSetup);
  }
}

class _SecurityQuestionsBody extends StatefulWidget {
  final bool forceSetup;
  const _SecurityQuestionsBody({required this.forceSetup});

  @override
  State<_SecurityQuestionsBody> createState() => _SecurityQuestionsBodyState();
}

class _SecurityQuestionsBodyState extends State<_SecurityQuestionsBody> {
  final _a1Ctrl = TextEditingController();
  final _a2Ctrl = TextEditingController();

  int? _q1Id;
  int? _q2Id;

  @override
  void dispose() {
    _a1Ctrl.dispose();
    _a2Ctrl.dispose();
    super.dispose();
  }

  void _save() {
    // Local validation first — same rules the backend enforces.
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

    context.read<SecurityQuestionsBloc>().add(
      SecurityQuestionsSaveRequested(
        q1Id: _q1Id!,
        a1:   _a1Ctrl.text.trim(),
        q2Id: _q2Id!,
        a2:   _a2Ctrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !widget.forceSetup,
      child: BlocConsumer<SecurityQuestionsBloc, SecurityQuestionsState>(
        listener: (context, state) {
          if (state is SecurityQuestionsSaved) {
            ToastManager.show(
              context: context,
              title: 'Saved',
              message: 'Security questions updated',
              type: ToastType.success,
            );
            if (widget.forceSetup) {
              ZNavigator.gotoReplacement(context: context, const HomeView());
            } else {
              Navigator.of(context).pop();
            }
          }
          if (state is SecurityQuestionsSaveFailure) {
            ToastManager.show(
              context: context,
              title: 'Error',
              message: state.message,
              type: ToastType.error,
            );
          }
        },
        builder: (context, state) {
          // ── Loading the catalogue ────────────────────────────────
          if (state is SecurityQuestionsInitial ||
              state is SecurityQuestionsLoading) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Security questions'),
                automaticallyImplyLeading: !widget.forceSetup,
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          // ── Load failed — show error + retry ──────────────────────
          if (state is SecurityQuestionsFailure) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Security questions'),
                automaticallyImplyLeading: !widget.forceSetup,
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off,
                          size: 48, color: scheme.error),
                      const SizedBox(height: 12),
                      const Text(
                        'Could not load security questions',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      ZOutlineButton(
                        onPressed: () => context
                            .read<SecurityQuestionsBloc>()
                            .add(const SecurityQuestionsLoadRequested()),
                        isActive: true,
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // ── Catalogue ready — render form ─────────────────────────
          final questions = switch (state) {
            SecurityQuestionsLoaded s         => s.questions,
            SecurityQuestionsSaving s         => s.questions,
            SecurityQuestionsSaved s          => s.questions,
            SecurityQuestionsSaveFailure s    => s.questions,
            _                                 => const <SecurityQuestion>[],
          };

          final saving = state is SecurityQuestionsSaving;

          return Scaffold(
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
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: questions
                            .map((q) => DropdownMenuItem<int>(
                          value: q.id,
                          child: Text(q.text,
                              overflow: TextOverflow.ellipsis),
                        ))
                            .toList(),
                        onChanged: saving
                            ? null
                            : (v) => setState(() => _q1Id = v),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _a1Ctrl,
                        enabled: !saving,
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
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: questions
                            .where((q) => q.id != _q1Id)
                            .map((q) => DropdownMenuItem<int>(
                          value: q.id,
                          child: Text(q.text,
                              overflow: TextOverflow.ellipsis),
                        ))
                            .toList(),
                        onChanged: saving
                            ? null
                            : (v) => setState(() => _q2Id = v),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _a2Ctrl,
                        enabled: !saving,
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
                          onPressed: saving ? null : _save,
                          isActive: true,
                          label: saving
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                            CircularProgressIndicator(strokeWidth: 2),
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
          );
        },
      ),
    );
  }
}