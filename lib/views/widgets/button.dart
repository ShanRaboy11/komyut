import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isFilled;
  final Color? fillColor;
  final double width;
  final double height;
  final Color strokeColor;
  final Color outlinedFillColor;
  final Color? textColor;
  final bool hasShadow;
  final double borderRadius; 

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFilled = true,
    this.fillColor,
    this.width = 325,
    this.height = 50,
    this.strokeColor = Colors.transparent,
    this.outlinedFillColor = Colors.white,
    this.textColor,
    this.hasShadow = true,
    this.borderRadius = 50, 
  });

  static const Gradient _kGradient = LinearGradient(
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
    final double w = width;
    final double h = height;

    final BorderRadius actualOuterRadius = BorderRadius.circular(borderRadius);
    final BorderRadius actualInnerRadius = BorderRadius.circular(borderRadius > 2 ? borderRadius - 2 : 0);


    final List<BoxShadow> buttonShadow = [
      BoxShadow(
        color: Colors.black.withAlpha(64),
        offset: const Offset(0, 2),
        blurRadius: 4,
      ),
    ];

    TextStyle textStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      fontFamily: 'Nunito',
    );

    // Filled gradient button
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
                child: Text(
                  text,
                  style: textStyle.copyWith(
                    foreground: textColor == null
                        ? (Paint()
                          ..shader = _kGradient.createShader(
                            Rect.fromLTWH(0, 0, w, h),
                          ))
                        : null,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Outlined button
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
                    foreground: textColor == null
                        ? (Paint()
                          ..shader = _kGradient.createShader(
                            Rect.fromLTWH(0, 0, w, h),
                          ))
                        : null,
                    color: textColor,
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