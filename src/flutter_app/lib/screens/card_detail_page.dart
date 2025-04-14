
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:credit_card_savvy/models/credit_card.dart';
import 'package:credit_card_savvy/utils/card_recommendation.dart';
import 'package:credit_card_savvy/screens/card_form_page.dart';
import 'package:credit_card_savvy/widgets/detail_row.dart';
import 'package:credit_card_savvy/widgets/cycle_info_card.dart';

class CardDetailPage extends StatelessWidget {
  final CreditCard card;
  
  const CardDetailPage({Key? key, required this.card}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysUntilStatement = calculateDaysUntilStatement(card.statementDate);
    final daysUntilBilling = calculateDaysUntilBilling(card.billingDate);
    final interestFreePeriod = calculateInterestFreePeriod(card);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(card.nickname),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Display
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: card.color ?? theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card.nickname,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.credit_card,
                        color: Colors.white.withOpacity(0.8),
                        size: 32,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Card Number',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '•••• •••• •••• ${card.lastFourDigits}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card.provider.toString().split('.').last.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      if (card.creditLimit != null)
                        Text(
                          'Limit: ${NumberFormat.currency(symbol: '\$').format(card.creditLimit)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Card Details
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Card Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    DetailRow(
                      label: 'Statement Date',
                      value: 'Day ${card.statementDate} of each month',
                      icon: Icons.calendar_today,
                    ),
                    DetailRow(
                      label: 'Payment Due Date',
                      value: 'Day ${card.billingDate} of each month',
                      icon: Icons.event,
                    ),
                    if (card.creditLimit != null)
                      DetailRow(
                        label: 'Credit Limit',
                        value: NumberFormat.currency(symbol: '\$').format(card.creditLimit),
                        icon: Icons.account_balance_wallet,
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Current Cycle Info
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Cycle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: CycleInfoCard(
                            title: 'Next Statement',
                            value: '$daysUntilStatement',
                            unit: 'days',
                            icon: Icons.calendar_today,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CycleInfoCard(
                            title: 'Payment Due',
                            value: '$daysUntilBilling',
                            unit: 'days',
                            icon: Icons.payment,
                            color: daysUntilBilling <= 7
                                ? Colors.red
                                : daysUntilBilling <= 14
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CycleInfoCard(
                      title: 'Interest-Free Period',
                      value: '$interestFreePeriod',
                      unit: 'days',
                      icon: Icons.access_time,
                      color: theme.colorScheme.primary,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Edit Button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CardFormPage(initialCard: card),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Card'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
