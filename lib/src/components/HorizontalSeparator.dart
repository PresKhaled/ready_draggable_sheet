import 'package:flutter/material.dart';

class HorizontalSeparator extends StatelessWidget {
  final EdgeInsets padding;
  final double thickness;
  final Color? color;

  const HorizontalSeparator({
    super.key,
    this.padding = const EdgeInsets.symmetric(
      vertical: 5.0,
    ),
    this.thickness = 4.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: SizedBox(
          width: (MediaQuery.of(context).size.width / 6),
          height: thickness,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: (color ?? Theme.of(context).colorScheme.onSurfaceVariant),
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ),
    );
  }
}
