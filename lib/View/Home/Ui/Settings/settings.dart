import 'package:flutter/material.dart';

import '../../../../Themes/Ui/theme_selector.dart';
import '../../../../l10n/locale_selector.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        actionsPadding: const EdgeInsets.all(8),
        actions: [
          LocaleSelector(width: 150),
          const SizedBox(width: 8),
          ThemeSelector(width: 150),
        ],
      ),
      body: Text("Settings View"),
    );
  }
}
