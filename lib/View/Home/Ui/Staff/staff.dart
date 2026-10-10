import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/toast.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';

import '../../../../../Features/Widgets/shimmer.dart';
import 'add_edit_staff.dart';
import 'bloc/staff_bloc.dart';
import 'model/staff_model.dart';

class StaffView extends StatefulWidget {
  const StaffView({super.key});

  @override
  State<StaffView> createState() => _StaffViewState();
}

class _StaffViewState extends State<StaffView> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _search = '';

  @override
  void initState() {
    super.initState();
    context.read<StaffBloc>().add(const StaffLoadRequested());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _search = value.trim().toLowerCase());
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _search = '');
  }

  void _reload() {
    context.read<StaffBloc>().add(const StaffLoadRequested());
  }

  Future<void> _openAddEdit({Staff? staff}) async {
    final bloc = context.read<StaffBloc>();
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AddEditStaffForm(staff: staff),
      ),
    );
  }

  Future<void> _confirmDelete(Staff s) async {
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
          title: Text('Delete ${s.fullName}?'),
          content: const Text('This action cannot be undone.'),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
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
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (ok == true && mounted) {
      context.read<StaffBloc>().add(StaffDeleteRequested(s.staffId));
    }
  }

  List<Staff> _applyFilter(List<Staff> all) {
    if (_search.isEmpty) return all;
    return all.where((s) {
      return s.fullName.toLowerCase().contains(_search) ||
          s.role.toLowerCase().contains(_search) ||
          (s.orgName ?? '').toLowerCase().contains(_search) ||
          (s.phone ?? '').contains(_search) ||
          (s.email ?? '').toLowerCase().contains(_search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocListener<StaffBloc, StaffState>(
        listener: (context, state) {
          if (state is StaffFailure) {
            ToastManager.show(
              context: context,
              title: 'Failed',
              message: state.message,
              type: ToastType.error,
            );
          }
          if (state is StaffActionSuccess) {
            ToastManager.show(
              context: context,
              title: 'Success',
              message: state.message,
              type: ToastType.success,
            );
          }
        },
        child: Column(
          children: [
            // =====================================================
            // HEADER
            // =====================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.badge_outlined,
                    size: 28,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'Staff',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),

                  Row(
                    spacing: 8,
                    children: [
                      ZOutlineButton(
                        onPressed: _reload,
                        icon: Icons.refresh,
                        label: const Text('Refresh'),
                      ),
                      ZOutlineButton(
                        onPressed: () => _openAddEdit(),
                        icon: Icons.add,
                        isActive: true,
                        label: const Text('New Staff'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // =====================================================
            // SEARCH
            // =====================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by name, role, org, phone, or email',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Clear',
                    onPressed: _clearSearch,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
                  filled: true,
                  fillColor: scheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: BorderSide(
                      color: scheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: BorderSide(
                      color: scheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: BorderSide(
                      color: scheme.primary,
                      width: 1.1,
                    ),
                  ),
                ),
              ),
            ),

            // =====================================================
            // LIST
            // =====================================================
            Expanded(
              child: BlocBuilder<StaffBloc, StaffState>(
                builder: (context, state) {
                  if (state is StaffLoading) {
                    return UniversalShimmer.dataList(
                      itemCount: 15,
                      numberOfColumns: 5,
                    );
                  }
                  if (state is StaffFailure) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: _reload,
                    );
                  }

                  final all = state is StaffWithItems
                      ? state.items
                      : const <Staff>[];

                  final items = _applyFilter(all);

                  if (items.isEmpty) {
                    final hasSearch = _searchCtrl.text.trim().isNotEmpty;
                    return _EmptyView(hasSearch: hasSearch);
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: items.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _StaffCard(
                          staff: items[i],
                          onTap: () => _openAddEdit(staff: items[i]),
                          onEdit: () => _openAddEdit(staff: items[i]),
                          onDelete: () => _confirmDelete(items[i]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Card
// =====================================================================
class _StaffCard extends StatelessWidget {
  final Staff staff;
  final VoidCallback onTap, onEdit, onDelete;

  const _StaffCard({
    required this.staff,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  staff.fullName.isNotEmpty
                      ? staff.fullName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            staff.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (staff.role.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: scheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              staff.role,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: scheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (staff.orgName != null && staff.orgName!.isNotEmpty)
                          staff.orgName!,
                        if (staff.phone != null && staff.phone!.isNotEmpty)
                          staff.phone!,
                      ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Active status chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: staff.isActive
                      ? scheme.secondaryContainer
                      : scheme.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  staff.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: staff.isActive
                        ? scheme.onSecondaryContainer
                        : scheme.onErrorContainer,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              PopupMenuButton<_MenuAction>(
                tooltip: 'More',
                icon: Icon(
                  Icons.more_vert,
                  color: scheme.onSurfaceVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
                position: PopupMenuPosition.under,
                onSelected: (a) {
                  switch (a) {
                    case _MenuAction.edit:
                      onEdit();
                      break;
                    case _MenuAction.delete:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _MenuAction.edit,
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 18, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 10),
                        const Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _MenuAction.delete,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: scheme.error),
                        const SizedBox(width: 10),
                        Text('Delete',
                            style: TextStyle(color: scheme.error)),
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

enum _MenuAction { edit, delete }

// =====================================================================
// Empty view
// =====================================================================
class _EmptyView extends StatelessWidget {
  final bool hasSearch;
  const _EmptyView({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearch ? Icons.search_off : Icons.badge_outlined,
              size: 56,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
            Text(
              hasSearch ? 'No matches' : 'No staff yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasSearch
                  ? 'Try a different search term'
                  : 'Tap "New Staff" to get started',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: scheme.error),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}