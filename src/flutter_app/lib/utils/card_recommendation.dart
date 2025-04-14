
import 'package:credit_card_savvy/models/credit_card.dart';

int calculateDaysUntilBilling(int billingDay) {
  final today = DateTime.now();
  final currentDay = today.day;
  final currentMonth = today.month;
  final currentYear = today.year;

  // Set target date to this month's billing day
  var targetDate = DateTime(currentYear, currentMonth, billingDay);
  
  // If billing day has passed this month, set target to next month
  if (currentDay > billingDay) {
    targetDate = DateTime(currentYear, currentMonth + 1, billingDay);
  }
  
  // Calculate days difference
  final difference = targetDate.difference(today);
  return difference.inDays;
}

int calculateDaysUntilStatement(int statementDay) {
  final today = DateTime.now();
  final currentDay = today.day;
  final currentMonth = today.month;
  final currentYear = today.year;

  // Set target date to this month's statement day
  var targetDate = DateTime(currentYear, currentMonth, statementDay);
  
  // If statement day has passed this month, set target to next month
  if (currentDay > statementDay) {
    targetDate = DateTime(currentYear, currentMonth + 1, statementDay);
  }
  
  // Calculate days difference
  final difference = targetDate.difference(today);
  return difference.inDays;
}

int calculateInterestFreePeriod(CreditCard card) {
  // Calculate days from statement to billing
  var daysFromStatementToBilling = card.billingDate - card.statementDate;
  
  // If billing date is earlier in the month than statement date, add days in month
  if (daysFromStatementToBilling < 0) {
    daysFromStatementToBilling += 30; // Approximation for month length
  }
  
  // Add days until next statement
  final daysUntilStatement = calculateDaysUntilStatement(card.statementDate);
  
  return daysUntilStatement + daysFromStatementToBilling;
}

CreditCard? getBestCard(List<CreditCard> cards) {
  if (cards.isEmpty) return null;
  
  // Sort cards by interest free period, longest first
  final sortedCards = List<CreditCard>.from(cards);
  sortedCards.sort((a, b) {
    final periodA = calculateInterestFreePeriod(a);
    final periodB = calculateInterestFreePeriod(b);
    return periodB.compareTo(periodA);
  });
  
  return sortedCards.first;
}
