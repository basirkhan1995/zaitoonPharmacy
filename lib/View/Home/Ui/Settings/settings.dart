import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/View/Auth/bloc/auth_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Settings/Ui/Backup/backup.dart';
import 'package:zpharmacy/View/Home/Ui/Settings/Ui/Category/categories.dart';
import 'package:zpharmacy/View/Home/Ui/Settings/Ui/System/system.dart';
import 'package:zpharmacy/View/Home/Ui/Settings/Ui/Users/users.dart';
import 'package:zpharmacy/View/Home/Ui/Settings/bloc/settings_tab_bloc.dart';
import '../../../../Features/Widgets/tab_bar.dart';
import '../../../../l10n/app_localizations.dart';
import 'Ui/About/about.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Who is logged in?
    final authState = context.select((AuthBloc b) => b.state);
    final isAdmin = authState is AuthAuthenticated &&
        authState.user.role.toUpperCase() == 'ADMIN';

    final tabs = <ZTabItem<SettingsTabName>>[
      ZTabItem(
        value: SettingsTabName.system,
        label: "System",
        screen: const SysetmView(),
      ),

      // Users tab — visible to admins only
      if (isAdmin)
        ZTabItem(
          value: SettingsTabName.users,
          label: "Users",
          screen: const UsersView(),
        ),

      ZTabItem(
        value: SettingsTabName.category,
        label: "Category",
        screen: const CategoriesView(),
      ),
      ZTabItem(
        value: SettingsTabName.backup,
        label: "Backup",
        screen: const BackupView(),
      ),
      ZTabItem(
        value: SettingsTabName.about,
        label: "About",
        screen: const AboutView(),
      ),
    ];

    return BlocBuilder<SettingsTabBloc, SettingsTabState>(
      builder: (context, blocState) {
        final availableValues = tabs.map((tab) => tab.value).toList();

        // If the currently-selected tab is hidden (e.g. an admin logged out
        // and a non-admin logged in), fall back to the first available tab.
        final selected = availableValues.contains(blocState.tabs)
            ? blocState.tabs
            : availableValues.first;

        return ZTabContainer<SettingsTabName>(
          tabs: tabs,
          selectedValue: selected,
          onChanged: (val) =>
              context.read<SettingsTabBloc>().add(SettingsOnChangeEvent(val)),
          title: AppLocalizations.of(context)!.settings,
          description: "Manage your settings",
          style: ZTabStyle.rounded,
          tabBarPadding:
          const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          borderRadius: 0,
          selectedColor: Theme.of(context).colorScheme.primary,
          unselectedTextColor: Theme.of(context).colorScheme.secondary,
          selectedTextColor: Theme.of(context).colorScheme.surface,
        );
      },
    );
  }
}