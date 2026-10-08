import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/zdropdown.dart';

import '../Organization/bloc/organization_bloc.dart';
import '../Organization/model/org_model.dart';

/// A self-contained organization picker that wraps your ZDropdown.
///
/// Loads organizations via [OrganizationBloc], then renders them
/// in a [ZDropdown]<Organization>.
///
/// Usage:
/// ```dart
/// OrganizationPickerField(
///   title: 'Organization *',
///   selected: _selectedOrg,
///   onSelected: (org) => setState(() => _selectedOrg = org),
/// )
/// ```
class OrganizationPickerField extends StatefulWidget {
  /// Label above the dropdown.
  final String title;

  /// Currently selected organization (nullable).
  final Organization? selected;

  /// Fires when the user picks an organization.
  final ValueChanged<Organization> onSelected;

  /// Placeholder shown when nothing is selected.
  final String initialValue;

  /// Disable the dropdown.
  final bool enabled;

  /// Optional custom height. Defaults to 40.
  final double? height;

  /// Optional custom radius. Defaults to 4.
  final double? radius;

  /// Optional bloc override. When null, reads from context.
  final OrganizationBloc? bloc;

  /// When true (default), loads organizations on first mount
  /// if the bloc doesn't already have any.
  final bool autoLoad;

  const OrganizationPickerField({
    super.key,
    this.title = 'Organization *',
    this.selected,
    required this.onSelected,
    this.initialValue = 'Select organization',
    this.enabled = true,
    this.height,
    this.radius,
    this.bloc,
    this.autoLoad = true,
  });

  @override
  State<OrganizationPickerField> createState() =>
      _OrganizationPickerFieldState();
}

class _OrganizationPickerFieldState extends State<OrganizationPickerField> {
  late OrganizationBloc _bloc;

  @override
  void initState() {
    super.initState();

    _bloc = widget.bloc ?? context.read<OrganizationBloc>();

    if (widget.autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final s = _bloc.state;
        final hasData = s is OrganizationWithItems && s.items.isNotEmpty;
        if (!hasData) {
          _bloc.add(const OrganizationLoadRequested());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<OrganizationBloc, OrganizationState>(
      bloc: _bloc,
      builder: (context, state) {
        // ---------------- Loading ----------------
        if (state is OrganizationLoading) {
          return _wrap(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        // ---------------- Error ----------------
        if (state is OrganizationFailure) {
          return _wrap(
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(widget.radius ?? 4),
              ),
              child: Row(children: [
                Icon(Icons.error_outline,
                    size: 16, color: scheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh,
                      size: 16, color: scheme.onErrorContainer),
                  tooltip: 'Retry',
                  onPressed: () =>
                      _bloc.add(const OrganizationLoadRequested()),
                ),
              ]),
            ),
          );
        }

        // ---------------- Items ----------------
        final List<Organization> items = state is OrganizationWithItems
            ? state.items
            : const [];

        // ---------------- Empty ----------------
        if (items.isEmpty) {
          return _wrap(
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(widget.radius ?? 4),
                border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(
                    'No organizations found',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh,
                      size: 16, color: scheme.onSurfaceVariant),
                  tooltip: 'Reload',
                  onPressed: () =>
                      _bloc.add(const OrganizationLoadRequested()),
                ),
              ]),
            ),
          );
        }

        // ---------------- Success — your ZDropdown ----------------
        // Guard: if selected points at a deleted org, fall back to null
        final validSelection = widget.selected != null &&
            items.any((o) => o.orgId == widget.selected!.orgId)
            ? widget.selected
            : null;

        return ZDropdown<Organization>(
          title: widget.title,
          items: items,
          itemLabel: (org) => org.orgName,
          selectedItem: validSelection,
          initialValue: widget.initialValue,
          radius: widget.radius ?? 4,
          height: widget.height ?? 40,
          disableAction: !widget.enabled,
          onItemSelected: widget.onSelected,
          // Optional: show a small circular avatar with the initial
          leadingBuilder: (org) => Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              org.orgName.isNotEmpty
                  ? org.orgName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Wraps loading/error/empty states with the same title style used
  /// by ZDropdown when `title` is provided.
  Widget _wrap(Widget child) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title.isNotEmpty) ...[
          Text(
            widget.title,
            style: TextStyle(fontSize: 12, color: scheme.outline),
          ),
          const SizedBox(height: 4),
        ],
        child,
      ],
    );
  }
}