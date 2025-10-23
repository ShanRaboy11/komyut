import 'package:flutter/material.dart';

class BookingBottomSheet extends StatefulWidget {
  final int passengerCount;
  final Function(int) onPassengerCountChanged;
  final VoidCallback onProceed;

  const BookingBottomSheet({
    super.key,
    required this.passengerCount,
    required this.onPassengerCountChanged,
    required this.onProceed,
  });

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  double _sheetPosition = 0; // 0 = fully expanded, positive = moved down
  final double _maxDragDown = 400; // Maximum pixels to drag down
  final double _minHeight = 120; // Minimum visible height when collapsed

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _sheetPosition += details.delta.dy;
      if (_sheetPosition < 0) _sheetPosition = 0;
      if (_sheetPosition > _maxDragDown) _sheetPosition = _maxDragDown;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    // Snap to positions based on velocity or position
    final velocity = details.velocity.pixelsPerSecond.dy;
    
    if (velocity > 500) {
      // Fast swipe down - collapse
      setState(() => _sheetPosition = _maxDragDown);
    } else if (velocity < -500) {
      // Fast swipe up - expand
      setState(() => _sheetPosition = 0);
    } else {
      // Snap to nearest position
      if (_sheetPosition > _maxDragDown / 2) {
        setState(() => _sheetPosition = _maxDragDown);
      } else {
        setState(() => _sheetPosition = 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      bottom: -_sheetPosition,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DriverInfoCard(),
                    const SizedBox(height: 20),
                    const Text(
                      'How many are you?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PassengerCounter(
                      count: widget.passengerCount,
                      onChanged: widget.onPassengerCountChanged,
                    ),
                    const SizedBox(height: 24),
                    const TripDetailsSection(),
                    const SizedBox(height: 20),
                    const PaymentSection(),
                    const SizedBox(height: 20),
                    ProceedButton(onPressed: widget.onProceed),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverInfoCard extends StatelessWidget {
  const DriverInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: const Icon(Icons.person, size: 30, color: Colors.grey),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver 1',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                SizedBox(width: 4),
                Text(
                  '4.9',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class PassengerCounter extends StatelessWidget {
  final int count;
  final Function(int) onChanged;

  const PassengerCounter({
    super.key,
    required this.count,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: count > 1 ? () => onChanged(count - 1) : null,
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.remove, size: 20),
          ),
        ),
        const SizedBox(width: 40),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 40),
        IconButton(
          onPressed: count < 4 ? () => onChanged(count + 1) : null,
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, size: 20),
          ),
        ),
      ],
    );
  }
}

class TripDetailsSection extends StatelessWidget {
  const TripDetailsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trip Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 2,
                  height: 30,
                  color: Colors.grey[300],
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SM Cebu',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  'Colon',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class PaymentSection extends StatelessWidget {
  const PaymentSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, 
                     color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'My Wallet',
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF8E4CB6), // Light (top)
                  Color(0xFFB945AA), // Dark (bottom)
                ],
              ).createShader(bounds),
              child: const Text(
                'PHP 500.00',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Payment Detail',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Base Fare', style: TextStyle(fontSize: 14)),
            Text(
              'PHP 13.00',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF8E4CB6).withAlpha(153), // Corrected: withAlpha instead of withOpacity
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', 
                 style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(
              'PHP 23.00',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8E4CB6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ProceedButton extends StatefulWidget {
  final VoidCallback onPressed;

  const ProceedButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<ProceedButton> createState() => _ProceedButtonState();
}

class _ProceedButtonState extends State<ProceedButton> {
  double _dragPosition = 0;
  bool _isDragging = false;
  final double _buttonWidth = 70;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragPosition += details.delta.dx;
      if (_dragPosition < 0) _dragPosition = 0;
      
      // Get max width (container width - button width)
      final maxDrag = MediaQuery.of(context).size.width - 40 - _buttonWidth;
      if (_dragPosition > maxDrag) _dragPosition = maxDrag;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final maxDrag = MediaQuery.of(context).size.width - 40 - _buttonWidth;
    
    // If dragged more than 80% of the way, trigger action
    if (_dragPosition > maxDrag * 0.8) {
      widget.onPressed();
      // Reset after a delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _dragPosition = 0;
            _isDragging = false;
          });
        }
      });
    } else {
      // Animate back to start
      setState(() {
        _dragPosition = 0;
        _isDragging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFB945AA), // Dark (left)
            Color(0xFF8E4CB6), // Light (right)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Text in center
          Center(
            child: Text(
              'Swipe to Proceed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(_isDragging ? 0.5 : 1.0),
              ),
            ),
          ),
          // Draggable button
          AnimatedPositioned(
            duration: _isDragging 
                ? Duration.zero 
                : const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            left: _dragPosition + 4,
            top: 4,
            bottom: 4,
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: Container(
                width: _buttonWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFF8E4CB6),
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}