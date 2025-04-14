
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:credit_card_savvy/models/credit_card.dart';
import 'package:credit_card_savvy/services/github_sync.dart';

class CardStorage {
  static const String storageKey = 'credit_cards';
  
  static Future<List<CreditCard>> getCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cardsJson = prefs.getString(storageKey);
      if (cardsJson == null) return [];
      
      final List<dynamic> decoded = jsonDecode(cardsJson);
      return decoded.map((item) => CreditCard.fromJson(item)).toList();
    } catch (e) {
      print('Failed to get cards from storage: $e');
      return [];
    }
  }
  
  static Future<void> saveCards(List<CreditCard> cards) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(cards.map((card) => card.toJson()).toList());
      await prefs.setString(storageKey, encoded);

      // After saving locally, sync to GitHub if possible
      final githubSync = GitHubSync();
      if (await githubSync.isAuthenticated()) {
        await githubSync.syncData(encoded);
      }
    } catch (e) {
      print('Failed to save cards to storage: $e');
    }
  }
  
  static Future<void> addCard(CreditCard card) async {
    final cards = await getCards();
    cards.add(card);
    await saveCards(cards);
  }
  
  static Future<void> updateCard(CreditCard updatedCard) async {
    final cards = await getCards();
    final index = cards.indexWhere((card) => card.id == updatedCard.id);
    if (index != -1) {
      cards[index] = updatedCard;
      await saveCards(cards);
    }
  }
  
  static Future<void> deleteCard(String id) async {
    final cards = await getCards();
    cards.removeWhere((card) => card.id == id);
    await saveCards(cards);
  }
}
