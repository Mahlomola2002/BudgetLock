import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class TransactionList extends StatefulWidget {
  @override
  _TransactionListState createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  List<dynamic> transactions = [];
  double availableBalance = 0.0;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    final response =
        await http.get(Uri.parse('http://localhost:8020/transactions/'));
    if (response.statusCode == 200) {
      setState(() {
        transactions = json.decode(response.body);
        calculateBalance();
      });
    } else {
      print('Failed to load transactions');
    }
  }

  void calculateBalance() {
    availableBalance = transactions.fold(
        0.0, (sum, transaction) => sum + transaction['amount']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            color: Color(0xFF00008B),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                SizedBox(height: 10),
                Text(
                  'R${availableBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('All',
                        style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline)),
                    Text('Money In', style: TextStyle(color: Colors.white)),
                    Text('Money Out', style: TextStyle(color: Colors.white)),
                    Text('Track', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return ListTile(
                  title: Text(transaction['category_name']),
                  subtitle: Text(
                    '${DateFormat('d MMM yyyy').format(DateTime.parse(transaction['transaction_date']))} - ${transaction['customer_name']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: Text(
                    'R${transaction['amount'].toStringAsFixed(2)}',
                    style: TextStyle(
                      color:
                          transaction['amount'] < 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
