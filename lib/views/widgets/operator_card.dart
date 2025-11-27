import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'button.dart';

class OperatorCard extends StatefulWidget {
  final String operatorName;
  final String activeDrivers;
  final String routeStart;
  final String routeEnd;
  final String routeCode;
  final VoidCallback onApply;

  const OperatorCard({
    super.key,
    required this.operatorName,
    required this.activeDrivers,
    required this.routeStart,
    required this.routeEnd,
    required this.routeCode,
    required this.onApply,
  });

  @override
  State<OperatorCard> createState() => _OperatorCardState();
}

class _OperatorCardState extends State<OperatorCard> {
  bool _isApplied = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.operatorName,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                "${widget.activeDrivers} Active Drivers",
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(height: 24),
          const SizedBox(height: 10),

          // Route Row
          Row(
            children: [
              const Icon(Symbols.route, color: Color(0xFF8E4CB6), size: 28),
              const SizedBox(width: 13),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.routeStart,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Symbols.arrow_forward,
                        color: Colors.black,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.routeEnd,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "Route ${widget.routeCode}",
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Apply Button
          CustomButton(
            text: _isApplied ? "Applied" : "Apply",
            onPressed: _isApplied
                ? () {}
                : () {
                    setState(() {
                      _isApplied = true;
                    });
                    widget.onApply();
                  },
            height: 42,
            isFilled: false,
            outlinedFillColor: _isApplied ? Colors.grey[300]! : Colors.white,
            textColor: _isApplied ? Colors.grey : const Color(0xFF5B53C2),
            hasShadow: false,
            fontSize: 15,
          ),
        ],
      ),
    );
  }
}
