import 'package:flutter/material.dart';

class FocusOutline extends StatefulWidget {
  const FocusOutline({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding = const EdgeInsets.all(2),
    this.focusThickness = 3.0,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsets padding;
  final double focusThickness;

  @override
  State<FocusOutline> createState() => _FocusOutlineState();
}

class _FocusOutlineState extends State<FocusOutline> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = _focused
        ? theme.colorScheme.onSurface
        : (_hovered ? theme.colorScheme.outline : Colors.transparent);

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        padding: widget.padding,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: _focused ? widget.focusThickness : 1,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
