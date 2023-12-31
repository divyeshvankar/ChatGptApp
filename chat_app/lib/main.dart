import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const ChatApp(),
    ),
  );
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
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
  bool _isMessageEmpty = true;
  bool _isLoading = false; // Added variable for loading state

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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat GPT 2.0'),
        actions: [
          IconButton(
            onPressed: () {
              themeProvider.toggleTheme();
            },
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
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
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        chatMessage.message,
                        style: TextStyle(
                          color: chatMessage.sender == 'user'
                              ? Colors.blue
                              : themeProvider.isDarkMode
                                  ? Colors.white
                                  : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
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
                  onPressed: _isLoading
                      ? null
                      : _isMessageEmpty
                          ? null
                          : () async {
                              final message = _messageController.text.trim();
                              if (message.isNotEmpty) {
                                setState(() {
                                  _isLoading = true; // Set loading state to true
                                });
                                await _sendMessage(message);
                                _messageController.clear();
                                setState(() {
                                  _isLoading = false; // Set loading state to false
                                });
                              }
                            },
                  icon: _isLoading
                      ? CircularProgressIndicator() // Show loading spinner if _isLoading is true
                      : Icon(Icons.send),
                  color: _isMessageEmpty ? Colors.grey : Colors.blue,
                ),
              ),
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
              cursorColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatApp extends StatelessWidget {
  const ChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Chat GPT 2.0',
      theme: themeProvider.isDarkMode ? darkTheme : lightTheme,
      home: const ChatScreen(),
    );
  }
}

final lightTheme = ThemeData(
  primarySwatch: Colors.blue,
  primaryColor: Colors.white,
  brightness: Brightness.light,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  fontFamily: 'Arial',
);

final darkTheme = ThemeData(
  primarySwatch: Colors.blue,
  primaryColor: Colors.blueGrey[900],
  brightness: Brightness.dark,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  fontFamily: 'Arial',
);

