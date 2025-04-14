
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:credit_card_savvy/models/credit_card.dart';
import 'package:credit_card_savvy/services/card_storage.dart';

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
