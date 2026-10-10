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
  @override
  Widget build(BuildContext context) {
    final authState = context.select((AuthBloc bloc) => bloc.state);
    if (authState is! AuthAuthenticated) {
      return const SizedBox();
    }

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
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
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
          menuHeaderBuilder: (isExpanded) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}