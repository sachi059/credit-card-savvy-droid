
import 'package:flutter/material.dart';

enum CardProvider { visa, mastercard, amex, discover, other }

class CreditCard {
  final String id;
  final String nickname;
  final String lastFourDigits;
  final CardProvider provider;
  final int statementDate; // Day of the month when statement is generated
  final int billingDate; // Day of the month when payment is due
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
      creditLimit: json['creditLimit'] != null ? json['creditLimit'].toDouble() : null,
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
