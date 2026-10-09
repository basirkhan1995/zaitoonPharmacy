import 'package:flutter/material.dart';
import 'package:zpharmacy/Features/Widgets/znavigator.dart';
import 'package:zpharmacy/View/Home/Ui/Report/MedicineReport/medicine_report_view.dart';
import 'package:zpharmacy/View/Home/Ui/Report/StockCard/stoc_card_view.dart';
import 'AntibioticReport/antibiotic_report.dart';
import 'TallySheet/tally_sheet.dart';

class ReportView extends StatelessWidget {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- Header ----------------
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.insert_chart_outlined,
                    size: 32,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Choose a report to view',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ---------------- Section title ----------------
            Text(
              'STOCK REPORTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            // ---------------- Cards ----------------
            _ReportCard(
              icon: Icons.assessment_outlined,
              title: 'Stock Card',
              description:
              'Movement history of a single medicine with opening '
                  'balance, running balance, and batch details.',
              accent: scheme.primary,
              bg: scheme.primaryContainer,
              onTap: () => ZNavigator.goto(
                context: context,
                const StockCardView(),
              ),
            ),
            const SizedBox(height: 12),

            _ReportCard(
              icon: Icons.list_alt_outlined,
              title: 'Medicines Report',
              description:
              'Summary of all medicines in a date range: '
                  'opening, in, out, closing balance, and sources.',
              accent: scheme.tertiary,
              bg: scheme.tertiaryContainer,
              onTap: () => ZNavigator.goto(
                context: context,
                const MedicineReportView(),
              ),
            ),
            const SizedBox(height: 12),

            _ReportCard(
              icon: Icons.receipt_long_outlined,
              title: 'Tally Sheet',
              description:
              'Per-medicine out tally: every dispense, damage, expiry '
                  'and donation out — with a running total per medicine.',
              accent: scheme.error,
              bg: scheme.errorContainer,
              onTap: () => ZNavigator.goto(
                context: context,
                const TallySheetView(),
              ),
            ),
            const SizedBox(height: 12),

            _ReportCard(
              icon: Icons.assignment_outlined,
              title: 'Antibiotic Form',
              description:
              'Daily antibiotic percentage and polypharmacy analysis '
                  'form with a printable Excel layout for HF Name / Code.',
              accent: scheme.secondary,
              bg: scheme.secondaryContainer,
              onTap: () => ZNavigator.goto(
                context: context,
                const AntibioticReportView(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// =====================================================================
// Report card
// =====================================================================
class _ReportCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final Color bg;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.bg,
    required this.onTap,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered
              ? scheme.surfaceContainer
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered
                ? widget.accent.withValues(alpha: 0.4)
                : scheme.outline.withValues(alpha: 0.2),
            width: _hovered ? 1.2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.icon,
                      size: 26,
                      color: widget.accent,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Arrow
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 150),
                    offset: _hovered
                        ? const Offset(0.15, 0)
                        : Offset.zero,
                    child: Icon(
                      Icons.arrow_forward_ios_outlined,
                      size: 16,
                      color: _hovered
                          ? widget.accent
                          : scheme.onSurfaceVariant,
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