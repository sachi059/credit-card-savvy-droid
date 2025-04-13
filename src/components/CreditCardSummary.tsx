
import { CreditCard } from '@/types/card';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { AlertCircle, CreditCard as CreditCardIcon, Calendar } from 'lucide-react';
import { 
  calculateInterestFreePeriod, 
  calculateDaysUntilBilling,
  calculateDaysUntilStatement
} from '@/utils/cardRecommendation';

interface CreditCardSummaryProps {
  bestCard: CreditCard | null;
  cards: CreditCard[];
}

const CreditCardSummary = ({ bestCard, cards }: CreditCardSummaryProps) => {
  if (!bestCard) {
    return (
      <Card className="mb-6">
        <CardHeader>
          <CardTitle className="text-center flex items-center justify-center">
            <AlertCircle className="mr-2 h-5 w-5 text-yellow-500" />
            No Credit Cards
          </CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-center text-muted-foreground">
            Add a card to see recommendations on which card to use for maximum interest-free period.
          </p>
        </CardContent>
      </Card>
    );
  }

  const bestInterestFreePeriod = calculateInterestFreePeriod(bestCard);
  const daysUntilBilling = calculateDaysUntilBilling(bestCard.billingDate);
  const daysUntilStatement = calculateDaysUntilStatement(bestCard.statementDate);

  return (
    <Card className="mb-6 bg-gradient-to-br from-blue-50 to-white dark:from-blue-950 dark:to-gray-900">
      <CardHeader>
        <CardTitle className="text-center">
          Recommended Card
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex flex-col items-center space-y-4">
          <div className="h-16 w-16 rounded-full bg-primary/10 flex items-center justify-center">
            <CreditCardIcon className="h-8 w-8 text-primary" />
          </div>
          
          <h3 className="text-xl font-semibold">{bestCard.nickname}</h3>
          
          <div className="grid grid-cols-2 gap-4 w-full">
            <div className="flex flex-col items-center p-3 bg-background rounded-lg">
              <span className="text-3xl font-bold text-primary">{bestInterestFreePeriod}</span>
              <span className="text-xs text-muted-foreground">Interest-Free Days</span>
            </div>
            
            <div className="flex flex-col items-center p-3 bg-background rounded-lg">
              <span className="text-3xl font-bold text-primary">{daysUntilBilling}</span>
              <span className="text-xs text-muted-foreground">Days Until Due</span>
            </div>
          </div>
          
          <div className="text-sm text-muted-foreground text-center mt-2">
            <div className="flex items-center justify-center">
              <Calendar className="h-4 w-4 mr-1" />
              Statement on day {bestCard.statementDate}, payment due on day {bestCard.billingDate}
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default CreditCardSummary;
