// lib/widgets/custom_dropdown_field.dart
import 'package:flutter/material.dart';

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
    this.borderRadius = 15.0,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    this.hintText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox( // Use SizedBox to add whitespace and apply width/height
      width: width,
      height: height,
      child: DropdownButtonFormField<T>(
        value: initialValue, // Use initialValue here
        items: items,
        onChanged: onChanged,
        validator: validator,
        style: TextStyle(
          color: textColor ?? Colors.black,
          fontSize: 16,
          fontFamily: 'Manrope',
        ),
        icon: icon ?? const Icon(Icons.keyboard_arrow_down, color: Colors.grey), // Customizable icon
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          hintStyle: TextStyle(
            color: hintColor ?? Colors.grey[400],
            fontSize: 16,
            fontFamily: 'Manrope',
          ),
          labelStyle: TextStyle(
            color: labelColor ?? Colors.grey[600],
            fontSize: 16,
            fontFamily: 'Manrope',
          ),
          filled: fillColor != null,
          fillColor: fillColor,
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
              color: focusedBorderColor ?? const Color.fromRGBO(185, 69, 170, 1),
              width: 2,
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