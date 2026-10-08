import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/toast.dart';
import 'package:zpharmacy/View/Home/Ui/Prescription/prescription_details.dart';
import 'bloc/prescription_bloc.dart';
import 'model/prescription_model.dart';
import 'prescription_form.dart';

class PrescriptionView extends StatefulWidget {
  const PrescriptionView({super.key});

  @override
  State<PrescriptionView> createState() => _PrescriptionViewState();
}

class _PrescriptionViewState extends State<PrescriptionView> {
  @override
  void initState() {
    super.initState();
    context.read<PrescriptionBloc>().add(const PrescriptionLoadRequested());
  }

  Future<void> _openAdd() async {
    final bloc = context.read<PrescriptionBloc>();
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const AddEditPrescriptionForm(),
      ),
    );
    bloc.add(const PrescriptionClearSelection());
  }

  Future<void> _openDetail(Prescription p) async {
    final bloc = context.read<PrescriptionBloc>();
    bloc.add(PrescriptionSelectRequested(p.prescriptionId));
    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: PrescriptionDetails(prescription: p),
      ),
    );
    bloc.add(const PrescriptionClearSelection());
  }

  Future<void> _openEdit(Prescription p) async {
    final bloc = context.read<PrescriptionBloc>();
    bloc.add(PrescriptionSelectRequested(p.prescriptionId));
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AddEditPrescriptionForm(existing: p),
      ),
    );
    bloc.add(const PrescriptionClearSelection());
  }

  Future<void> _confirmCancel(Prescription p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          elevation: 0,
          backgroundColor: scheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: Text('Cancel ${p.registerNo}?'),
          content: const Text(
            'The prescription will be marked as CANCELLED and all '
                'dispensed stock will be returned to its batches.',
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Keep'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Cancel Rx'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (ok == true && mounted) {
      context
          .read<PrescriptionBloc>()
          .add(PrescriptionCancelRequested(p.prescriptionId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: () => context
                .read<PrescriptionBloc>()
                .add(const PrescriptionLoadRequested()),
          ),
        ],
      ),
      body: BlocListener<PrescriptionBloc, PrescriptionState>(
        listener: (context, state) {
          if (state is PrescriptionFailure) {
            ToastManager.show(
              context: context,
              title: 'Failed',
              message: state.message,
              type: ToastType.error,
            );
          }
          if (state is PrescriptionActionSuccess) {
            ToastManager.show(
              context: context,
              title: 'Success',
              message: state.message,
              type: ToastType.success,
            );
          }
        },
        child: BlocBuilder<PrescriptionBloc, PrescriptionState>(
          builder: (context, state) {
            if (state is PrescriptionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PrescriptionFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 56, color: scheme.error),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.error),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => context
                            .read<PrescriptionBloc>()
                            .add(const PrescriptionLoadRequested()),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final items = state is PrescriptionWithItems
                ? state.items
                : const <Prescription>[];

            if (items.isEmpty) {
              return const Center(child: Text('No prescriptions yet'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<PrescriptionBloc>()
                    .add(const PrescriptionLoadRequested());
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: items.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PrescriptionCard(
                    prescription: items[i],
                    onTap: () => _openDetail(items[i]),
                    onEdit: () => _openEdit(items[i]),
                    onCancel: items[i].isCancelled
                        ? null
                        : () => _confirmCancel(items[i]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('New Prescription'),
      ),
    );
  }
}

// =====================================================================
// Compact card
// =====================================================================
class _PrescriptionCard extends StatelessWidget {
  final Prescription prescription;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onCancel;

  const _PrescriptionCard({
    required this.prescription,
    required this.onTap,
    required this.onEdit,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cancelled = prescription.isCancelled;

    // Compact meta line: "R-0001 · M, 32 · 3 items · 07 Oct"
    final meta = <String>[
      prescription.registerNo,
      '${prescription.gender[0]}, ${prescription.age}',
      '${prescription.itemCount} item${prescription.itemCount == 1 ? '' : 's'}',
      prescription.prescriptionDate,
    ].join('  ·  ');

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
          child: Row(
            children: [
              // ---- Small initial avatar ----
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cancelled
                      ? scheme.errorContainer
                      : scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  prescription.patientName.isNotEmpty
                      ? prescription.patientName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cancelled
                        ? scheme.onErrorContainer
                        : scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ---- Name + meta ----
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      prescription.patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: cancelled
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: scheme.onSurfaceVariant,
                        color: cancelled
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant
                            .withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // ---- Status dot ----
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cancelled ? scheme.error : scheme.secondary,
                ),
              ),
              const SizedBox(width: 4),

              // ---- Popup ----
              SizedBox(
                width: 32,
                height: 32,
                child: PopupMenuButton<_MenuAction>(
                  tooltip: 'More',
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                  position: PopupMenuPosition.under,
                  onSelected: (a) {
                    switch (a) {
                      case _MenuAction.view:
                        onTap();
                        break;
                      case _MenuAction.edit:
                        onEdit();
                        break;
                      case _MenuAction.cancel:
                        onCancel?.call();
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: _MenuAction.view,
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('View'),
                        ],
                      ),
                    ),
                    if (!cancelled)
                      const PopupMenuItem(
                        value: _MenuAction.edit,
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (onCancel != null)
                      PopupMenuItem(
                        value: _MenuAction.cancel,
                        child: Row(
                          children: [
                            Icon(Icons.cancel_outlined,
                                size: 18, color: scheme.error),
                            const SizedBox(width: 10),
                            Text(
                              'Cancel Rx',
                              style: TextStyle(color: scheme.error),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MenuAction { view, edit, cancel }