
import { useState, useEffect } from 'react';
import { CreditCard, CardProvider } from '@/types/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useToast } from '@/components/ui/use-toast';

interface CardFormProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (card: CreditCard) => void;
  editCard: CreditCard | null;
}

const CardForm = ({ isOpen, onClose, onSave, editCard }: CardFormProps) => {
  const { toast } = useToast();
  const [card, setCard] = useState<Partial<CreditCard>>({
    nickname: '',
    lastFourDigits: '',
    provider: 'visa',
    statementDate: 1,
    billingDate: 15,
  });

  useEffect(() => {
    if (editCard) {
      setCard(editCard);
    } else {
      setCard({
        nickname: '',
        lastFourDigits: '',
        provider: 'visa',
        statementDate: 1,
        billingDate: 15,
      });
    }
  }, [editCard, isOpen]);

  const handleChange = (field: keyof CreditCard, value: any) => {
    setCard(prev => ({ ...prev, [field]: value }));
  };

  const validateCard = (): boolean => {
    if (!card.nickname) {
      toast({
        title: "Nickname required",
        description: "Please enter a nickname for this card",
        variant: "destructive"
      });
      return false;
    }

    if (!card.lastFourDigits || card.lastFourDigits.length !== 4 || !/^\d{4}$/.test(card.lastFourDigits)) {
      toast({
        title: "Invalid card number",
        description: "Please enter the last 4 digits of your card number",
        variant: "destructive"
      });
      return false;
    }

    if (!card.statementDate || card.statementDate < 1 || card.statementDate > 31) {
      toast({
        title: "Invalid statement date",
        description: "Please enter a valid day of the month (1-31)",
        variant: "destructive"
      });
      return false;
    }

    if (!card.billingDate || card.billingDate < 1 || card.billingDate > 31) {
      toast({
        title: "Invalid billing date",
        description: "Please enter a valid day of the month (1-31)",
        variant: "destructive"
      });
      return false;
    }

    return true;
  };

  const handleSubmit = () => {
    if (!validateCard()) return;

    const newCard: CreditCard = {
      id: editCard?.id || Date.now().toString(),
      nickname: card.nickname!,
      lastFourDigits: card.lastFourDigits!,
      provider: card.provider as CardProvider,
      statementDate: Number(card.statementDate),
      billingDate: Number(card.billingDate),
      creditLimit: card.creditLimit,
    };

    onSave(newCard);
    onClose();
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>{editCard ? 'Edit Card' : 'Add New Card'}</DialogTitle>
        </DialogHeader>
        <div className="grid gap-4 py-4">
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="nickname" className="text-right">
              Card Nickname
            </Label>
            <Input
              id="nickname"
              value={card.nickname || ''}
              onChange={(e) => handleChange('nickname', e.target.value)}
              className="col-span-3"
              placeholder="Personal Visa"
            />
          </div>
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="lastFourDigits" className="text-right">
              Last 4 Digits
            </Label>
            <Input
              id="lastFourDigits"
              value={card.lastFourDigits || ''}
              onChange={(e) => handleChange('lastFourDigits', e.target.value)}
              className="col-span-3"
              placeholder="1234"
              maxLength={4}
            />
          </div>
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="provider" className="text-right">
              Card Provider
            </Label>
            <Select
              value={card.provider}
              onValueChange={(value) => handleChange('provider', value)}
            >
              <SelectTrigger className="col-span-3">
                <SelectValue placeholder="Select provider" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="visa">Visa</SelectItem>
                <SelectItem value="mastercard">MasterCard</SelectItem>
                <SelectItem value="amex">American Express</SelectItem>
                <SelectItem value="discover">Discover</SelectItem>
                <SelectItem value="other">Other</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="statementDate" className="text-right">
              Statement Day
            </Label>
            <Input
              id="statementDate"
              type="number"
              min={1}
              max={31}
              value={card.statementDate || ''}
              onChange={(e) => handleChange('statementDate', parseInt(e.target.value))}
              className="col-span-3"
              placeholder="1"
            />
          </div>
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="billingDate" className="text-right">
              Billing Day
            </Label>
            <Input
              id="billingDate"
              type="number"
              min={1}
              max={31}
              value={card.billingDate || ''}
              onChange={(e) => handleChange('billingDate', parseInt(e.target.value))}
              className="col-span-3"
              placeholder="15"
            />
          </div>
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="creditLimit" className="text-right">
              Credit Limit
            </Label>
            <Input
              id="creditLimit"
              type="number"
              value={card.creditLimit || ''}
              onChange={(e) => handleChange('creditLimit', parseInt(e.target.value))}
              className="col-span-3"
              placeholder="Optional"
            />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button onClick={handleSubmit}>Save</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default CardForm;
