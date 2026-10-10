import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Settings/bloc/settings_tab_bloc.dart';
import '../../../Home/bloc/menu_bloc.dart';
import 'bloc/dashboard_stats_bloc.dart';

class DashboardStatsView extends StatelessWidget {
  const DashboardStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardStatsBloc, DashboardStatsState>(
      builder: (context, state) {
        // Error — full error view (rare)
        if (state is DashboardStatsFailure) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context
                .read<DashboardStatsBloc>()
                .add(const DashboardStatsLoadRequested()),
          );
        }

        // Show the layout regardless — during load the numbers shimmer
        final loading = state is DashboardStatsInitial || state is DashboardStatsLoading;
        final stats = state is DashboardStatsLoaded ? state.stats : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.dashboard_outlined,
                    size: 22,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Live snapshot of today and inventory',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () => context
                      .read<DashboardStatsBloc>()
                      .add(const DashboardStatsLoadRequested()),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Today
            const _SectionTitle('TODAY'),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, c) {
                final cols = _columnsFor(c.maxWidth);
                return _Grid(
                  cols: cols,
                  children: [
                    _StatCard(
                      icon: Icons.receipt_long_outlined,
                      label: "Today's Prescriptions",
                      value: loading
                          ? null
                          : '${stats!.today.prescriptions}',
                      accent: const Color(0xFF2563EB),
                      bg: const Color(0xFFDBEAFE),
                      onTap: () => _goTo(context, MenuName.prescription),
                    ),
                    _StatCard(
                      icon: Icons.outbox_outlined,
                      label: 'Medicines Out',
                      value: loading
                          ? null
                          : '${stats!.today.medicinesOut}',
                      accent: const Color(0xFFDC2626),
                      bg: const Color(0xFFFEE2E2),
                      onTap: () => _goTo(context, MenuName.stock),
                    ),
                    _StatCard(
                      icon: Icons.move_to_inbox_outlined,
                      label: 'Medicines In',
                      value: loading
                          ? null
                          : '${stats!.today.medicinesIn}',
                      accent: const Color(0xFF059669),
                      bg: const Color(0xFFD1FAE5),
                      onTap: () => _goTo(context, MenuName.stock),
                    ),
                    _StatCard(
                      icon: Icons.medical_services_outlined,
                      label: 'Antibiotic Items',
                      value: loading
                          ? null
                          : '${stats!.today.antibioticItems}  ·  ${stats.today.antibioticPercent.toStringAsFixed(1)}%',
                      accent: const Color(0xFF7C3AED),
                      bg: const Color(0xFFEDE9FE),
                      onTap: null,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // ── Inventory
            const _SectionTitle('INVENTORY'),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, c) {
                final cols = _columnsFor(c.maxWidth);
                return _Grid(
                  cols: cols,
                  children: [
                    _StatCard(
                      icon: Icons.medication_outlined,
                      label: 'Medicines Catalog',
                      value: loading
                          ? null
                          : '${stats!.inventory.medicinesCatalog}',
                      accent: const Color(0xFF0EA5E9),
                      bg: const Color(0xFFE0F2FE),
                      onTap: () => _goTo(context, MenuName.medicine),
                    ),
                    _StatCard(
                      icon: Icons.qr_code_2_outlined,
                      label: 'Active Batches',
                      value: loading
                          ? null
                          : '${stats!.inventory.activeBatches}',
                      accent: const Color(0xFF6366F1),
                      bg: const Color(0xFFE0E7FF),
                      onTap: () => _goTo(context, MenuName.stock),
                    ),
                    _StatCard(
                      icon: Icons.medical_information_outlined,
                      label: 'Units in Stock',
                      value: loading
                          ? null
                          : '${stats!.inventory.unitsInStock}',
                      accent: const Color(0xFF14B8A6),
                      bg: const Color(0xFFCCFBF1),
                      onTap: () => _goTo(context, MenuName.stock),
                    ),
                    _StatCard(
                      icon: Icons.warning_amber_rounded,
                      label: 'Expiry Alerts',
                      value: loading ? null : '${stats!.expiry.total}',
                      accent: const Color(0xFFDC2626),
                      bg: const Color(0xFFFEE2E2),
                      onTap: () => _goTo(context, MenuName.report),
                      subtitle: loading
                          ? null
                          : '${stats!.expiry.expired} expired · '
                          '${stats.expiry.within3m} ≤3m · '
                          '${stats.expiry.within6m} ≤6m',
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // ── Directory
            const _SectionTitle('DIRECTORY'),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, c) {
                final cols = _columnsFor(c.maxWidth);
                return _Grid(
                  cols: cols,
                  children: [
                    _StatCard(
                      icon: Icons.business_outlined,
                      label: 'Organizations',
                      value: loading
                          ? null
                          : '${stats!.directory.organizations}',
                      accent: const Color(0xFF0EA5E9),
                      bg: const Color(0xFFE0F2FE),
                      onTap: () => _goTo(context, MenuName.organization),
                    ),
                    _StatCard(
                      icon: Icons.badge_outlined,
                      label: 'Staff',
                      value: loading ? null : '${stats!.directory.staff}',
                      accent: const Color(0xFFF59E0B),
                      bg: const Color(0xFFFEF3C7),
                      onTap: () => _goTo(context, MenuName.staff),
                    ),
                    _StatCard(
                      icon: Icons.manage_accounts_outlined,
                      label: 'Users',
                      value: loading ? null : '${stats!.directory.users}',
                      accent: const Color(0xFF7C3AED),
                      bg: const Color(0xFFEDE9FE),
                      onTap: () {
                        _goTo(context, MenuName.settings);
                        _goTo2(context, SettingsTabName.users);
                      },
                    ),
                    _StatCard(
                      icon: Icons.category_outlined,
                      label: 'Categories',
                      value: loading
                          ? null
                          : '${stats!.directory.categories}',
                      accent: const Color(0xFF059669),
                      bg: const Color(0xFFD1FAE5),
                      onTap: () {
                        _goTo(context, MenuName.settings);
                        _goTo2(context, SettingsTabName.category);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _goTo(BuildContext context, MenuName target) {
    final menuBloc = context.read<MenuBloc>();
    if (menuBloc.state.tabs != target) {
      menuBloc.add(MenuOnChangedEvent(target));
    }
  }

  void _goTo2(BuildContext context, SettingsTabName target) {
    final settingBloc = context.read<SettingsTabBloc>();
    if (settingBloc.state.tabs != target) {
      settingBloc.add(SettingsOnChangeEvent(target));
    }
  }

  int _columnsFor(double width) {
    if (width >= 900) return 4;
    if (width >= 560) return 2;
    return 1;
  }
}

// =====================================================================
// Section title
// =====================================================================
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// =====================================================================
// Responsive grid
// =====================================================================
class _Grid extends StatelessWidget {
  final int cols;
  final List<Widget> children;

  const _Grid({required this.cols, required this.children});

  @override
  Widget build(BuildContext context) {
    const gap = 10.0;
    return LayoutBuilder(
      builder: (context, c) {
        final itemW = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((w) => SizedBox(width: itemW, child: w))
              .toList(),
        );
      },
    );
  }
}

// =====================================================================
// Stat card — value is nullable → shows shimmer when null
// =====================================================================
class _StatCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? value;          // null = loading → shimmer
  final Color accent;
  final Color bg;
  final VoidCallback? onTap;
  final String? subtitle;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.bg,
    this.onTap,
    this.subtitle,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final interactive = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: interactive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered && interactive
                ? widget.accent.withValues(alpha: 0.5)
                : scheme.outline.withValues(alpha: 0.18),
            width: _hovered && interactive ? 1.3 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row — icon + label + arrow
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: widget.bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Icon(widget.icon,
                            size: 18, color: widget.accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      if (interactive)
                        AnimatedSlide(
                          duration: const Duration(milliseconds: 150),
                          offset: _hovered
                              ? const Offset(0.15, 0)
                              : Offset.zero,
                          child: Icon(
                            Icons.arrow_forward_ios_outlined,
                            size: 12,
                            color: _hovered
                                ? widget.accent
                                : scheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Value row — number on the left, subtitle inline on the right
                  SizedBox(
                    height: 26,
                    child: widget.value == null
                        ? const _ShimmerNumber()
                        : Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          widget.value!,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            color: widget.accent,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
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

// =====================================================================
// Shimmer strip used in place of the number
// =====================================================================
class _ShimmerNumber extends StatefulWidget {
  const _ShimmerNumber();

  @override
  State<_ShimmerNumber> createState() => _ShimmerNumberState();
}

class _ShimmerNumberState extends State<_ShimmerNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final highlight = scheme.surfaceContainerLowest.withValues(alpha: 0.95);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: 72,
          height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + _ctrl.value * 3, 0),
              end: Alignment(-0.5 + _ctrl.value * 3, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

// =====================================================================
// Error view
// =====================================================================
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 32, color: scheme.error),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: scheme.onErrorContainer),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}