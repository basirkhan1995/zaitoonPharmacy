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

  // -----------------------------------------------------------------
  // Add
  // -----------------------------------------------------------------
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

  // -----------------------------------------------------------------
  // View — MUST dispatch Select first so items arrive from the API
  // -----------------------------------------------------------------
  Future<void> _openDetail(Prescription p) async {
    final bloc = context.read<PrescriptionBloc>();

    // Ask the bloc to fetch the full detail (items + dispensed batches)
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

  // -----------------------------------------------------------------
  // Edit
  // -----------------------------------------------------------------
  Future<void> _openEdit(Prescription p) async {
    final bloc = context.read<PrescriptionBloc>();

    // Ensure items are loaded so the read-only medicine list has data
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

  // -----------------------------------------------------------------
  // Cancel confirmation
  // -----------------------------------------------------------------
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
            'The prescription will be marked as CANCELLED. '
                'Stock already dispensed is NOT returned.',
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
                  padding: const EdgeInsets.only(bottom: 10),
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
// Card
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

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cancelled
                      ? scheme.errorContainer
                      : scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  cancelled
                      ? Icons.cancel_outlined
                      : Icons.receipt_long_outlined,
                  color: cancelled
                      ? scheme.onErrorContainer
                      : scheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prescription.patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${prescription.registerNo}  •  '
                          '${prescription.gender}, ${prescription.age}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${prescription.prescriptionDate}  •  '
                          '${prescription.itemCount} item(s)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant
                            .withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cancelled
                      ? scheme.errorContainer
                      : scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cancelled ? 'Cancelled' : 'Dispensed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cancelled
                        ? scheme.onErrorContainer
                        : scheme.onSecondaryContainer,
                  ),
                ),
              ),

              // Popup
              PopupMenuButton<_MenuAction>(
                icon: Icon(Icons.more_vert,
                    color: scheme.onSurfaceVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
            ],
          ),
        ),
      ),
    );
  }
}

enum _MenuAction { view, edit, cancel }

