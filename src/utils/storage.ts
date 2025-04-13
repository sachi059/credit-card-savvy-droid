
import { CreditCard } from '@/types/card';

const STORAGE_KEY = 'credit-cards';

export const getCards = (): CreditCard[] => {
  try {
    const cardsJson = localStorage.getItem(STORAGE_KEY);
    if (!cardsJson) return [];
    return JSON.parse(cardsJson);
  } catch (error) {
    console.error('Failed to get cards from storage:', error);
    return [];
  }
};

export const saveCards = (cards: CreditCard[]): void => {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(cards));
  } catch (error) {
    console.error('Failed to save cards to storage:', error);
  }
};

export const addCard = (card: CreditCard): void => {
  const cards = getCards();
  cards.push(card);
  saveCards(cards);
};

export const updateCard = (updatedCard: CreditCard): void => {
  const cards = getCards();
  const index = cards.findIndex(card => card.id === updatedCard.id);
  if (index !== -1) {
    cards[index] = updatedCard;
    saveCards(cards);
  }
};

export const deleteCard = (id: string): void => {
  const cards = getCards();
  const filteredCards = cards.filter(card => card.id !== id);
  saveCards(filteredCards);
};
