
import 'package:flutter/material.dart';
import 'package:credit_card_savvy/models/credit_card.dart';
import 'package:credit_card_savvy/utils/card_recommendation.dart';

class CreditCardItem extends StatelessWidget {
  final CreditCard card;
  final VoidCallback onTap;
  
  const CreditCardItem({
    Key? key,
    required this.card,
    required this.onTap,
  }) : super(key: key);

  IconData _getCardIcon() {
    switch (card.provider) {
      case CardProvider.visa:
        return Icons.credit_card;
      case CardProvider.mastercard:
        return Icons.credit_card;
      case CardProvider.amex:
        return Icons.credit_card;
      case CardProvider.discover:
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysUntilBilling = calculateDaysUntilBilling(card.billingDate);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: card.color ?? theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCardIcon(),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.nickname,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '•••• ${card.lastFourDigits}',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: daysUntilBilling <= 7
                      ? Colors.red.withOpacity(0.1)
                      : daysUntilBilling <= 14
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Due in $daysUntilBilling days',
                  style: TextStyle(
                    color: daysUntilBilling <= 7
                        ? Colors.red
                        : daysUntilBilling <= 14
                            ? Colors.orange
                            : Colors.green,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
