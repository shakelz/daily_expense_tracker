/// EXAMPLE USAGE OF WhatsAppStyleBubble
/// 
/// This file demonstrates how to use the WhatsApp-style bubble widget
/// in your transaction list or floating overlay.

import 'package:flutter/material.dart';
import '../models/expense_entry.dart';
import '../widgets/whatsapp_bubble.dart';

/// Example: Using bubbles in a transaction list
class TransactionListExample extends StatelessWidget {
  final List<ExpenseEntry> transactions;

  const TransactionListExample({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        
        return WhatsAppStyleBubble(
          title: transaction.title,
          amount: transaction.amount,
          categoryIcon: _getCategoryIcon(transaction.category),
          isIncome: transaction.isIncome,
          onTap: () {
            // Handle tap - edit transaction, show details, etc.
            print('Tapped transaction: ${transaction.title}');
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'utilities':
        return Icons.bolt;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.favorite;
      case 'housing':
        return Icons.home;
      case 'salary':
        return Icons.work;
      case 'freelance':
        return Icons.code;
      case 'investment':
        return Icons.trending_up;
      case 'gift':
        return Icons.card_giftcard;
      default:
        return Icons.more_horiz;
    }
  }
}

/// Example: Single bubble preview
class BubblePreviewExample extends StatelessWidget {
  const BubblePreviewExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('WhatsApp Bubble Preview'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          // Expense bubble (right side)
          WhatsAppStyleBubble(
            title: 'Grocery Shopping',
            amount: 45.50,
            categoryIcon: Icons.shopping_cart,
            isIncome: false,
          ),
          
          SizedBox(height: 8),
          
          // Income bubble (left side)
          WhatsAppStyleBubble(
            title: 'Freelance Project',
            amount: 1250.00,
            categoryIcon: Icons.code,
            isIncome: true,
          ),
          
          SizedBox(height: 8),
          
          // Expense bubble
          WhatsAppStyleBubble(
            title: 'Coffee & Breakfast',
            amount: 12.75,
            categoryIcon: Icons.restaurant,
            isIncome: false,
          ),
          
          SizedBox(height: 8),
          
          // Income bubble
          WhatsAppStyleBubble(
            title: 'Monthly Salary',
            amount: 3500.00,
            categoryIcon: Icons.work,
            isIncome: true,
          ),
        ],
      ),
    );
  }
}

/// Example: Integration with existing transaction screen
/// 
/// To integrate into your home page or transaction screen:
/// 
/// 1. Import the widget:
///    import '../widgets/whatsapp_bubble.dart';
/// 
/// 2. Replace your current transaction list item with:
///    WhatsAppStyleBubble(
///      title: transaction.title,
///      amount: transaction.amount,
///      categoryIcon: _getCategoryIcon(transaction.category),
///      isIncome: transaction.isIncome,
///      onTap: () => _editTransaction(transaction),
///    )
/// 
/// 3. For the floating overlay bubble on homescreen, you can use
///    a smaller version with just the amount:
///    
///    Container(
///      decoration: BoxDecoration(
///        shape: BoxShape.circle,
///        gradient: LinearGradient(
///          colors: [Color(0xFF2B7A91), Color(0xFF1F5F6F)],
///        ),
///        boxShadow: [
///          BoxShadow(
///            color: Color(0xFF2B7A91).withOpacity(0.3),
///            blurRadius: 12,
///            spreadRadius: 2,
///          ),
///        ],
///      ),
///      child: Icon(Icons.add_circle_outline, color: Colors.white, size: 48),
///    )
