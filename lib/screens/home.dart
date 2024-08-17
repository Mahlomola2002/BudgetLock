import 'package:budget_lock/screens/create_Budget.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  double _balance = 1000.00; // Initial balance
  List<Budget> _budgets = [];

  @override
  bool get wantKeepAlive => true; // Ensures the state is kept alive

  void _updateBalance(double amount) {
    setState(() {
      _balance += amount; // Update balance
    });
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
        print('Clicked on ${budget.category}');
        // You can add navigation or show a dialog here
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
                color: Colors.green,
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
      backgroundColor: Colors.blueAccent,
      appBar: AppBar(
        backgroundColor: Colors.blue,
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
                  color: Colors.black,
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
          decoration: BoxDecoration(
            color: Color.fromARGB(
                255, 240, 247, 239), // Set the background color to black
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
            ),
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
                        color: Colors.black26,
                        blurRadius: 10.0,
                        spreadRadius: 2.0,
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
              SizedBox(height: 15),
              // Services Component
              Padding(
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
                        _buildServiceItem(
                            Icons.lightbulb_outline, 'Pay Bill', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
              // Budget Component
              Padding(
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
                        .map((budget) => _buildClickableTransactionItem(budget))
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
                      },
                      child: Text('Add More Categories'),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue,
                        onPrimary: Colors.white,
                      ),
                    ),
                  ],
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
