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
      title: 'Chat GPT 2.0',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.white,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Arial', // Change the font to Arial
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
  bool _isLoading = false;
  bool _isMessageEmpty = true;

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

        if (responseBody != null && responseBody.isNotEmpty) {
          final jsonData = jsonDecode(responseBody);

          if (jsonData['response'] != null && jsonData['response'] is List) {
            final responseList = jsonData['response'];

            setState(() {
              for (final item in responseList) {
                final role = item['role'];
                final content = item['content'];
                _messages.add(ChatMessage(sender: role, message: content));
              }
              _isLoading = false;
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
      appBar: AppBar(title: const Text('Chat GPT 2.0')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  reverse: true,
                  itemCount: _messages.length,
                  itemBuilder: (ctx, index) {
                    final chatMessage = _messages.reversed.toList()[index];
                    return ListTile(
                      title: Align(
                        alignment: chatMessage.sender == 'user'
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: chatMessage.sender == 'user'
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            chatMessage.message,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (_isLoading)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.all(16.0),
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _messageController,
              onChanged: (value) {
                setState(() {
                  _isMessageEmpty = value.trim().isEmpty;
                });
              },
              decoration: InputDecoration(
                labelText: 'Send a message',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: IconButton(
                  onPressed: _isMessageEmpty ? null : () {
                    final message = _messageController.text.trim();
                    if (message.isNotEmpty) {
                      setState(() {
                        _isLoading = true;
                      });
                      _sendMessage(message);
                      _messageController.clear();
                    }
                  },
                  icon: Icon(Icons.send),
                  color: _isMessageEmpty ? Colors.grey : Colors.blue,
                ),
              ),
              style: const TextStyle(color: Colors.black),
              cursorColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
