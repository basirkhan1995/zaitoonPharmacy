import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Services/repository.dart';
import 'package:zpharmacy/View/Auth/auth.dart';
import 'package:zpharmacy/View/Auth/bloc/auth_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Medicine/batch_bloc/batch_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Organization/bloc/organization_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Prescription/bloc/prescription_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Report/AntibioticReport/bloc/antibiotic_report_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Report/StockCard/bloc/stock_card_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Report/TallySheet/bloc/tally_sheet_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Settings/Ui/Category/bloc/category_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Stock/bloc/stock_bloc.dart';
import 'package:zpharmacy/View/Home/bloc/menu_bloc.dart';
import 'package:zpharmacy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'Services/api_services.dart';
import 'Themes/Bloc/themes_bloc.dart';
import 'Themes/Ui/theme.dart';
import 'View/Home/Ui/Medicine/bloc/medicine_bloc.dart';
import 'View/Home/Ui/Report/MedicineReport/bloc/medicine_report_bloc.dart';
import 'l10n/Bloc/localizations_bloc.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await ApiServices().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeBloc()),
        BlocProvider(create: (context) => LocalizationBloc()),
        BlocProvider(create: (context) => MenuBloc()),
        BlocProvider(create: (context) => AuthBloc(Repositories(ApiServices()))..add(const AuthCheckRequested()),),
        BlocProvider(create: (context) => MedicineBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => CategoryBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => OrganizationBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => PrescriptionBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => StockBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => BatchBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => StockCardBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => MedicineReportBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => TallySheetBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => AntibioticReportBloc(Repositories(ApiServices()))),
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
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const AuthView(),
              );
            },
          );
        },
      ),
    );
  }
}


