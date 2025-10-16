import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isFilled;
  final bool isTextOnly;
  final IconData? icon; // 👈 optional icon
  final String? imagePath;
  final Color? fillColor;
  final double width;
  final double height;
  final Color strokeColor;
  final Color outlinedFillColor;
  final Color? textColor;
  final bool hasShadow;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFilled = true,
    this.isTextOnly = false,
    this.icon, // 👈 optional icon param
    this.imagePath,
    this.fillColor,
    this.width = 325,
    this.height = 50,
    this.strokeColor = Colors.transparent,
    this.outlinedFillColor = Colors.white,
    this.textColor,
    this.hasShadow = true,
    this.borderRadius = 50,
    this.fontSize = 18.0,
    this.fontWeight = FontWeight.bold,
  });

  static const Gradient _kGradient = LinearGradient(
    colors: [Color(0xFFB945AA), Color(0xFF8E4CB6), Color(0xFF5B53C2)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final double w = width;
    final double h = height;

    final BorderRadius actualOuterRadius = BorderRadius.circular(borderRadius);
    final BorderRadius actualInnerRadius = BorderRadius.circular(
      borderRadius > 2 ? borderRadius - 2 : 0,
    );

    final List<BoxShadow> buttonShadow = [
      BoxShadow(
        color: Colors.black.withAlpha(64),
        offset: const Offset(0, 2),
        blurRadius: 4,
      ),
    ];

    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      fontFamily: 'Nunito',
    );

    // 🟣 Text-only variant
    if (isTextOnly) {
      return GestureDetector(
        onTap: onPressed,
        child: Text(
          text,
          style: textStyle.copyWith(
            foreground: Paint()
              ..shader = _kGradient.createShader(Rect.fromLTWH(0, 0, w, h)),
          ),
        ),
      );
    }

    // 🟢 Filled gradient button (with optional icon)
    if (isFilled) {
      return SizedBox(
        width: w,
        height: h,
        child: Material(
          color: Colors.transparent,
          elevation: hasShadow ? 4 : 0,
          borderRadius: actualOuterRadius,
          child: Ink(
            decoration: BoxDecoration(
              color: fillColor,
              gradient: fillColor == null ? _kGradient : null,
              borderRadius: actualOuterRadius,
              boxShadow: hasShadow ? buttonShadow : null,
            ),
            child: InkWell(
              borderRadius: actualOuterRadius,
              onTap: onPressed,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (imagePath != null) ...[
                      SvgPicture.asset(imagePath!, height: 20, width: 20),
                      const SizedBox(width: 6),
                    ],
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: textColor ?? Colors.white,
                        size: fontSize + 2,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: textStyle.copyWith(
                        color: textColor,
                        foreground: textColor == null
                            ? (Paint()
                                ..shader = _kGradient.createShader(
                                  Rect.fromLTWH(0, 0, w, h),
                                ))
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 🟡 Outlined button
    return SizedBox(
      width: w,
      height: h,
      child: Material(
        color: Colors.transparent,
        elevation: hasShadow ? 4 : 0,
        borderRadius: actualOuterRadius,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: strokeColor != Colors.transparent ? strokeColor : null,
            gradient: strokeColor == Colors.transparent ? _kGradient : null,
            borderRadius: actualOuterRadius,
            boxShadow: hasShadow ? buttonShadow : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: outlinedFillColor,
              borderRadius: actualInnerRadius,
            ),
            child: InkWell(
              borderRadius: actualInnerRadius,
              onTap: onPressed,
              child: Center(
                child: Text(
                  text,
                  style: textStyle.copyWith(
                    color: textColor,
                    foreground: textColor == null
                        ? (Paint()
                            ..shader = _kGradient.createShader(
                              Rect.fromLTWH(0, 0, w, h),
                            ))
                        : null,
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
