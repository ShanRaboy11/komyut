// lib/widgets/custom_text_field.dart
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool enabled;
  final double? width;
  final double? height;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? textColor;
  final Color? labelColor;
  final Color? hintColor;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;

  const CustomTextField({
    Key? key,
    required this.labelText,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
    this.width,
    this.height,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.textColor,
    this.labelColor,
    this.hintColor,
    this.borderRadius = 15.0, // Default border radius
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Default padding
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, // Use provided width
      height: height, // Use provided height (might be overridden by TextField internal sizing if too small)
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        enabled: enabled,
        style: TextStyle(
          color: textColor ?? Colors.black, // Customizable text color
          fontSize: 16,
          fontFamily: 'Manrope', // Assuming Manrope for inputs
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          hintStyle: TextStyle(
            color: hintColor ?? Colors.grey[400], // Customizable hint color
            fontSize: 16,
            fontFamily: 'Manrope',
          ),
          labelStyle: TextStyle(
            color: labelColor ?? Colors.grey[600], // Customizable label color
            fontSize: 16,
            fontFamily: 'Manrope',
          ),
          filled: fillColor != null,
          fillColor: fillColor,
          suffixIcon: suffixIcon,
          prefixIcon: prefixIcon,
          contentPadding: contentPadding, // Customizable content padding
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius), // Customizable border radius
            borderSide: BorderSide(
              color: borderColor ?? const Color.fromRGBO(200, 200, 200, 1), // Customizable border color
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: borderColor ?? const Color.fromRGBO(200, 200, 200, 1),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: focusedBorderColor ?? const Color.fromRGBO(185, 69, 170, 1), // Customizable focused border color
              width: 2, // Thicker focused border for emphasis
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}