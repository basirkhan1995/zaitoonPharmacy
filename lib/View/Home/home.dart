import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';
import 'package:zpharmacy/Features/Widgets/znavigator.dart';
import 'package:zpharmacy/View/Auth/bloc/auth_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Medicine/medicine.dart';
import 'package:zpharmacy/View/Home/Ui/Organization/organization.dart';
import 'package:zpharmacy/View/Home/Ui/Prescription/prescription.dart';
import 'package:zpharmacy/View/Home/Ui/Stock/stock.dart';
import 'package:zpharmacy/l10n/app_localizations.dart';
import '../../Features/Widgets/generic_menu.dart';
import '../Auth/auth.dart';
import 'Ui/Dashboard/dashboard.dart';
import 'Ui/Report/report.dart';
import 'Ui/Settings/settings.dart';
import 'bloc/menu_bloc.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.accessDenied,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please contact administrator",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .4),
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
        appBar: AppBar(
          title: const Text('Home'),
          actions: [
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              onPressed: () => _confirmLogout(context),
            ),
          ],
        ),
        body: GenericMenuWithScreen<MenuName>(
          key: const Key('main_menu'),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
          selectedValue: currentTab,
          onChanged: (val) {
            if (currentTab != val) {
              context.read<MenuBloc>().add(MenuOnChangedEvent(val));
            }
          },
          items: menuItems,
          selectedColor: Theme.of(context).colorScheme.primary.withAlpha(23),
          selectedTextColor: Theme.of(context).colorScheme.primary.withAlpha(230),
          unselectedTextColor: Theme.of(context).colorScheme.secondary,
          menuHeaderBuilder: (isExpanded) {
            return BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {

              },
              builder: (context, state) {


                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                  ],
                );
              },
            );
          },

        ),
      ),
    );
  }
}