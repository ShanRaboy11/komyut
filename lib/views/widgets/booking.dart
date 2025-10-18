import 'package:flutter/material.dart';

class BookingBottomSheet extends StatelessWidget {
  final int passengerCount;
  final Function(int) onPassengerCountChanged;
  final VoidCallback onProceed;

  const BookingBottomSheet({
    Key? key,
    required this.passengerCount,
    required this.onPassengerCountChanged,
    required this.onProceed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            count: passengerCount,
            onChanged: onPassengerCountChanged,
          ),
          const SizedBox(height: 24),
          const TripDetailsSection(),
          const SizedBox(height: 20),
          const PaymentSection(),
          const SizedBox(height: 20),
          ProceedButton(onPressed: onProceed),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class DriverInfoCard extends StatelessWidget {
  const DriverInfoCard({Key? key}) : super(key: key);

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
    Key? key,
    required this.count,
    required this.onChanged,
  }) : super(key: key);

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
  const TripDetailsSection({Key? key}) : super(key: key);

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
  const PaymentSection({Key? key}) : super(key: key);

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
                color: const Color(0xFF8E4CB6).withOpacity(0.6),
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

class ProceedButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ProceedButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

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
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.credit_card, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Swipe to Proceed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}