import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsPage extends StatefulWidget {
  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final Map<String, double> spendingByCategory = {
    'Shopping': 1000.0,
    'Travel': 500.0,
    'Food': 300.0,
    'Entertainment': 200.0,
    'Utilities': 150.0,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reports 2'),
            SizedBox(height: 16.0),
            Container(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Transaction Summary'),
                    SizedBox(height: 16.0),
                    PieChart(
                      PieChartData(
                        sections: spendingByCategory.entries
                            .map((entry) => PieChartSectionData(
                                  value: entry.value,
                                  title: entry.key,
                                  color: _getColorForCategory(entry.key),
                                ))
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Text('Gateways'),
                    SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: _GatewayCard(
                            icon: Icons.apple,
                            name: 'Apple Pay',
                            amount: 1475.0,
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: _GatewayCard(
                            icon: Icons.payment,
                            name: 'Wechat Pay',
                            amount: 1475.0,
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: _GatewayCard(
                            icon: Icons.credit_card,
                            name: 'Visa',
                            amount: 1475.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    Text('Transactions'),
                    SizedBox(height: 16.0),
                    _TransactionCard(
                      date: 'Feb 28, Monday',
                      name: 'ABC company',
                      amount: 35.39,
                    ),
                    _TransactionCard(
                      date: 'Feb 28, Monday',
                      name: 'ABC company',
                      amount: 847.57,
                    ),
                    _TransactionCard(
                      date: 'Feb 28, Monday',
                      name: 'ABC company',
                      amount: 57.61,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Shopping':
        return Colors.blue;
      case 'Travel':
        return Colors.green;
      case 'Food':
        return Colors.orange;
      case 'Entertainment':
        return Colors.purple;
      case 'Utilities':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _GatewayCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final double amount;

  _GatewayCard({
    required this.icon,
    required this.name,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            SizedBox(height: 8.0),
            Text(name),
            Spacer(),
            Text('\$${amount.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final String date;
  final String name;
  final double amount;

  _TransactionCard({
    required this.date,
    required this.name,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date),
                  SizedBox(height: 8.0),
                  Text(name),
                ],
              ),
            ),
            Text('\$${amount.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}
