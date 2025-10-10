import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isFilled;
  final double width;
  final double height;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isFilled = true,
    this.width = 250,
    this.height = 50,
  }) : super(key: key);

  static const Gradient _kGradient = LinearGradient(
    colors: [
      Color(0xFFB945AA), // B945AA
      Color(0xFF8E4CB6), // 8E4CB6
      Color(0xFF5B53C2), // 5B53C2
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final double w = width;
    final double h = height;
    final BorderRadius outerRadius = BorderRadius.circular(50);
    final BorderRadius innerRadius = BorderRadius.circular(48);

    // Filled gradient button
    if (isFilled) {
      return SizedBox(
        width: w,
        height: h,
        child: Material(
          color: Colors.transparent,
          elevation: 4,
          borderRadius: outerRadius,
          child: Ink(
            decoration: BoxDecoration(
              gradient: _kGradient,
              borderRadius: outerRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: InkWell(
              borderRadius: outerRadius,
              onTap: onPressed,
              child: Center(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Outlined button with gradient stroke
    // We make an outer container with the gradient and a small inner white container
    // to simulate a stroked button.
    return SizedBox(
      width: w,
      height: h,
      child: Material(
        color: Colors.transparent,
        elevation: 4,
        borderRadius: outerRadius,
        child: Container(
          padding: const EdgeInsets.all(2), // stroke thickness
          decoration: BoxDecoration(
            gradient: _kGradient,
            borderRadius: outerRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: innerRadius,
            ),
            child: InkWell(
              borderRadius: innerRadius,
              onTap: onPressed,
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    // gradient text paint: maps same gradient to the text
                    foreground: Paint()
                      ..shader = _kGradient.createShader(
                        Rect.fromLTWH(0, 0, w, h),
                      ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
