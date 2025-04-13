
import { CreditCard } from '@/types/card';

export const calculateDaysUntilBilling = (billingDay: number): number => {
  const today = new Date();
  const currentDay = today.getDate();
  const currentMonth = today.getMonth();
  const currentYear = today.getFullYear();

  // Set target date to this month's billing day
  let targetDate = new Date(currentYear, currentMonth, billingDay);
  
  // If billing day has passed this month, set target to next month
  if (currentDay > billingDay) {
    targetDate = new Date(currentYear, currentMonth + 1, billingDay);
  }
  
  // Calculate days difference
  const timeDiff = targetDate.getTime() - today.getTime();
  return Math.ceil(timeDiff / (1000 * 3600 * 24));
};

export const calculateDaysUntilStatement = (statementDay: number): number => {
  const today = new Date();
  const currentDay = today.getDate();
  const currentMonth = today.getMonth();
  const currentYear = today.getFullYear();

  // Set target date to this month's statement day
  let targetDate = new Date(currentYear, currentMonth, statementDay);
  
  // If statement day has passed this month, set target to next month
  if (currentDay > statementDay) {
    targetDate = new Date(currentYear, currentMonth + 1, statementDay);
  }
  
  // Calculate days difference
  const timeDiff = targetDate.getTime() - today.getTime();
  return Math.ceil(timeDiff / (1000 * 3600 * 24));
};

export const calculateInterestFreePeriod = (card: CreditCard): number => {
  // Calculate days from statement to billing
  let daysFromStatementToBilling = card.billingDate - card.statementDate;
  
  // If billing date is earlier in the month than statement date, add days in month
  if (daysFromStatementToBilling < 0) {
    daysFromStatementToBilling += 30; // Approximation for month length
  }
  
  // Add days until next statement
  const daysUntilStatement = calculateDaysUntilStatement(card.statementDate);
  
  return daysUntilStatement + daysFromStatementToBilling;
};

export const getBestCard = (cards: CreditCard[]): CreditCard | null => {
  if (!cards.length) return null;
  
  // Sort cards by interest free period, longest first
  const sortedCards = [...cards].sort((a, b) => {
    const periodA = calculateInterestFreePeriod(a);
    const periodB = calculateInterestFreePeriod(b);
    return periodB - periodA;
  });
  
  return sortedCards[0];
};
