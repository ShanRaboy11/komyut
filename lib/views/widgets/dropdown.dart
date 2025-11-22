// lib/widgets/custom_dropdown_field.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomDropdownField<T> extends StatelessWidget {
  final String labelText;
  final T? initialValue; // Changed from 'value' to 'initialValue'
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
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
  final String? hintText;
  final Widget? icon; // Customizable dropdown icon

  const CustomDropdownField({
    super.key, // Use super.key
    required this.labelText,
    this.initialValue, // Use initialValue
    required this.items,
    required this.onChanged,
    this.validator,
    this.width,
    this.height,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.textColor,
    this.labelColor,
    this.hintColor,
    this.borderRadius = 10.0,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 5,
      vertical: 10,
    ),
    this.hintText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Use SizedBox to add whitespace and apply width/height
      width: width == 0 ? null : width,
      height: height,
      child: DropdownButtonFormField<T>(
        isExpanded: true,
        initialValue: initialValue,
        items: items,
        onChanged: onChanged,
        validator: validator,
        style: GoogleFonts.manrope(
          color: textColor ?? Colors.black,
          fontSize: 12,
        ),
        icon:
            icon ??
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey,
            ), // Customizable icon
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          hintStyle: GoogleFonts.manrope(
            color: hintColor ?? Colors.grey[400],
            fontSize: 12,
          ),
          labelStyle: GoogleFonts.manrope(
            color: labelColor ?? Colors.grey[600],
            fontSize: 13,
          ),
          filled: fillColor != null,
          fillColor: fillColor,
          errorStyle: const TextStyle(height: 0, fontSize: 0),
          contentPadding: contentPadding,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: borderColor ?? const Color.fromRGBO(200, 200, 200, 1),
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
              color:
                  focusedBorderColor ?? const Color.fromRGBO(185, 69, 170, 1),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
    );
  }
}
