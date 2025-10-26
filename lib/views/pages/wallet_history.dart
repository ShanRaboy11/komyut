import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// An enum to make our code cleaner and safer.
enum HistoryType { transactions, tokens }

class TransactionHistoryPage extends StatelessWidget {
  final HistoryType type;

  const TransactionHistoryPage({super.key, required this.type});

  // Dummy data for a long list
  List<Map<String, dynamic>> get _dummyTransactions => List.generate(14, (i) {
    bool isCashIn = i == 0 || i == 13;
    return {
      'title': isCashIn ? 'Cash In' : 'Trip Fare',
      'subtitle': '10/${i % 2 + 2}/25 ${i % 5 + 1}:${i * 4} PM',
      'amount': isCashIn ? '+₱100.00' : '−₱13.00',
      'isCredit': isCashIn,
    };
  });

  List<Map<String, dynamic>> get _dummyTokens => List.generate(14, (i) {
    bool isReward = i % 2 != 0;
    return {
      'title': isReward ? 'Trip Reward' : 'Token Redemption',
      'subtitle': '10/${i % 3 + 1}/25 ${i % 6 + 1}:${i * 3} PM',
      'amount': isReward ? '+0.5' : '-${(i % 5 + 1)}.0',
      'isCredit': isReward,
    };
  });

  @override
  Widget build(BuildContext context) {
    final bool isTransactions = type == HistoryType.transactions;
    final data = isTransactions ? _dummyTransactions : _dummyTokens;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isTransactions ? 'Transactions' : 'Tokens',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
            child: Text(
              isTransactions ? 'All Transactions' : 'Token History',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 100.0),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final isLast = index == data.length - 1;
                return isTransactions
                    ? _buildTransactionItem(
                        item['title'],
                        item['subtitle'],
                        item['amount'],
                        item['isCredit'],
                        isLast: isLast,
                      )
                    : _buildTokenItem(
                        item['title'],
                        item['subtitle'],
                        item['amount'],
                        item['isCredit'],
                        isLast: isLast,
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- UPDATED WIDGETS ---

  Widget _buildTransactionItem(
    String title,
    String subtitle,
    String amount,
    bool isCredit, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        // The 'color: Colors.white' property has been removed.
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.nunito(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          Text(
            amount,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isCredit
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFC62828),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenItem(
    String title,
    String subtitle,
    String amount,
    bool isCredit, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        // The 'color: Colors.white' property has been removed.
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.nunito(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                amount,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCredit
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828),
                ),
              ),
              const SizedBox(width: 6),
              Image.asset('assets/images/wheel token.png', height: 20),
            ],
          ),
        ],
      ),
    );
  }
}
