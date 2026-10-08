import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../Features/Widgets/z_dialog.dart';
import 'bloc/prescription_bloc.dart';
import 'model/prescription_model.dart';

//Prescription Details
class PrescriptionDetails extends StatelessWidget {
  final Prescription prescription;
  const PrescriptionDetails({super.key, required this.prescription});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<PrescriptionBloc, PrescriptionState>(
      builder: (context, state) {
        // If the bloc has a fully loaded detail (with items), prefer it
        final full = (state is PrescriptionLoaded && state.selected != null)
            ? state.selected!
            : prescription;

        return ZFormDialog(
          title: 'Rx ${full.registerNo}',
          icon: Icons.receipt_long_outlined,
          width: 680,
          padding: const EdgeInsets.all(16),
          isActionTrue: false, // no action buttons — read-only
          onAction: null,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Patient block
                _kv(scheme, 'Patient',  '${full.patientName} · ${full.gender} · ${full.age}'),
                _kv(scheme, 'Register', full.registerNo),
                _kv(scheme, 'Date',     full.prescriptionDate),
                if (full.doctorName != null) _kv(scheme, 'Doctor',    full.doctorName!),
                if (full.diagnosis  != null) _kv(scheme, 'Diagnosis', full.diagnosis!),
                if (full.address    != null) _kv(scheme, 'Address',   full.address!),
                if (full.note       != null) _kv(scheme, 'Note',      full.note!),

                const SizedBox(height: 16),
                Text('MEDICINES',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    )),
                const SizedBox(height: 8),

                if (full.items.isEmpty)
                  const Text('No items')
                else
                  ...full.items.map((it) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${it.medName}'
                                    '${it.dosage != null ? " · ${it.dosage}" : ""}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text('x${it.quantity}'),
                          ],
                        ),
                        if (it.dosageInstruction != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            it.dosageInstruction!,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (it.dispensedBatches.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: it.dispensedBatches.map((b) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: scheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${b.batchNo} · ${b.quantity}'
                                      '${b.expiryDate != null ? " · exp ${b.expiryDate}" : ""}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSecondaryContainer,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kv(ColorScheme scheme, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              k,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}