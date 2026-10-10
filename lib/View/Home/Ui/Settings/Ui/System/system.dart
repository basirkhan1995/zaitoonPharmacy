import 'package:flutter/material.dart';
import 'package:zpharmacy/View/Home/Ui/Settings/Ui/System/theme_toggle.dart';
import 'package:zpharmacy/l10n/locale_selector.dart';


class SysetmView extends StatelessWidget {
  const SysetmView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  // Force segmented Android style
                  ThemeSelectorWidget(
                    width: 330,
                    title: "Theme",
                    style: ThemeSelectorStyle.toggle,
                    usePlatformDefault: false,
                  ),

                  LocaleSelector(
                    width: 330,
                    title: "Language",
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
