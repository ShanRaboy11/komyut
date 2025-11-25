import 'package:flutter/material.dart';

class BigCard extends StatelessWidget {
  // It now takes a child widget
  final Widget child;
  // You might also want to customize its height if it's generic
  final double? height; // Make height optional

  const BigCard({
    super.key,
    required this.child, // The content to place inside the card
    this.height, // Optional height
  });

  static const Gradient _cardGradient = LinearGradient(
    colors: [
      Color(0xFFB945AA),
      Color(0xFF8E4CB6),
      Color(0xFF5B53C2),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    // You might still use screen height for default/relative sizing if height is null
    final Size screenSize = MediaQuery.of(context).size;
    final double actualHeight = height ?? screenSize.height * 0.65; // Default if not provided

    return Container(
      height: actualHeight, // Use the provided or default height
      width: double.infinity, // Always full width
      decoration: const BoxDecoration(
        gradient: _cardGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
      ),
      // The child is now directly placed here
      child: child,
    );
  }
}