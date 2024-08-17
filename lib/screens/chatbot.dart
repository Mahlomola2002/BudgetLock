import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatBotScreen extends StatefulWidget {
  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  late WebSocketChannel channel;
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  String _currentBotResponse = '';
  bool _isWaitingForResponse = false;

  @override
  void initState() {
    super.initState();
    connectWebSocket();
  }

  void connectWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8000/ws/chat'),
    );

    channel.stream.listen((message) {
      final data = jsonDecode(message);
      setState(() {
        if (data['finished'] == false) {
          _currentBotResponse += data['text'];

          // Update the last bot message in the list or add a new one if none exists
          if (_messages.isNotEmpty && !_messages.first.isUser) {
            _messages.first.text = _currentBotResponse;
          } else {
            _messages.insert(
                0, ChatMessage(text: _currentBotResponse, isUser: false));
          }
        } else {
          _isWaitingForResponse = false;
          _currentBotResponse = '';
        }
      });
    }, onError: (error) {
      print('WebSocket Error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    ChatMessage message = ChatMessage(text: text, isUser: true);
    setState(() {
      _messages.insert(0, message);
      _currentBotResponse = '';
      _isWaitingForResponse = true;
    });
    channel.sink.add(text); // Send the message as a string
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/bot_avatar.png'),
              backgroundColor: Colors.white,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Twinkle Bot', style: TextStyle(fontSize: 16)),
                Text('Online',
                    style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) => _messages[index],
            ),
          ),
          Divider(height: 1.0, color: Colors.grey),
          Container(
            color: Colors.black,
            child: _buildTextComposer(),
          ),
          if (_isWaitingForResponse)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration(
                hintText: "Ask me something...",
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[800],
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(width: 8.0),
          ElevatedButton(
            onPressed: () => _handleSubmitted(_textController.text),
            style: ElevatedButton.styleFrom(
              primary: Colors.purpleAccent, // Updated color to match the theme
              shape: CircleBorder(),
              padding: EdgeInsets.all(12.0),
            ),
            child: Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundImage: AssetImage('assets/bot_avatar.png'),
              backgroundColor: Colors.transparent,
            ),
            SizedBox(width: 8.0),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Text('Twinkle Bot',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                Container(
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.purpleAccent : Colors.grey[850],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Text(
                    text,
                    style:
                        TextStyle(color: isUser ? Colors.white : Colors.white),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8.0),
            CircleAvatar(
              child: Text('U', style: TextStyle(color: Colors.black)),
              backgroundColor: Colors.white, // Updated user avatar style
            ),
          ],
        ],
      ),
    );
  }
}
