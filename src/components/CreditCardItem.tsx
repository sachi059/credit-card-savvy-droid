
import { CreditCard } from '@/types/card';
import { useState } from 'react';
import { calculateDaysUntilBilling, calculateInterestFreePeriod } from '@/utils/cardRecommendation';
import { CreditCard as CreditCardIcon, Calendar, BadgeCheck } from 'lucide-react';

interface CreditCardItemProps {
  card: CreditCard;
  isBest: boolean;
  onEdit: (card: CreditCard) => void;
  onDelete: (id: string) => void;
}

const CreditCardItem = ({ card, isBest, onEdit, onDelete }: CreditCardItemProps) => {
  const [isFlipped, setIsFlipped] = useState(false);

  const getProviderLogo = () => {
    switch (card.provider) {
      case 'visa':
        return <span className="text-white font-bold italic text-lg">VISA</span>;
      case 'mastercard':
        return <span className="text-white font-bold text-lg">MasterCard</span>;
      case 'amex':
        return <span className="text-white font-bold text-lg">AMEX</span>;
      case 'discover':
        return <span className="text-white font-bold text-lg">Discover</span>;
      default:
        return <CreditCardIcon className="text-white" />;
    }
  };

  const daysUntilBilling = calculateDaysUntilBilling(card.billingDate);
  const interestFreePeriod = calculateInterestFreePeriod(card);

  return (
    <div className="w-full mb-4">
      <div 
        className={`credit-card ${card.provider} ${isBest ? 'best' : ''}`}
        onClick={() => setIsFlipped(!isFlipped)}
      >
        {!isFlipped ? (
          // Front of card
          <>
            <div className="credit-card-chip"></div>
            <div className="absolute top-4 right-4">
              {getProviderLogo()}
            </div>
            <div className="absolute bottom-16 left-5 right-5">
              <div className="credit-card-number text-white text-lg font-mono">
                •••• •••• •••• {card.lastFourDigits}
              </div>
            </div>
            <div className="absolute bottom-4 left-5">
              <div className="text-white font-medium">
                {card.nickname}
              </div>
            </div>
            {isBest && (
              <div className="absolute top-4 left-20 flex items-center">
                <BadgeCheck className="h-6 w-6 text-green-300" />
                <span className="text-white text-sm ml-1">Best Choice</span>
              </div>
            )}
          </>
        ) : (
          // Back of card - show important dates
          <div className="flex flex-col justify-center h-full">
            <div className="text-white mb-2">
              <span className="font-semibold">Statement Date:</span> Day {card.statementDate}
            </div>
            <div className="text-white mb-2">
              <span className="font-semibold">Billing Date:</span> Day {card.billingDate}
            </div>
            <div className="text-white mb-2">
              <span className="font-semibold">Days until billing:</span> {daysUntilBilling}
            </div>
            <div className="text-white mb-6">
              <span className="font-semibold">Interest-free period:</span> {interestFreePeriod} days
            </div>
            <div className="flex space-x-2">
              <button 
                onClick={(e) => {
                  e.stopPropagation();
                  onEdit(card);
                }}
                className="bg-white/20 hover:bg-white/30 text-white py-1 px-3 rounded text-sm"
              >
                Edit
              </button>
              <button 
                onClick={(e) => {
                  e.stopPropagation();
                  onDelete(card.id);
                }}
                className="bg-red-500/70 hover:bg-red-500/90 text-white py-1 px-3 rounded text-sm"
              >
                Delete
              </button>
            </div>
          </div>
        )}
      </div>
      <div className="text-sm mt-2 text-center text-muted-foreground">
        {!isFlipped ? "Tap to see details" : "Tap to see card"}
      </div>
    </div>
  );
};

export default CreditCardItem;
