import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zpharmacy/Features/Widgets/zbutton.dart';
import '../../l10n/app_localizations.dart';

class ZFormDialog extends StatefulWidget {
  final VoidCallback? onAction;
  final Widget? actionLabel;
  final String title;
  final Color? backgroundColor;
  final IconData? icon;
  final Widget? child;
  final bool isButtonEnabled;
  final bool isActionTrue;
  final double? width;
  final double? height;
  final Widget? expandedAction;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Widget? expandedHeader;

  const ZFormDialog({
    super.key,
    required this.onAction,
    this.backgroundColor,
    this.actionLabel,
    this.child,
    this.alignment,
    this.isButtonEnabled = true,
    this.expandedAction,
    this.isActionTrue = true,
    this.width,
    this.height,
    this.icon,
    required this.title,
    this.margin,
    this.expandedHeader,
    this.padding,
  });

  @override
  State<ZFormDialog> createState() => _ZFormDialogState();
}

class _ZFormDialogState extends State<ZFormDialog> {
  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: widget.padding ?? const EdgeInsets.all(5.0),
          child: AlertDialog(
            alignment: widget.alignment ?? AlignmentGeometry.center,
            contentPadding: EdgeInsets.zero,
            insetPadding: EdgeInsets.zero,
            titlePadding: EdgeInsets.zero,
            actionsPadding: EdgeInsets.zero,
            content: Shortcuts(
              shortcuts: {
                LogicalKeySet(LogicalKeyboardKey.f4):
                const ActivateIntent(),
              },
              child: Actions(
                actions: {
                  ActivateIntent: CallbackAction<ActivateIntent>(
                    onInvoke: (intent) {
                      if (widget.isButtonEnabled && widget.onAction != null) {
                        widget.onAction!();
                      }
                      return null;
                    },
                  ),
                },
                child: Focus(
                  autofocus: true,
                  child: Container(
                    margin: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
                    width:
                    widget.width ?? MediaQuery.sizeOf(context).width * .4,
                    decoration: BoxDecoration(
                      color: widget.backgroundColor ??
                          Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildHeader(),
                        Flexible(
                          child: Container(
                            padding: widget.padding ??
                                const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 5),
                            child: widget.child,
                          ),
                        ),
                        if (widget.isActionTrue) buildAction(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildAction(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return Padding(
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            spacing: 8,
            children: [
              ZOutlineButton(
                label: Text(tr.cancel),
                backgroundHover: Theme.of(context).colorScheme.error,
                onPressed: () => Navigator.of(context).pop(),
                height: 35,
                width: 100,
              ),
              ZOutlineButton(
                disable: !widget.isButtonEnabled,
                isActive: true,
                height: 35,
                width: 100,
                label: widget.actionLabel ?? Text(tr.save),
                onPressed: widget.onAction,
              ),
            ],
          ),
          Row(
            children: [widget.expandedAction ?? const Text("")],
          ),
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      height: 50,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5.0, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      widget.icon != null
                          ? Icon(
                        widget.icon,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 24,
                      )
                          : const SizedBox(),
                      widget.icon != null
                          ? const SizedBox(width: 8)
                          : const SizedBox(),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 17,
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: widget.expandedHeader ??
                        const Icon(Icons.close, size: 23),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}