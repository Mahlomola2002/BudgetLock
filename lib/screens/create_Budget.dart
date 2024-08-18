import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class Budget {
  final String category;
  final String emoji;
  final double amount;

  Budget({required this.category, required this.emoji, required this.amount});

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      category: json['category_name'],
      emoji: json['emoji'],
      amount: json['amount'].toDouble(),
    );
  }
}

// ignore: must_be_immutable
class CreateGoalScreen extends StatefulWidget {
  final List<Budget> budgets;
  double amount;

  CreateGoalScreen({required this.budgets, required this.amount});

  @override
  _CreateGoalScreenState createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final TextEditingController _goalNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedEmoji = '🎯'; // Default emoji

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Goal'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Categorize"),
            TextField(
              controller: _goalNameController,
              decoration: InputDecoration(
                hintText: 'Name of your expense',
                border: UnderlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                hintText: 'Enter Amount',
                border: UnderlineInputBorder(),
                prefixText: 'R',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            InkWell(
              onTap: () {
                // Show emoji picker
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return EmojiPicker(
                      onEmojiSelected: (category, emoji) {
                        setState(() {
                          _selectedEmoji = emoji.emoji;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pick an emoji'),
                    Text(_selectedEmoji, style: TextStyle(fontSize: 24)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: Text('Create'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  if (_goalNameController.text.isNotEmpty &&
                      _amountController.text.isNotEmpty) {
                    double enteredAmount = double.parse(_amountController.text);

                    if (enteredAmount <= widget.amount) {
                      Budget newBudget = Budget(
                        emoji: _selectedEmoji,
                        category: _goalNameController.text,
                        amount: enteredAmount,
                      );

                      widget.budgets.add(newBudget);

                      // Pass the reduced amount back to HomeScreen
                      Navigator.pop(context, widget.amount - enteredAmount);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Entered amount exceeds available balance')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Please fill all required fields')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
