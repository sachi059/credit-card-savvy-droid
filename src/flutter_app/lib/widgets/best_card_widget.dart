
import 'package:flutter/material.dart';
import 'package:credit_card_savvy/models/credit_card.dart';
import 'package:credit_card_savvy/utils/card_recommendation.dart';

class BestCardWidget extends StatelessWidget {
  final CreditCard? bestCard;
  
  const BestCardWidget({Key? key, required this.bestCard}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (bestCard == null) return const SizedBox.shrink();
    
    final interestFreePeriod = calculateInterestFreePeriod(bestCard!);
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Best Card to Use Today',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Icon(
                  Icons.star,
                  color: theme.colorScheme.onPrimary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              bestCard!.nickname,
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Text(
              '•••• ${bestCard!.lastFourDigits}',
              style: TextStyle(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Up to $interestFreePeriod days interest-free',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
