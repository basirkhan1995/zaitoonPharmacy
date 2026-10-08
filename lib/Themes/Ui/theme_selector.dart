import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../Bloc/themes_bloc.dart';

class ThemeSelector extends StatefulWidget {
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final String title;

  const ThemeSelector({
    super.key,
    this.padding,
    this.margin,
    this.radius = 4,
    this.width,
    this.title = "",
  });

  @override
  State<ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<ThemeSelector> {
  bool _isOpen = false;
  late OverlayEntry _overlayEntry;
  final GlobalKey _buttonKey = GlobalKey(); // Key for the button
  final FocusNode _focusNode = FocusNode();

  // Define available theme modes (without hardcoded names)
  final List<Map<String, dynamic>> _themeModes = [
    {'mode': 'system', 'icon': Icons.settings},
    {'mode': 'light', 'icon': Icons.light_mode},
    {'mode': 'dark', 'icon': Icons.dark_mode},
  ];

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.read<ThemeBloc>();
    final currentTheme = themeCubit.state; // Get current theme mode
    final color = Theme.of(context).colorScheme;
    return Focus(
      focusNode: _focusNode,
      onFocusChange: (hasFocus) {
        if (!hasFocus && _isOpen) {
          _overlayEntry.remove();
          setState(() {
            _isOpen = false;
          });
        }
      },
      child: GestureDetector(
        onTap: () {
          if (_isOpen) {
            _overlayEntry.remove();
          } else {
            _overlayEntry = _createOverlayEntry(context);
            Overlay.of(context).insert(_overlayEntry);
          }
          setState(() {
            _isOpen = !_isOpen;
            if (_isOpen) {
              _focusNode.requestFocus();
            } else {
              _focusNode.unfocus();
            }
          });
        },
        child: Container(
          key: _buttonKey,
          width: widget.width ?? double.infinity,
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 0),
          margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 0),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.title.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(),
              // Main Dropdown Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                decoration: BoxDecoration(
                  color: color.surface,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: color.outline.withValues(alpha: .3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: Text(
                        _themeModes.firstWhere(
                                  (theme) =>
                                      theme['mode'] ==
                                      currentTheme.name.toLowerCase(),
                                  orElse: () => _themeModes[0],
                                )['mode'] ==
                                'system'
                            ? AppLocalizations.of(context)!.systemMode
                            : _themeModes.firstWhere(
                                    (theme) =>
                                        theme['mode'] ==
                                        currentTheme.name.toLowerCase(),
                                  )['mode'] ==
                                  'light'
                            ? AppLocalizations.of(context)!.lightMode
                            : AppLocalizations.of(context)!.darkMode,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Icon(
                      _isOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Theme.of(context).colorScheme.outline,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Creates the overlay entry
  OverlayEntry _createOverlayEntry(BuildContext context) {
    final themeBloc = context.read<ThemeBloc>();
    final selectedTheme = themeBloc.state.name
        .toLowerCase(); // Get the selected theme name

    // Get the position and size of the button using the global key
    RenderBox renderBox =
        _buttonKey.currentContext!.findRenderObject() as RenderBox;
    Offset offset = renderBox.localToGlobal(Offset.zero);
    double buttonWidth = renderBox.size.width; // Get width of the button
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // A GestureDetector as a barrier to detect taps outside the dropdown
          GestureDetector(
            onTap: () {
              _overlayEntry.remove();
              setState(() {
                _isOpen = false;
              });
            },
            child: Container(
              color: Colors.transparent, // Makes it transparent and tappable
            ),
          ),
          Positioned(
            left: offset.dx, // Align it exactly with the button's left edge
            top: offset.dy + renderBox.size.height + 8, // Position below button
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: buttonWidth, // Match the button's width
                padding: EdgeInsets.zero,
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: _themeModes.map((theme) {
                    bool isSelected =
                        theme['mode'] ==
                        selectedTheme; // Check if this is the selected theme

                    return GestureDetector(
                      onTap: () {
                        themeBloc.add(
                          ChangeThemeEvent(theme['mode']),
                        ); // Change theme
                        _overlayEntry.remove();
                        setState(() {
                          _isOpen = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                                    .withValues(alpha: .3)
                              : Theme.of(context)
                                    .colorScheme
                                    .surface, // Transparent for unselected themes
                        ),
                        child: Row(
                          children: [
                            Icon(
                              theme['icon'],
                              size: 18,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              theme['mode'] == 'system'
                                  ? AppLocalizations.of(context)!.systemMode
                                  : theme['mode'] == 'light'
                                  ? AppLocalizations.of(context)!.lightMode
                                  : AppLocalizations.of(context)!.darkMode,
                              style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurface, // Change text color based on selection
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
