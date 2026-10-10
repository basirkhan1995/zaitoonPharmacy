import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/znavigator.dart';
import '../ExpiryAlertReport/expiry_alert_batch_report.dart';
import 'bloc/expiry_notify_bloc.dart';
import 'model/expiry_notify_model.dart';

class ExpiryNotifyCard extends StatelessWidget {
  const ExpiryNotifyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<ExpiryNotifyBloc, ExpiryNotifyState>(
      builder: (context, state) {
        final loading = state is ExpiryNotifyInitial ||
            state is ExpiryNotifyLoading;
        final summary = state is ExpiryNotifyLoaded ? state.summary : null;
        final failure = state is ExpiryNotifyFailure ? state.message : null;

        final hasIssues = summary?.hasIssues ?? false;

        final accent = !hasIssues
            ? const Color(0xFF059669)
            : (summary!.expired > 0
            ? const Color(0xFFDC2626)
            : const Color(0xFFEA580C));

        return _CardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header
              Row(
                children: [
                  _HeaderIcon(accent: accent, loading: loading),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Expiry Alerts',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: scheme.onSurface,
                              ),
                            ),
                            if (hasIssues) ...[
                              const SizedBox(width: 8),
                              _Badge(label: 'Action needed', color: accent),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          failure ??
                              (loading
                                  ? 'Checking inventory…'
                                  : hasIssues
                                  ? '${summary!.total} batch${summary.total == 1 ? '' : 'es'} need attention'
                                  : 'All batches are healthy'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: failure != null
                                ? scheme.error
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ViewAllButton(accent: accent),
                  const SizedBox(width: 4),
                  _RefreshButton(loading: loading, accent: accent),
                ],
              ),

              const SizedBox(height: 14),

              // ── Body
              if (failure != null && summary == null)
                _EmptyState(message: failure)
              else ...[
                // The UrgencyBar slot is ALWAYS present in the tree —
                // it just collapses to zero height when there are no issues.
                // This keeps the tile row's position stable across rebuilds.
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: hasIssues
                      ? Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _UrgencyBar(
                      summary: summary!,
                      scheme: scheme,
                    ),
                  )
                      : const SizedBox(width: double.infinity),
                ),

                // ── Keyed tile row — prevents state loss when siblings change
                Row(
                  key: const ValueKey('expiry-stat-tiles'),
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.error_outline_rounded,
                        label: 'Expired',
                        sublabel: 'past expiry',
                        count: summary?.expired,
                        accent: const Color(0xFFDC2626),
                        gradient: const [
                          Color(0xFFFEE2E2),
                          Color(0xFFFEF2F2),
                        ],
                        onTap: () => ZNavigator.goto(
                          context: context,
                          const ExpiryAlertView(initialFilter: 'expired'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.warning_amber_rounded,
                        label: '≤ 3 Months',
                        sublabel: 'urgent',
                        count: summary?.within3m,
                        accent: const Color(0xFFEA580C),
                        gradient: const [
                          Color(0xFFFFEDD5),
                          Color(0xFFFFF7ED),
                        ],
                        onTap: () => ZNavigator.goto(
                          context: context,
                          const ExpiryAlertView(initialFilter: '3m'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.schedule_rounded,
                        label: '≤ 6 Months',
                        sublabel: 'watchlist',
                        count: summary?.within6m,
                        accent: const Color(0xFFD97706),
                        gradient: const [
                          Color(0xFFFEF3C7),
                          Color(0xFFFFFBEB),
                        ],
                        onTap: () => ZNavigator.goto(
                          context: context,
                          const ExpiryAlertView(initialFilter: '6m'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// =====================================================================
// Card shell
// =====================================================================
class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}

// =====================================================================
// Header icon — no animation
// =====================================================================
class _HeaderIcon extends StatelessWidget {
  final Color accent;
  final bool loading;

  const _HeaderIcon({required this.accent, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: accent,
        ),
      )
          : Icon(
        Icons.notifications_active_rounded,
        size: 20,
        color: accent,
      ),
    );
  }
}

// =====================================================================
// Small pill badge
// =====================================================================
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: color,
        ),
      ),
    );
  }
}

// =====================================================================
// View-all & refresh buttons
// =====================================================================
class _ViewAllButton extends StatelessWidget {
  final Color accent;
  const _ViewAllButton({required this.accent});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => ZNavigator.goto(
        context: context,
        const ExpiryAlertView(),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
      label: const Text(
        'View all',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _RefreshButton extends StatefulWidget {
  final bool loading;
  final Color accent;
  const _RefreshButton({required this.loading, required this.accent});

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.loading) _spin.repeat();
  }

  @override
  void didUpdateWidget(covariant _RefreshButton old) {
    super.didUpdateWidget(old);
    if (widget.loading && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.loading && _spin.isAnimating) {
      _spin.stop();
      _spin.value = 0;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'Refresh',
      child: InkWell(
        onTap: widget.loading
            ? null
            : () => context
            .read<ExpiryNotifyBloc>()
            .add(const ExpiryNotifyLoadRequested()),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: RotationTransition(
            turns: _spin,
            child: Icon(
              Icons.refresh_rounded,
              size: 16,
              color: widget.loading
                  ? widget.accent.withValues(alpha: 0.5)
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Segmented urgency bar
// =====================================================================
class _UrgencyBar extends StatelessWidget {
  final ExpirySummary summary;
  final ColorScheme scheme;

  const _UrgencyBar({required this.summary, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final total = summary.total;
    if (total == 0) return const SizedBox.shrink();

    final segments = [
      _Segment(count: summary.expired,  color: const Color(0xFFDC2626)),
      _Segment(count: summary.within3m, color: const Color(0xFFEA580C)),
      _Segment(count: summary.within6m, color: const Color(0xFFD97706)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 6,
            child: Row(
              children: segments
                  .where((s) => s.count > 0)
                  .map((s) => Expanded(
                flex: s.count,
                child: Container(color: s.color),
              ))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final s in segments) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: s.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _segmentLabel(s),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ],
        ),
      ],
    );
  }

  String _segmentLabel(_Segment s) {
    final pct = ((s.count / summary.total) * 100).round();
    return '${s.count} · $pct%';
  }
}

class _Segment {
  final int count;
  final Color color;
  const _Segment({required this.count, required this.color});
}

// =====================================================================
// Stat tile — count is nullable; null renders a shimmer
// =====================================================================
class _StatTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final int? count;
  final Color accent;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.count,
    required this.accent,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loading = widget.count == null;
    final isEmpty = !loading && widget.count == 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: loading
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
            0, (_hovered && !loading) ? -2 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: (isEmpty || loading)
                ? [
              scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              scheme.surfaceContainerHighest.withValues(alpha: 0.15),
            ]
                : widget.gradient,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (isEmpty || loading)
                ? scheme.outline.withValues(alpha: 0.15)
                : widget.accent.withValues(
              alpha: _hovered ? 0.5 : 0.2,
            ),
            width: _hovered && !isEmpty && !loading ? 1.4 : 1,
          ),
          boxShadow: _hovered && !isEmpty && !loading
              ? [
            BoxShadow(
              color: widget.accent.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.icon,
                        size: 15,
                        color: (isEmpty || loading)
                            ? scheme.onSurfaceVariant
                            : widget.accent,
                      ),
                      const Spacer(),
                      if (!isEmpty && !loading)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: _hovered ? 1 : 0,
                          child: Icon(
                            Icons.arrow_outward_rounded,
                            size: 13,
                            color: widget.accent,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Big count — shimmer when loading
                  SizedBox(
                    height: 26,
                    child: loading
                        ? const _ShimmerNumber()
                        : Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${widget.count}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          letterSpacing: -0.5,
                          color: isEmpty
                              ? scheme.onSurfaceVariant
                              : widget.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                          color: (isEmpty || loading)
                              ? scheme.onSurfaceVariant
                              : widget.accent,
                        ),
                      ),
                      Text(
                        ' · ${widget.sublabel}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
// Empty state
// =====================================================================
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 28,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}