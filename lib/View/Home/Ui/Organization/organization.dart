import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/toast.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart'; // ZOutlineButton
import '../../../../Features/Widgets/shimmer.dart';
import '../../../../Services/api_services.dart';
import 'add_edit_org.dart';
import 'bloc/organization_bloc.dart';
import 'model/org_model.dart';

class OrganizationView extends StatefulWidget {
  const OrganizationView({super.key});

  @override
  State<OrganizationView> createState() => _OrganizationViewState();
}

class _OrganizationViewState extends State<OrganizationView> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _search = ''; // normalized (lowercased, trimmed) query

  @override
  void initState() {
    super.initState();
    context.read<OrganizationBloc>().add(const OrganizationLoadRequested());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {}); // rebuild so the clear (×) icon shows/hides
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
    context.read<OrganizationBloc>().add(const OrganizationLoadRequested());
  }

  Future<void> _openAddEdit({Organization? org}) async {
    final bloc = context.read<OrganizationBloc>();
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AddEditOrganizationDialog(organization: org),
      ),
    );
  }

  Future<void> _confirmDelete(Organization o) async {
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
          title: Text('Delete ${o.orgName}?'),
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
      context
          .read<OrganizationBloc>()
          .add(OrganizationDeleteRequested(o.orgId));
    }
  }

  List<Organization> _applyFilter(List<Organization> all) {
    if (_search.isEmpty) return all;
    return all.where((o) {
      final name = o.orgName.toLowerCase();
      final contact = (o.contact ?? '').toLowerCase();
      final phone = (o.phone ?? '').toLowerCase();
      return name.contains(_search) ||
          contact.contains(_search) ||
          phone.contains(_search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocListener<OrganizationBloc, OrganizationState>(
        listener: (context, state) {
          if (state is OrganizationFailure) {
            ToastManager.show(
              context: context,
              title: 'Failed',
              message: state.message,
              type: ToastType.error,
            );
          }
          if (state is OrganizationActionSuccess) {
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
            // HEADER — icon + title on left, buttons on right
            // =====================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon badge
                  Icon(
                    Icons.business_outlined,
                    size: 28,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),

                  // Title
                  Expanded(
                    child: Text(
                      'Organizations',
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

                  // Actions
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
                        label: const Text('New'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // =====================================================
            // SEARCH BAR
            // =====================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search organization',
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
              child: BlocBuilder<OrganizationBloc, OrganizationState>(
                builder: (context, state) {
                  if (state is OrganizationLoading) {
                    return UniversalShimmer.accountList(
                      itemCount: 8,
                      useAlternatingColors: true,
                    );
                  }
                  if (state is OrganizationFailure) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: _reload,
                    );
                  }

                  final allItems = state is OrganizationWithItems
                      ? state.items
                      : const <Organization>[];

                  final items = _applyFilter(allItems);

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
                        child: _OrgCard(
                          org: items[i],
                          onTap: () => _openAddEdit(org: items[i]),
                          onEdit: () => _openAddEdit(org: items[i]),
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
// Card (compact)
// =====================================================================
class _OrgCard extends StatelessWidget {
  final Organization org;
  final VoidCallback onTap, onEdit, onDelete;

  const _OrgCard({
    required this.org,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 2, 8),
          child: Row(
            children: [
              // Logo
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(5),
                ),
                clipBehavior: Clip.antiAlias,
                child: org.hasLogo
                    ? Image.network(
                  '${ApiServices.baseUrl}/api/organizations/${org.orgId}/logo',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      _initial(scheme, org.orgName),
                )
                    : _initial(scheme, org.orgName),
              ),
              const SizedBox(width: 10),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      org.orgName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((org.contact != null && org.contact!.isNotEmpty) ||
                        (org.phone != null && org.phone!.isNotEmpty)) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (org.contact != null &&
                              org.contact!.isNotEmpty)
                            Flexible(
                              child: Text(
                                org.contact!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          if (org.contact != null &&
                              org.contact!.isNotEmpty &&
                              org.phone != null &&
                              org.phone!.isNotEmpty)
                            Text(
                              '  •  ',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          if (org.phone != null && org.phone!.isNotEmpty)
                            Text(
                              org.phone!,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Menu
              PopupMenuButton<_MenuAction>(
                icon: Icon(Icons.more_vert,
                    size: 20, color: scheme.onSurfaceVariant),
                padding: EdgeInsets.zero,
                splashRadius: 20,
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
                itemBuilder: (_) => [
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

  Widget _initial(ColorScheme scheme, String name) => Center(
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(
        color: scheme.onPrimaryContainer,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  );
}

enum _MenuAction { edit, delete }

// =====================================================================
// Empty view (search-aware)
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
              hasSearch ? Icons.search_off : Icons.business_outlined,
              size: 56,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
            Text(
              hasSearch ? 'No matches' : 'No organizations yet',
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
                  : 'Tap "New" to get started',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

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
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.error)),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}