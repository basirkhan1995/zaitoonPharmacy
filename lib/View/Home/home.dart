import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/cover.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';
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
          title: Text(AppLocalizations.of(context)!.logout),
          content: Text(
            AppLocalizations.of(context)!.confirmLogout,
            textAlign: TextAlign.center,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ZOutlineButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    backgroundHover: Theme.of(context).colorScheme.error,
                    label: Text(AppLocalizations.of(context)!.cancel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ZOutlineButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    isActive: true,
                    label: Text(AppLocalizations.of(context)!.logout),
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

    final login = authState.user;
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
        label: "Staff",
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

    if (menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_accounts_rounded,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: .3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.accessDenied,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: .5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please contact administrator",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: .4),
              ),
            ),
          ],
        ),
      );
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          ZNavigator.gotoReplacement(context: context, AuthView());
        }
      },
      child: Scaffold(

        body: Column(
          children: [
            // =====================================================
            // COMPACT TOP BAR
            // =====================================================
            _TopBar(
              orgName: login.orgName,
              fullName: login.fullName,
              role: login.role,
              username: login.username,
              onLogout: () => _confirmLogout(context),
            ),

            Expanded(
              child: GenericMenuWithScreen<MenuName>(
                key: const Key('main_menu'),
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 8),
                margin:
                const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                selectedValue: currentTab,
                onChanged: (val) {
                  if (currentTab != val) {
                    context.read<MenuBloc>().add(MenuOnChangedEvent(val));
                  }
                },
                items: menuItems,
                selectedColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withAlpha(23),
                selectedTextColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withAlpha(230),
                unselectedTextColor:
                Theme.of(context).colorScheme.secondary,
                menuHeaderBuilder: (isExpanded) {
                  return const SizedBox.shrink();
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
// Compact top bar — org on the left, user chip on the right
// =====================================================================
class _TopBar extends StatelessWidget {
  final String orgName;
  final String fullName;
  final String role;
  final String username;
  final VoidCallback onLogout;

  const _TopBar({
    required this.orgName,
    required this.fullName,
    required this.role,
    required this.username,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: ZCover(
        radius: 8,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: scheme.surface,
        borderColor: scheme.primary.withValues(alpha: .2),
        child: Row(
          children: [
            // ── Org (brand)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.local_pharmacy_outlined,
                size: 18,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                orgName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ),

            // ── User chip
            _UserChip(
              fullName: fullName,
              role: role,
              username: username,
              onLogout: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// User chip with popup
// =====================================================================
class _UserChip extends StatelessWidget {
  final String fullName;
  final String role;
  final String username;
  final VoidCallback onLogout;

  const _UserChip({
    required this.fullName,
    required this.role,
    required this.username,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 3,
      onSelected: (value) {
        if (value == 'logout') onLogout();
      },
      itemBuilder: (context) => [
        // Header (not selectable)
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Container(
            width: 260,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: scheme.error),
              const SizedBox(width: 10),
              Text(
                'Logout',
                style: TextStyle(color: scheme.error),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                initial,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fullName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}