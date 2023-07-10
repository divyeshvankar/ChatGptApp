import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.blueGrey[900], // Set the primary color
        brightness: Brightness.dark, // Set the theme to use a dark background
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatMessage {
  final String sender;
  final String message;

  ChatMessage({
    required this.sender,
    required this.message,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  StreamSubscription<String>? _responseSubscription;

  Future<void> _sendMessage(String message) async {
    try {
      final url = Uri.parse('http://192.168.201.182:8000/chat');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "message": message,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;

        // Check if the response is a valid JSON string
        if (responseBody != null && responseBody.isNotEmpty) {
          final jsonData = jsonDecode(responseBody);

          // Handle the response based on the expected format
          if (jsonData['response'] != null && jsonData['response'] is List) {
            final responseList = jsonData['response'];

            setState(() {
              for (final item in responseList) {
                final role = item['role'];
                final content = item['content'];
                _messages.add(ChatMessage(sender: role, message: content));
              }
            });
          } else {
            print('Invalid response format: $responseBody');
          }
        } else {
          print('Empty response received');
        }
      } else {
        print('Failed to send message. StatusCode: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  void dispose() {
    _responseSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat App')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Reverse the list to show new messages at the bottom
              itemCount: _messages.length,
              itemBuilder: (ctx, index) {
                final chatMessage = _messages.reversed.toList()[index];
                return ListTile(
                  title: Align(
                    alignment: chatMessage.sender == 'user'
                        ? Alignment.centerRight // Align user's messages to the right
                        : Alignment.centerLeft, // Align assistant's replies to the left
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: chatMessage.sender == 'user'
                            ? Colors.blueAccent // Color for user's message
                            : const Color.fromARGB(255, 1, 78, 41), // Color for assistant's reply
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        chatMessage.message,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () {
                    final message = _messageController.text.trim();
                    if (message.isNotEmpty) {
                      _sendMessage(message);
                      _messageController.clear();
                    }
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
