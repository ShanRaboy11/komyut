import 'package:flutter/material.dart';
import 'dart:math';

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double shakeCount;
  final double shakeOffset;

  const ShakeWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.shakeCount = 4,
    this.shakeOffset = 8.0,
  });

  @override
  // The ShakeWidgetState is made public to access the shake() method.
  ShakeWidgetState createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticIn));
  }

  // Public method to trigger the animation
  void shake() {
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final sineValue = sin(widget.shakeCount * 2 * pi * _animation.value);
        return Transform.translate(
          offset: Offset(sineValue * widget.shakeOffset, 0),
          child: child,
        );
      },
    );
  }
}
