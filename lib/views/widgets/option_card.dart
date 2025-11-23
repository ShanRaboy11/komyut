// lib/widgets/option_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Enum to define different selection types
enum OptionCardType { radio, checkbox, simple }

class OptionCard extends StatelessWidget {
  final String title;
  final String? subtitle; // Optional subtitle
  final bool isSelected;
  final VoidCallback onTap;
  final OptionCardType type;
  final Color selectedColor; // New: for custom selected border/indicator color
  final Color unselectedColor; // New: for custom unselected border color
  final Widget? leadingIcon; // New: for an optional icon at the start
  final Widget?
  trailingWidget; // New: for custom widget at the end (overrides default type indicator)
  final double? width; // New: Customizable width
  final double height; // New: Customizable height, now required
  final double borderRadius; // New: Customizable border radius
  final EdgeInsetsGeometry? margin; // New: Customizable margin
  final double textSize; // Fixed text size for title

  const OptionCard({
    super.key, // Use super.key
    required this.title,
    this.subtitle,
    this.isSelected = false,
    required this.onTap,
    this.type = OptionCardType.simple, // Default to a simple tappable card
    this.selectedColor = const Color.fromRGBO(
      185,
      69,
      170,
      1,
    ), // Default purple
    this.unselectedColor = const Color.fromRGBO(
      200,
      200,
      200,
      1,
    ), // Default grey
    this.leadingIcon,
    this.trailingWidget,
    this.width, // Defaults to double.infinity if null in Container
    this.height = 70, // Default height, but now customizable
    this.borderRadius = 15, // Default border radius
    this.margin = const EdgeInsets.symmetric(
      horizontal: 25,
      vertical: 8,
    ), // Default margin
    this.textSize = 16, // Default text size
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? double.infinity, // Use provided width or full width
        height: height, // Use provided height
        margin: margin, // Use provided margin
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            borderRadius,
          ), // Use provided border radius
          border: Border.all(
            color: isSelected ? selectedColor : unselectedColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (leadingIcon != null) ...[
                leadingIcon!,
                const SizedBox(width: 15),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        // Changed: Active text color now matches selectedColor
                        color: isSelected ? selectedColor : Colors.grey[700],
                        fontSize: textSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.grey[600]
                              : Colors.grey[500],
                          fontFamily: 'Manrope',
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailingWidget != null)
                trailingWidget!
              else
                _buildDefaultTrailingWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultTrailingWidget() {
    switch (type) {
      case OptionCardType.radio:
        // Custom radio button visual indicator (no deprecated parameters)
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? selectedColor : unselectedColor,
              width: 2,
            ),
          ),
          child: isSelected
              ? Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selectedColor,
                    ),
                  ),
                )
              : null,
        );
      case OptionCardType.checkbox:
        return Checkbox(
          value: isSelected,
          onChanged: (bool? value) => onTap(),
          activeColor: selectedColor,
        );
      case OptionCardType.simple:
        return Icon(
          Icons.chevron_right,
          color: isSelected ? selectedColor : unselectedColor,
        );
    }
  }
}
