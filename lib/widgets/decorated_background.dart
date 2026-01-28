import 'package:flutter/material.dart';

class DecoratedBackground extends StatelessWidget {
  const DecoratedBackground({
    super.key,
    required this.child,
    required this.gradientColors,
    this.accents = const <Widget>[],
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final List<Color> gradientColors;
  final List<Widget> accents;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final hasGradient = gradientColors.length > 1;
    return Container(
      decoration: BoxDecoration(
        color: hasGradient ? null : gradientColors.first,
        gradient: hasGradient
            ? LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Stack(
        children: <Widget>[
          ...accents,
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}
