import 'dart:ui' show AppExitResponse;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Services/repository.dart';
import 'package:zpharmacy/Services/api_services.dart';
import 'package:zpharmacy/Themes/Bloc/themes_bloc.dart';
import 'package:zpharmacy/Themes/Ui/theme.dart';
import 'package:zpharmacy/View/ForgotPassword/bloc/forgot_password_bloc.dart';
import 'package:zpharmacy/l10n/Bloc/localizations_bloc.dart';
import 'package:zpharmacy/l10n/app_localizations.dart';
import 'package:zpharmacy/View/Auth/auth.dart';
import 'package:zpharmacy/View/Auth/bloc/auth_bloc.dart';
import 'package:zpharmacy/View/Home/bloc/menu_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Dashboard/bloc/dashboard_stats_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Medicine/bloc/medicine_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Medicine/batch_bloc/batch_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Organization/bloc/organization_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Prescription/bloc/prescription_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Staff/bloc/staff_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Stock/bloc/stock_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Report/AntibioticReport/bloc/antibiotic_report_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Report/ExpiryNotify/bloc/expiry_notify_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Report/ExpiryAlertReport/bloc/expiry_alert_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Report/MedicineReport/bloc/medicine_report_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Report/StockCard/bloc/stock_card_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Report/TallySheet/bloc/tally_sheet_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Settings/bloc/settings_tab_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Settings/Ui/Backup/bloc/backup_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Settings/Ui/Category/bloc/category_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Settings/Ui/Users/bloc/users_bloc.dart';
import 'Services/config.dart';
import 'Services/server_manager.dart';
import 'Services/server_status.dart';
import 'View/ForgotPassword/SecurityQuestions/security_questions_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize shared services
  await ApiServices().init();

  // 2. Spawn the Node.js server process
 // await ServerService().start();

  // 3. Wait until it's actually reachable (up to 15s)
  //    We don't abort on failure — the ServerStatusCubit will show "down"
  //    and the Retry banner will let the user try again.
  //await ServerService().waitUntilReady();

  // 4. Launch the UI
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();

    // Fires when the user closes the app window (X button).
    // This is the *clean* shutdown path.
    // The Node server's --parent-pid watcher covers the force-kill path.
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        await ServerService().stop();
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => Repositories(ApiServices()),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ServerStatusCubit(AppConfig.apiBaseUrl)..startPolling(),
          ),

          BlocProvider(
          create: (ctx) => SecurityQuestionsBloc(
          ctx.read<Repositories>(),
          )..add(const SecurityQuestionsLoadRequested())),

          // ---- App-wide (no repo needed) ----
          BlocProvider(create: (_) => ThemeBloc()),
          BlocProvider(create: (_) => LocalizationBloc()),
          BlocProvider(create: (_) => MenuBloc()),
          BlocProvider(create: (_) => SettingsTabBloc()),

          // ---- Auth ----
          BlocProvider(
            create: (ctx) => AuthBloc(ctx.read<Repositories>())..add(const AuthCheckRequested()),
          ),


          BlocProvider(
            create: (ctx) => ForgotPasswordBloc(ctx.read<Repositories>()),
          ),
          // ---- Core domain ----
          BlocProvider(
            create: (ctx) => MedicineBloc(ctx.read<Repositories>()),
          ),
          BlocProvider(
            create: (ctx) => CategoryBloc(ctx.read<Repositories>()),
          ),
          BlocProvider(
            create: (ctx) => OrganizationBloc(ctx.read<Repositories>()),
          ),
          BlocProvider(
            create: (ctx) => PrescriptionBloc(ctx.read<Repositories>()),
          ),
          BlocProvider(
            create: (ctx) => StockBloc(ctx.read<Repositories>()),
          ),
          BlocProvider(
            create: (ctx) => BatchBloc(ctx.read<Repositories>()),
          ),
          BlocProvider(
            create: (ctx) => StaffBloc(ctx.read<Repositories>()),
          ),
          BlocProvider(
            create: (ctx) => UsersBloc(ctx.read<Repositories>()),
          ),
          BlocProvider(
            create: (ctx) => BackupBloc(ctx.read<Repositories>()),
          ),

          // ---- Reports ----
          BlocProvider(
            create: (ctx) => StockCardBloc(ctx.read<Repositories>()),
          ),
          BlocProvider(
            create: (ctx) => MedicineReportBloc(ctx.read<Repositories>()),
          ),
          BlocProvider(
            create: (ctx) => TallySheetBloc(ctx.read<Repositories>()),
          ),
          BlocProvider(
            create: (ctx) => AntibioticReportBloc(ctx.read<Repositories>()),
          ),
          BlocProvider(
            create: (ctx) => ExpiryAlertBloc(ctx.read<Repositories>()),
          ),

          // ---- Eager loaders ----
          BlocProvider(
            create: (ctx) =>
            ExpiryNotifyBloc(ctx.read<Repositories>())
              ..add(ExpiryNotifyLoadRequested()),
          ),
          BlocProvider(
            create: (ctx) =>
            DashboardStatsBloc(ctx.read<Repositories>())
              ..add(DashboardStatsLoadRequested()),
          ),
        ],
        child: BlocBuilder<LocalizationBloc, Locale>(
          builder: (context, locale) {
            return BlocBuilder<ThemeBloc, ThemeMode>(
              builder: (context, themeMode) {
                final theme = AppThemes(TextTheme.of(context));
                return MaterialApp(
                  themeMode: themeMode,
                  locale: locale,
                  title: 'zPharmacy',
                  darkTheme: theme.dark(),
                  theme: theme.light(),
                  debugShowCheckedModeBanner: false,
                  localizationsDelegates:
                  AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: const AuthView(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}