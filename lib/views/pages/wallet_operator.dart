// lib/screens/operator_wallet_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../widgets/button.dart'; // Make sure this path is correct

class OperatorWalletPage extends StatelessWidget {
  const OperatorWalletPage({super.key});

  // Dummy data for the transaction list
  final List<Map<String, dynamic>> _transactions = const [
    {
      'type': 'remittance',
      'description': 'Remittance from John Doe',
      'amount': 750.00,
      'date': '2023-10-27T10:00:00Z',
    },
    {
      'type': 'cash-out',
      'description': 'Cash Out to BPI Account',
      'amount': -5000.00,
      'date': '2023-10-26T15:30:00Z',
    },
    {
      'type': 'remittance',
      'description': 'Remittance from Jane Smith',
      'amount': 920.50,
      'date': '2023-10-26T09:15:00Z',
    },
    {
      'type': 'cash-in',
      'description': 'Manual Top-up',
      'amount': 10000.00,
      'date': '2023-10-25T11:00:00Z',
    },
    {
      'type': 'remittance',
      'description': 'Remittance from Mike Ross',
      'amount': 680.00,
      'date': '2023-10-25T08:45:00Z',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Wallet',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              // --- Balance Card ---
              _buildBalanceCard(),
              const SizedBox(height: 24),

              // --- Cash Out Button ---
              CustomButton(
                text: 'Cash Out',
                onPressed: () {
                  // TODO: Implement cash out logic
                },
                isFilled: true,
                fillColor: const Color(0xFF5B53C2),
                textColor: Colors.white,
                height: 50,
                fontSize: 16,
                hasShadow: true,
              ),
              const SizedBox(height: 32),

              // --- Recent Transactions ---
              Text(
                'Recent Transactions',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _transactions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildTransactionTile(_transactions[index]);
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B53C2).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Balance',
            style: GoogleFonts.nunito(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₱ 15,450.75', // Dummy balance
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> transaction) {
    final bool isCredit = transaction['amount'] > 0;
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱ ');
    final amount = currencyFormat.format(transaction['amount'].abs());
    final date = DateFormat(
      'MMM d, hh:mm a',
    ).format(DateTime.parse(transaction['date']));

    IconData getIcon() {
      switch (transaction['type']) {
        case 'remittance':
        case 'cash-in':
          return Symbols.arrow_downward_alt_rounded;
        case 'cash-out':
          return Symbols.arrow_upward_alt_rounded;
        default:
          return Icons.receipt_long_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isCredit
                ? Colors.green.shade50
                : Colors.red.shade50,
            child: Icon(
              getIcon(),
              color: isCredit ? Colors.green.shade600 : Colors.red.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['description'],
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: GoogleFonts.nunito(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isCredit ? '+' : '-'} $amount',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
