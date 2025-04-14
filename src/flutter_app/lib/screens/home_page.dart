
import 'package:flutter/material.dart';
import 'package:credit_card_savvy/services/auth_service.dart';
import '../widgets/user_profile_widget.dart';
// Import the required models and utilities
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Reusing existing models and utility functions
enum CardProvider { visa, mastercard, amex, discover, other }

class CreditCard {
  final String id;
  final String nickname;
  final String lastFourDigits;
  final CardProvider provider;
  final int statementDate;
  final int billingDate;
  final double? creditLimit;
  final Color? color;

  CreditCard({
    required this.id,
    required this.nickname,
    required this.lastFourDigits,
    required this.provider,
    required this.statementDate,
    required this.billingDate,
    this.creditLimit,
    this.color,
  });

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      id: json['id'],
      nickname: json['nickname'],
      lastFourDigits: json['lastFourDigits'],
      provider: CardProvider.values.firstWhere(
        (e) => e.toString().split('.').last == json['provider'],
        orElse: () => CardProvider.other,
      ),
      statementDate: json['statementDate'],
      billingDate: json['billingDate'],
      creditLimit: json['creditLimit'],
      color: json['color'] != null ? Color(int.parse(json['color'])) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'lastFourDigits': lastFourDigits,
        'provider': provider.toString().split('.').last,
        'statementDate': statementDate,
        'billingDate': billingDate,
        'creditLimit': creditLimit,
        'color': color?.value.toString(),
      };
}

// Card Storage Service
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

// Card Recommendation Utilities
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

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CreditCard> _cards = [];
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    final cards = await CardStorage.getCards();
    setState(() {
      _cards = cards;
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Card Savvy'),
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CardFormPage()),
          );
          _loadCards();
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCards,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Profile Widget
                    UserProfileWidget(onSignOut: _signOut),
                    
                    // Best Card Recommendation
                    if (_cards.isNotEmpty) 
                      BestCardWidget(bestCard: getBestCard(_cards)),
                    
                    const SizedBox(height: 24),
                    
                    if (_cards.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.credit_card, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'No credit cards yet',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add a card to get started',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CardFormPage()),
                                );
                                _loadCards();
                              },
                              child: const Text('Add Card'),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Cards',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Card List
                          ..._cards.map((card) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CreditCardItem(
                              card: card,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CardDetailPage(card: card),
                                  ),
                                );
                                _loadCards();
                              },
                            ),
                          )).toList(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Best Card Widget
class BestCardWidget extends StatelessWidget {
  final CreditCard? bestCard;
  
  const BestCardWidget({Key? key, required this.bestCard}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (bestCard == null) return const SizedBox.shrink();
    
    final interestFreePeriod = calculateInterestFreePeriod(bestCard!);
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Best Card to Use Today',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Icon(
                  Icons.star,
                  color: theme.colorScheme.onPrimary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              bestCard!.nickname,
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Text(
              '•••• ${bestCard!.lastFourDigits}',
              style: TextStyle(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Up to $interestFreePeriod days interest-free',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Credit Card Item Widget
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

// Card Form Page
class CardFormPage extends StatefulWidget {
  final CreditCard? initialCard;
  
  const CardFormPage({Key? key, this.initialCard}) : super(key: key);

  @override
  State<CardFormPage> createState() => _CardFormPageState();
}

class _CardFormPageState extends State<CardFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _lastFourDigitsController = TextEditingController();
  final _statementDateController = TextEditingController();
  final _billingDateController = TextEditingController();
  final _creditLimitController = TextEditingController();
  
  CardProvider _selectedProvider = CardProvider.visa;
  Color _selectedColor = Colors.blue;
  
  @override
  void initState() {
    super.initState();
    if (widget.initialCard != null) {
      _nicknameController.text = widget.initialCard!.nickname;
      _lastFourDigitsController.text = widget.initialCard!.lastFourDigits;
      _statementDateController.text = widget.initialCard!.statementDate.toString();
      _billingDateController.text = widget.initialCard!.billingDate.toString();
      if (widget.initialCard!.creditLimit != null) {
        _creditLimitController.text = widget.initialCard!.creditLimit.toString();
      }
      _selectedProvider = widget.initialCard!.provider;
      if (widget.initialCard!.color != null) {
        _selectedColor = widget.initialCard!.color!;
      }
    }
  }
  
  @override
  void dispose() {
    _nicknameController.dispose();
    _lastFourDigitsController.dispose();
    _statementDateController.dispose();
    _billingDateController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;
    
    final newCard = CreditCard(
      id: widget.initialCard?.id ?? const Uuid().v4(),
      nickname: _nicknameController.text,
      lastFourDigits: _lastFourDigitsController.text,
      provider: _selectedProvider,
      statementDate: int.parse(_statementDateController.text),
      billingDate: int.parse(_billingDateController.text),
      creditLimit: _creditLimitController.text.isNotEmpty
          ? double.parse(_creditLimitController.text)
          : null,
      color: _selectedColor,
    );
    
    if (widget.initialCard != null) {
      await CardStorage.updateCard(newCard);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card updated successfully')),
      );
    } else {
      await CardStorage.addCard(newCard);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card added successfully')),
      );
    }
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialCard != null ? 'Edit Card' : 'Add New Card'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'Card Nickname',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a nickname';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastFourDigitsController,
              decoration: const InputDecoration(
                labelText: 'Last 4 Digits',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter last 4 digits';
                }
                if (value.length != 4) {
                  return 'Please enter exactly 4 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CardProvider>(
              value: _selectedProvider,
              decoration: const InputDecoration(
                labelText: 'Card Provider',
                border: OutlineInputBorder(),
              ),
              items: CardProvider.values.map((provider) {
                return DropdownMenuItem(
                  value: provider,
                  child: Text(provider.toString().split('.').last.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedProvider = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _statementDateController,
              decoration: const InputDecoration(
                labelText: 'Statement Date (day of month)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter statement date';
                }
                final day = int.tryParse(value);
                if (day == null || day < 1 || day > 31) {
                  return 'Please enter a valid day (1-31)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _billingDateController,
              decoration: const InputDecoration(
                labelText: 'Billing Date (day of month)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter billing date';
                }
                final day = int.tryParse(value);
                if (day == null || day < 1 || day > 31) {
                  return 'Please enter a valid day (1-31)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _creditLimitController,
              decoration: const InputDecoration(
                labelText: 'Credit Limit (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            const Text(
              'Card Color',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                Colors.blue,
                Colors.red,
                Colors.green,
                Colors.purple,
                Colors.orange,
                Colors.teal,
                Colors.pink,
                Colors.indigo,
              ].map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color
                            ? Colors.white
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: _selectedColor == color
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveCard,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.initialCard != null ? 'Update Card' : 'Add Card',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (widget.initialCard != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Card'),
                      content: const Text(
                        'Are you sure you want to delete this card? This action cannot be undone.'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    await CardStorage.deleteCard(widget.initialCard!.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Card deleted successfully')),
                    );
                    if (mounted) Navigator.pop(context);
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.red,
                ),
                child: const Text(
                  'Delete Card',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Card Detail Page
class CardDetailPage extends StatelessWidget {
  final CreditCard card;
  
  const CardDetailPage({Key? key, required this.card}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysUntilStatement = calculateDaysUntilStatement(card.statementDate);
    final daysUntilBilling = calculateDaysUntilBilling(card.billingDate);
    final interestFreePeriod = calculateInterestFreePeriod(card);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(card.nickname),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Display
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: card.color ?? theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card.nickname,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.credit_card,
                        color: Colors.white.withOpacity(0.8),
                        size: 32,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Card Number',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '•••• •••• •••• ${card.lastFourDigits}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card.provider.toString().split('.').last.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      if (card.creditLimit != null)
                        Text(
                          'Limit: ${NumberFormat.currency(symbol: '\$').format(card.creditLimit)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Card Details
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Card Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    DetailRow(
                      label: 'Statement Date',
                      value: 'Day ${card.statementDate} of each month',
                      icon: Icons.calendar_today,
                    ),
                    DetailRow(
                      label: 'Payment Due Date',
                      value: 'Day ${card.billingDate} of each month',
                      icon: Icons.event,
                    ),
                    if (card.creditLimit != null)
                      DetailRow(
                        label: 'Credit Limit',
                        value: NumberFormat.currency(symbol: '\$').format(card.creditLimit),
                        icon: Icons.account_balance_wallet,
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Current Cycle Info
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Cycle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _CycleInfoCard(
                            title: 'Next Statement',
                            value: '$daysUntilStatement',
                            unit: 'days',
                            icon: Icons.calendar_today,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CycleInfoCard(
                            title: 'Payment Due',
                            value: '$daysUntilBilling',
                            unit: 'days',
                            icon: Icons.payment,
                            color: daysUntilBilling <= 7
                                ? Colors.red
                                : daysUntilBilling <= 14
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _CycleInfoCard(
                      title: 'Interest-Free Period',
                      value: '$interestFreePeriod',
                      unit: 'days',
                      icon: Icons.access_time,
                      color: theme.colorScheme.primary,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Edit Button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CardFormPage(initialCard: card),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Card'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper Widgets
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  
  const DetailRow({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool fullWidth;
  
  const _CycleInfoCard({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

