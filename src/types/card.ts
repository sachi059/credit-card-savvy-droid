
export type CardProvider = 'visa' | 'mastercard' | 'amex' | 'discover' | 'other';

export interface CreditCard {
  id: string;
  nickname: string;
  lastFourDigits: string;
  provider: CardProvider;
  statementDate: number; // Day of the month when statement is generated
  billingDate: number; // Day of the month when payment is due
  creditLimit?: number;
  color?: string;
}
