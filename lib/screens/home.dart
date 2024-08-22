// ignore_for_file: prefer_const_constructors, prefer_final_fields, library_private_types_in_public_api, unused_element, prefer_const_literals_to_create_immutables

import 'dart:convert';

import 'package:budget_lock/screens/Payment.dart';
import 'package:budget_lock/screens/create_Budget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  double _balance = 1000.00; // Initial balance
  List<Budget> _budgets = [];
  bool _isFetchingBudgets = false;

  @override
  bool get wantKeepAlive => true; // Ensures the state is kept alive

  void _updateBalance(double amount) {
    setState(() {
      _balance += amount; // Update balance
    });
  }

  @override
  void initState() {
    super.initState();

    _fetchBudgets();
  }

  Future<void> _addBudget(Budget budget) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/budgets/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'category_name': budget.category,
          'amount': budget.amount,
          'emoji': budget.emoji,
          'deadline': DateTime.now().toIso8601String(),
          'reminder': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        // Fetch the updated budgets after adding a new one
        await _fetchBudgets();
      } else {
        throw Exception('Failed to add budget');
      }
    } catch (e) {
      print('Error adding budget: $e');
    }
  }

  Future<void> _fetchBudgets() async {
    try {
      _isFetchingBudgets = true;
      final response =
          await http.get(Uri.parse('http://localhost:8000/budgets/'));
      if (response.statusCode == 200) {
        final List<dynamic> budgetsJson = json.decode(response.body);
        setState(() {
          _budgets = budgetsJson.map((json) => Budget.fromJson(json)).toList();
        });
      } else {
        throw Exception('Failed to load budgets');
      }
    } catch (e) {
      print('Error fetching budgets: $e');
    } finally {
      _isFetchingBudgets = false;
    }
  }

  Future<void> _deleteBudget(String category) async {
    final response =
        await http.delete(Uri.parse('http://localhost:8000/budgets/$category'));

    if (response.statusCode == 200) {
      _fetchBudgets();
    } else {
      throw Exception('Failed to delete budget');
    }
  }

  Widget _buildServiceItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildClickableTransactionItem(Budget budget) {
    return GestureDetector(
      onTap: () {
        // Handle category click
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentMethodsPage(),
          ),
        );
        // You can add navigation or show a dialog here
      },
      onLongPress: () {
        _deleteBudget(budget.category);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(budget.emoji, style: TextStyle(fontSize: 24)),
                SizedBox(width: 10),
                Text(budget.category, style: TextStyle(fontSize: 16)),
              ],
            ),
            Text(
              'R${budget.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                color: const Color.fromARGB(255, 55, 73, 56),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(
        context); // Necessary to call super.build() when using AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 16, 82, 3),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 3, 66, 3),
        title: Text(
          'BudgetLock',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: const Color.fromARGB(216, 37, 37, 37),
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                // Navigate to ProfileScreen
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                // Navigate to SettingsScreen
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sign Out'),
              onTap: () {
                // Handle sign out action
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: const Color.fromARGB(
                255, 3, 44, 19), // Set the background color to black

            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20.0,
                spreadRadius: 10.0,
                offset: Offset(5.0, 5.0),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(height: 15),
              // Available Balance Container
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 227, 238, 227),
                    borderRadius: BorderRadius.circular(30.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(66, 248, 253, 252),
                        blurRadius: 20.0,
                        spreadRadius: 5.0,
                        offset: Offset(5.0, 5.0),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Available Balance: ',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 15,
                          )),
                      Text(
                        'R${_balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Services Component
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 227, 238, 227),
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(66, 248, 253, 252),
                      blurRadius: 20.0,
                      spreadRadius: 5.0,
                      offset: Offset(5.0, 5.0),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Services',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildServiceItem(
                              Icons.compare_arrows, 'Transfer', Colors.green),
                          _buildServiceItem(Icons.add, 'Deposit', Colors.pink),
                          _buildServiceItem(
                              Icons.payment, 'Make Payment', Colors.purple),
                          _buildServiceItem(Icons.lightbulb_outline, 'Pay Bill',
                              Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 60),
              // Budget Component
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 227, 238, 227),
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(66, 248, 253, 252),
                      blurRadius: 20.0,
                      spreadRadius: 5.0,
                      offset: Offset(5.0, 5.0),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Budget',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      ..._budgets
                          .map((budget) =>
                              _buildClickableTransactionItem(budget))
                          .toList(),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateGoalScreen(
                                  budgets: _budgets, amount: _balance),
                            ),
                          );

                          if (result != null && result is double) {
                            _updateBalance(result -
                                _balance); // Update the balance with the new value
                          }
                          //_addBudget(_budgets[_budgets.length - 1]);
                        },
                        child: Text('Add More Categories'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              const Color.fromARGB(255, 5, 133, 54),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
