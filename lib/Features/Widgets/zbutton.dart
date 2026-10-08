import 'package:flutter/material.dart';

class ZOutlineButton extends StatefulWidget {
  final Widget? label;
  final VoidCallback? onPressed;
  final double? height;
  final double? width;
  final String toolTip;
  final Color? backgroundColor;
  final Color? backgroundHover;
  final Color? foregroundHover;
  final Color? textColor;
  final IconData? icon;
  final double? iconSize;
  final bool isActive;
  final bool disable;

  const ZOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundHover,
    this.foregroundHover,
    this.textColor,
    this.toolTip = '',
    this.disable = false,
    this.iconSize,
    this.width,
    this.icon,
    this.backgroundColor,
    this.height,
    this.isActive = false,
  });

  @override
  State<ZOutlineButton> createState() => ZOutlineButtonState();
}

class ZOutlineButtonState extends State<ZOutlineButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = widget.isActive
        ? widget.backgroundHover ?? theme.colorScheme.primary
        : (_isHovered
        ? widget.backgroundHover ?? theme.colorScheme.primary
        : widget.backgroundColor ?? theme.colorScheme.surface);

    final borderColor = widget.isActive
        ? bgColor
        : (_isHovered
        ? widget.backgroundHover ?? theme.colorScheme.primary
        : Colors.grey.withValues(alpha: .5));

    final disabledBorder = theme.colorScheme.error;

    final textColor = widget.isActive
        ? widget.foregroundHover ?? theme.colorScheme.onPrimary
        : (_isHovered
        ? widget.foregroundHover ?? theme.colorScheme.onPrimary
        : widget.textColor ??
        theme.colorScheme.primary.withValues(alpha: .9));

    Widget button = OutlinedButton(
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12),
        ),
        minimumSize: WidgetStateProperty.all(
          Size(0, widget.height ?? 40),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        ),
        backgroundColor: WidgetStateProperty.all(bgColor),
        side: WidgetStateProperty.all(
          BorderSide(color: widget.disable ? disabledBorder : borderColor),
        ),
      ),
      onPressed: widget.disable ? null : widget.onPressed,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null)
              Icon(widget.icon, color: textColor, size: widget.iconSize),
            if (widget.icon != null && widget.label !=null) const SizedBox(width: 5),
            DefaultTextStyle.merge(
              style: TextStyle(color: textColor),
              child: widget.label ?? SizedBox(),
            ),
          ],
        ),
      ),
    );

    // Apply fixed width ONLY if provided
    if (widget.width != null) {
      button = SizedBox(
        width: widget.width,
        height: widget.height ?? 40,
        child: button,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.toolTip,
        child: button,
      ),
    );
  }
}
