
import { useState, useEffect } from 'react';
import { CreditCard } from '@/types/card';
import { getCards, saveCards, addCard, updateCard, deleteCard } from '@/utils/storage';
import { getBestCard } from '@/utils/cardRecommendation';
import { Button } from '@/components/ui/button';
import { Plus, CreditCard as CreditCardIcon } from 'lucide-react';
import CreditCardItem from '@/components/CreditCardItem';
import CardForm from '@/components/CardForm';
import CreditCardSummary from '@/components/CreditCardSummary';
import { useToast } from '@/components/ui/use-toast';

const Index = () => {
  const { toast } = useToast();
  const [cards, setCards] = useState<CreditCard[]>([]);
  const [bestCard, setBestCard] = useState<CreditCard | null>(null);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingCard, setEditingCard] = useState<CreditCard | null>(null);

  useEffect(() => {
    const loadedCards = getCards();
    setCards(loadedCards);
    updateBestCard(loadedCards);
  }, []);

  const updateBestCard = (cardList: CreditCard[]) => {
    const best = getBestCard(cardList);
    setBestCard(best);
  };

  const handleAddCard = (card: CreditCard) => {
    const newCards = [...cards, card];
    setCards(newCards);
    saveCards(newCards);
    updateBestCard(newCards);
    toast({
      title: "Card Added",
      description: `${card.nickname} has been added to your wallet.`,
    });
  };

  const handleUpdateCard = (card: CreditCard) => {
    const updatedCards = cards.map(c => c.id === card.id ? card : c);
    setCards(updatedCards);
    updateCard(card);
    updateBestCard(updatedCards);
    toast({
      title: "Card Updated",
      description: `${card.nickname} has been updated.`,
    });
  };

  const handleDeleteCard = (id: string) => {
    const cardToDelete = cards.find(c => c.id === id);
    const updatedCards = cards.filter(card => card.id !== id);
    setCards(updatedCards);
    deleteCard(id);
    updateBestCard(updatedCards);
    toast({
      title: "Card Deleted",
      description: cardToDelete ? `${cardToDelete.nickname} has been removed.` : "Card has been removed.",
      variant: "destructive",
    });
  };

  const openAddForm = () => {
    setEditingCard(null);
    setIsFormOpen(true);
  };

  const openEditForm = (card: CreditCard) => {
    setEditingCard(card);
    setIsFormOpen(true);
  };

  const handleSaveCard = (card: CreditCard) => {
    if (editingCard) {
      handleUpdateCard(card);
    } else {
      handleAddCard(card);
    }
  };

  return (
    <div className="min-h-screen bg-background">
      <div className="max-w-md mx-auto pt-8 px-4">
        <header className="mb-8">
          <h1 className="text-3xl font-bold text-center mb-2">Credit Card Savvy</h1>
          <p className="text-muted-foreground text-center">
            Manage your cards and maximize interest-free periods
          </p>
        </header>

        <CreditCardSummary bestCard={bestCard} cards={cards} />

        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">Your Cards</h2>
          <Button onClick={openAddForm} size="sm">
            <Plus className="h-4 w-4 mr-1" />
            Add Card
          </Button>
        </div>

        {cards.length === 0 ? (
          <div className="text-center py-10 border border-dashed rounded-lg">
            <CreditCardIcon className="h-12 w-12 mx-auto text-muted-foreground opacity-50" />
            <p className="mt-4 text-muted-foreground">
              You haven't added any credit cards yet
            </p>
            <Button variant="outline" onClick={openAddForm} className="mt-4">
              Add Your First Card
            </Button>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4">
            {cards.map(card => (
              <CreditCardItem
                key={card.id}
                card={card}
                isBest={bestCard?.id === card.id}
                onEdit={openEditForm}
                onDelete={handleDeleteCard}
              />
            ))}
          </div>
        )}

        <CardForm
          isOpen={isFormOpen}
          onClose={() => setIsFormOpen(false)}
          onSave={handleSaveCard}
          editCard={editingCard}
        />

        <footer className="mt-8 mb-4 text-center text-xs text-muted-foreground">
          <p>Credit Card Savvy &copy; 2025</p>
          <p className="mt-1">All your data is stored locally on your device</p>
        </footer>
      </div>
    </div>
  );
};

export default Index;
