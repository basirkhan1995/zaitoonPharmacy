import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/znavigator.dart';
import 'package:zpharmacy/View/Auth/bloc/auth_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Medicine/medicine.dart';
import 'package:zpharmacy/View/Home/Ui/Organization/organization.dart';
import 'package:zpharmacy/View/Home/Ui/Prescription/prescription.dart';
import 'package:zpharmacy/View/Home/Ui/Staff/staff.dart';
import 'package:zpharmacy/View/Home/Ui/Stock/stock.dart';
import 'package:zpharmacy/l10n/app_localizations.dart';
import '../../Features/Widgets/generic_menu.dart';
import '../Auth/auth.dart';
import 'Ui/Dashboard/dashboard.dart';
import 'Ui/Report/report.dart';
import 'Ui/Settings/settings.dart';
import 'bloc/menu_bloc.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          icon: Icon(Icons.logout_rounded, color: scheme.error, size: 28),
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
            textAlign: TextAlign.center,
          ),
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
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const AuthLogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.select((AuthBloc bloc) => bloc.state);
    if (authState is! AuthAuthenticated) {
      return const SizedBox();
    }

    final user = authState.user;

    final menuItems = [
      MenuDefinition(
        value: MenuName.dashboard,
        label: AppLocalizations.of(context)!.dashboard,
        screen: const DashboardView(),
        icon: Icons.add_home_outlined,
      ),
      MenuDefinition(
        value: MenuName.prescription,
        label: AppLocalizations.of(context)!.prescription,
        screen: const PrescriptionView(),
        icon: Icons.document_scanner_outlined,
      ),
      MenuDefinition(
        value: MenuName.medicine,
        label: AppLocalizations.of(context)!.medicine,
        screen: const MedicineView(),
        icon: Icons.medical_information_outlined,
      ),
      MenuDefinition(
        value: MenuName.stock,
        label: AppLocalizations.of(context)!.stock,
        screen: const StockView(),
        icon: Icons.medical_services_outlined,
      ),
      MenuDefinition(
        value: MenuName.organization,
        label: AppLocalizations.of(context)!.organization,
        screen: const OrganizationView(),
        icon: Icons.location_city_outlined,
      ),
      MenuDefinition(
        value: MenuName.staff,
        label: 'Staff',
        screen: const StaffView(),
        icon: Icons.people,
      ),
      MenuDefinition(
        value: MenuName.settings,
        label: AppLocalizations.of(context)!.settings,
        screen: const SettingsView(),
        icon: Icons.settings_outlined,
      ),
      MenuDefinition(
        value: MenuName.report,
        label: AppLocalizations.of(context)!.report,
        screen: const ReportView(),
        icon: Icons.info_outlined,
      ),
    ];

    final currentTab = context.select((MenuBloc bloc) => bloc.state.tabs);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          ZNavigator.gotoReplacement(context: context, AuthView());
        }
      },
      child: Scaffold(
        body: GenericMenuWithScreen<MenuName>(
          key: const Key('main_menu'),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          margin: const EdgeInsets.all(10),
          selectedValue: currentTab,
          onChanged: (val) {
            if (currentTab != val) {
              context.read<MenuBloc>().add(MenuOnChangedEvent(val));
            }
          },
          items: menuItems,
          selectedColor: Theme.of(context).colorScheme.primary.withAlpha(23),
          selectedTextColor:
          Theme.of(context).colorScheme.primary.withAlpha(230),
          unselectedTextColor: Theme.of(context).colorScheme.secondary,

          // ── Header: org name only
          menuHeaderBuilder: (isExpanded) => _MenuHeader(
            isExpanded: isExpanded,
            orgName:    user.orgName,
          ),

          // ── Footer: user info + logout
          menuFooterBuilder: (isExpanded) => _MenuFooter(
            isExpanded: isExpanded,
            username:   user.username,
            role:       user.role,
            onLogout:   () => _confirmLogout(context),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Sidebar header — org name only, no box
// =====================================================================
class _MenuHeader extends StatelessWidget {
  final bool isExpanded;
  final String orgName;

  const _MenuHeader({
    required this.isExpanded,
    required this.orgName,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // ── Collapsed: initial letter tile
    if (!isExpanded) {
      final initial = orgName.isNotEmpty ? orgName[0].toUpperCase() : '?';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: Tooltip(
          message: orgName,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      );
    }

    // ── Expanded: just the org name, up to 2 lines, no decoration
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Text(
        orgName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          height: 1.25,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

// =====================================================================
// Sidebar footer — user info on the left, Logout on the right
// =====================================================================
class _MenuFooter extends StatefulWidget {
  final bool isExpanded;
  final String username;
  final String role;
  final VoidCallback onLogout;

  const _MenuFooter({
    required this.isExpanded,
    required this.username,
    required this.role,
    required this.onLogout,
  });

  @override
  State<_MenuFooter> createState() => _MenuFooterState();
}

class _MenuFooterState extends State<_MenuFooter> {
  bool _logoutHovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // ── Collapsed: compact "Out" chip with tooltip
    if (!widget.isExpanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Tooltip(
          message: '${widget.username} · ${widget.role}\nLogout',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onLogout,
              onHover: (h) => setState(() => _logoutHovered = h),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 40,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _logoutHovered
                        ? scheme.error.withValues(alpha: 0.35)
                        : scheme.outline.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  'Out',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _logoutHovered
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ── Expanded: [username / role] ................ [Logout]
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.role,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Logout
          MouseRegion(
            onEnter: (_) => setState(() => _logoutHovered = true),
            onExit: (_) => setState(() => _logoutHovered = false),
            cursor: SystemMouseCursors.click,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onLogout,
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _logoutHovered
                        ? scheme.error.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      color: _logoutHovered
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}