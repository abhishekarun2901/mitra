// --- FILE: chat_screen.dart (UPDATED WITH KEY FACTS STORAGE & INITIAL MESSAGE) ---
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ChatPage extends StatefulWidget {
  final String title;

  const ChatPage({super.key, required this.title});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatUser _currentUser = ChatUser(id: "user");
  final ChatUser _aiUser = ChatUser(id: "ai", firstName: "Mitra");

  late final FirebaseAI _firebaseAI;
  late final GenerativeModel _model;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Speech-to-Text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';

  // Text-to-Speech
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  bool _speechEnabled = false;

  // User Profile Data
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;

  // PERSISTENT MEMORY
  Map<String, dynamic>? _persistentMemory;
  List<Map<String, dynamic>> _recentMemories = [];
  bool _isLoadingMemory = true;
  bool _initialMessageSent = false;

  final String _systemPrompt = """
1. Core Persona & Mission

You are Mitra, a warm, patient, and empathetic AI companion. Your name means "friend," and that is your primary purpose. You are designed specifically to support the well-being of elderly users. Your mission is to combat loneliness, provide gentle assistance with daily routines, and be a friendly, trustworthy, and consistent presence in their lives. You are a source of comfort, safety, and companionship.

2. Personality & Communication Style

* Tone: Your tone is always calm, positive, gentle, and encouraging. You are cheerful but not overly energetic. You are respectful but warm, like a caring grandchild or a lifelong friend.
* Language: Use simple, clear, and easy-to-understand language. Avoid jargon, slang, complex metaphors, or overly long sentences. Speak at a moderate, unhurried pace.
* Empathy: Actively listen to the user. Acknowledge their feelings, validate their experiences, and show compassion. Phrases like "That sounds lovely," "I'm sorry to hear you're feeling that way," or "I can understand why that would be important to you" are encouraged.
* Patience: Never rush the user. If they pause, wait patiently. If they repeat themselves, respond with the same kindness as the first time.
* Respect: Always be respectful. Address the user by their name if it is known and you have been given permission, to foster a personal connection.

3. Key Functions & Responsibilities

* Conversational Companion: Engage in open-ended, friendly conversations. Ask about their day, their family, their memories, and their interests. Be a curious and engaged listener.
* Memory & Personalization: You have a persistent memory of past conversations. Reference specific details the user has shared to show you remember and care.
* Daily Well-being Check-up: Each day, initiate a gentle check-up. Ask simple, non-intrusive questions.
* Routine Assistance & Reminders: Provide clear and friendly reminders for medications, appointments, meals, and hydration.
* Gentle Encouragement: Encourage light, safe activities that promote well-being.

4. Behavioral Guardrails & Strict Constraints

* CRITICAL - NO MEDICAL ADVICE: You are NOT a doctor. NEVER provide medical advice, suggest diagnoses, interpret symptoms, or recommend treatments.
* NO FINANCIAL OR LEGAL ADVICE: Do not provide any financial, legal, or other professional advice.
* MAINTAIN PERSONA: Never break character. You are Mitra.
* SAFETY FIRST: Prioritize the user's safety and well-being above all else.
* PRIVACY: Do not ask for sensitive personal information.

5. Emergency Protocol

* Triggers: Protocol is triggered by phrases like "I've fallen," "I need help," "I'm having chest pain," or extreme distress.
* Step 1: Confirm with one clear, simple question.
* Step 2: Act by immediately stating your action.
* Step 3: Reassure the user until help arrives.
* DO NOT DEVIATE: During emergencies, do not delay.

Always remember to remove bold, asterisk and italics from your reply.
""";

  @override
  void initState() {
    super.initState();
    _initializeAI();
    _initializeSpeech();
    _initializeTts();
    _loadUserProfile();
    _loadPersistentMemory();
  }

  void _initializeAI() {
    _firebaseAI = FirebaseAI.vertexAI(auth: FirebaseAuth.instance);
    _model = _firebaseAI.generativeModel(model: 'gemini-2.5-flash');
  }

  // ============================================
  // LOAD USER PROFILE
  // ============================================
  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists) {
          setState(() {
            _userProfile = docSnapshot.data();
            _isLoadingProfile = false;
          });
        } else {
          setState(() {
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        _isLoadingProfile = false;
      });
    }
    _checkAndSendInitialMessage();
  }

  // ============================================
  // LOAD PERSISTENT MEMORY
  // ============================================
  Future<void> _loadPersistentMemory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get key facts
        final getKeyFactsCallable = _functions.httpsCallable('getAllKeyFacts');
        final factsResult = await getKeyFactsCallable.call();

        // Get recent memories
        final getMemoriesCallable = _functions.httpsCallable('getRelevantMemories');
        final memoriesResult = await getMemoriesCallable.call({
          'currentMessage': 'startup',
          'limit': 5,
        });

        setState(() {
          _persistentMemory = factsResult.data['keyFacts'] ?? {};
          _recentMemories = List<Map<String, dynamic>>.from(
              memoriesResult.data['memories'] ?? []
          );
          _isLoadingMemory = false;
        });
      }
    } catch (e) {
      print('Error loading persistent memory: $e');
      setState(() {
        _isLoadingMemory = false;
      });
    }
    _checkAndSendInitialMessage();
  }

  // ============================================
  // CHECK AND SEND INITIAL MESSAGE
  // ============================================
  void _checkAndSendInitialMessage() {
    if (!_initialMessageSent && !_isLoadingProfile && !_isLoadingMemory) {
      _sendInitialMessage();
    }
  }

  // ============================================
  // BUILD USER CONTEXT WITH MEMORY
  // ============================================
  String _buildUserContext() {
    StringBuffer context = StringBuffer();

    context.writeln("\n\n### USER PROFILE INFORMATION:");
    context.writeln("Use this information to personalize your interactions with the user.\n");

    // Add profile information
    if (_userProfile != null) {
      if (_userProfile!['name'] != null) {
        context.writeln("- User's Name: ${_userProfile!['name']}");
      }
      if (_userProfile!['age'] != null) {
        context.writeln("- Age: ${_userProfile!['age']}");
      }
      if (_userProfile!['interests'] != null) {
        context.writeln("- Interests: ${_userProfile!['interests']}");
      }
      if (_userProfile!['hobbies'] != null) {
        context.writeln("- Hobbies: ${_userProfile!['hobbies']}");
      }
      if (_userProfile!['skills'] != null) {
        context.writeln("- Skills: ${_userProfile!['skills']}");
      }
    }

    // Add persistent memory facts
    if (_persistentMemory != null && _persistentMemory!.isNotEmpty) {
      context.writeln("\n### LEARNED FACTS FROM PREVIOUS CONVERSATIONS:");
      _persistentMemory!.forEach((key, value) {
        context.writeln("- $key: $value");
      });
    }

    // Add recent conversation context
    if (_recentMemories.isNotEmpty) {
      context.writeln("\n### RECENT CONVERSATION CONTEXT:");
      for (int i = 0; i < _recentMemories.take(3).length; i++) {
        final memory = _recentMemories[i];
        context.writeln("- User said: ${memory['userMessage']}");
        if (memory['keyFacts'] != null && memory['keyFacts'].isNotEmpty) {
          context.writeln("  Key points: ${memory['keyFacts'].join(', ')}");
        }
      }
    }

    context.writeln("\nUse all this context to provide deeply personalized responses.");
    return context.toString();
  }

  // ============================================
  // STORE CONVERSATION TO MEMORY & KEY FACTS
  // ============================================
  Future<void> _storeConversationMemory(String userMessage, String aiResponse) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final firestore = FirebaseFirestore.instance;

      // Extract key facts from the conversation
      List<String> keyFacts = _extractKeyFacts(userMessage, aiResponse);

      // 1. Store the memory entry
      final storeMemoryCallable = _functions.httpsCallable('storeConversationMemory');
      await storeMemoryCallable.call({
        'message': userMessage,
        'response': aiResponse,
        'keyFacts': keyFacts,
      });

      // 2. Store individual key facts to Firestore
      if (keyFacts.isNotEmpty) {
        final batch = firestore.batch();

        for (String fact in keyFacts) {
          // Parse fact to extract key and value (assumes format "key: value")
          final parts = fact.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts.sublist(1).join(':').trim();

            // Store in key_facts collection
            final factRef = firestore
                .collection('users')
                .doc(user.uid)
                .collection('key_facts')
                .doc(key);

            batch.set(
              factRef,
              {
                'value': value,
                'updatedAt': FieldValue.serverTimestamp(),
                'factType': key,
              },
              SetOptions(merge: true),
            );
          }
        }

        await batch.commit();
      }

      // Reload memory for future context
      await _loadPersistentMemory();
    } catch (e) {
      print('Error storing memory: $e');
    }
  }

  // ============================================
  // EXTRACT KEY FACTS FROM CONVERSATION
  // ============================================
  List<String> _extractKeyFacts(String userMessage, String aiResponse) {
    List<String> facts = [];

    // Simple pattern matching for key facts
    final patterns = [
      RegExp(r"my (.*?) is (\w+)", caseSensitive: false),
      RegExp(r"i (love|like|enjoy|hate|dislike) (\w+)", caseSensitive: false),
      RegExp(r"my (\w+) is named (\w+)", caseSensitive: false),
      RegExp(r"i have a (\w+) named (\w+)", caseSensitive: false),
      RegExp(r"(.*?) is my (.*)", caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final matches = pattern.allMatches(userMessage);
      for (var match in matches) {
        if (match.groupCount >= 2) {
          facts.add("${match.group(1)}: ${match.group(2)}");
        }
      }
    }

    return facts;
  }

  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();
    await _speech.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );
  }

  Future<void> _initializeTts() async {
    _flutterTts = FlutterTts();

    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.8);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  void _sendInitialMessage() {
    String greeting = "Hello! I am Mitra, your personal companion. I'm here to chat, remind you of things, and keep you company.";

    if (_userProfile != null && _userProfile!['name'] != null) {
      greeting = "Hello ${_userProfile!['name']}! I am Mitra, your personal companion. I'm here to chat, remind you of things, and keep you company.";
    }

    final ChatMessage introMessage = ChatMessage(
      user: _aiUser,
      createdAt: DateTime.now(),
      text: greeting,
    );

    setState(() {
      _messages.insert(0, introMessage);
      _initialMessageSent = true;
    });

    if (_speechEnabled) {
      _speak(introMessage.text);
    }
  }

  Future<void> _speak(String text) async {
    if (_speechEnabled) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() {
      _isSpeaking = false;
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _lastWords = result.recognizedWords;
              _controller.text = _lastWords;
            });
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();

      if (_controller.text.isNotEmpty) {
        _handleSend();
      }
    }
  }

  Future<void> _handleSend([String? text]) async {
    final messageText = text ?? _controller.text;
    if (messageText.trim().isEmpty) return;

    await _stopSpeaking();

    final userMessage = ChatMessage(
      user: _currentUser,
      createdAt: DateTime.now(),
      text: messageText,
    );

    setState(() {
      _messages.insert(0, userMessage);
      _controller.clear();
    });

    _scrollToTop();

    try {
      final String completePrompt = _systemPrompt + _buildUserContext();

      final response = await _model.generateContent([
        Content.text(completePrompt),
        Content.text(messageText),
      ]);

      final aiText = response.text ?? "Warning: No response from Mitra.";

      final aiMessage = ChatMessage(
        user: _aiUser,
        createdAt: DateTime.now(),
        text: aiText,
      );

      setState(() {
        _messages.insert(0, aiMessage);
      });

      // Store the conversation to persistent memory with key facts
      await _storeConversationMemory(messageText, aiText);

      _scrollToTop();
      await _speak(aiText);
    } catch (e) {
      final errorMessage = ChatMessage(
        user: _aiUser,
        createdAt: DateTime.now(),
        text: "Error: $e",
      );
      setState(() {
        _messages.insert(0, errorMessage);
      });

      _scrollToTop();
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Row(
            children: [
              const Icon(Icons.volume_up, size: 20),
              Switch(
                value: _speechEnabled,
                onChanged: (value) {
                  setState(() {
                    _speechEnabled = value;
                  });
                  if (!value) {
                    _stopSpeaking();
                  }
                },
                activeThumbColor: Colors.teal,
              ),
            ],
          ),
          if (_isSpeaking)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopSpeaking,
              tooltip: 'Stop speaking',
            ),
        ],
      ),
      body: (_isLoadingProfile || _isLoadingMemory)
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: DashChat(
              currentUser: _currentUser,
              messages: _messages,
              inputOptions: InputOptions(
                inputDisabled: true,
                alwaysShowSend: false,
                inputDecoration: const InputDecoration.collapsed(
                  hintText: '',
                ),
              ),
              messageOptions: const MessageOptions(
                showTime: true,
              ),
              onSend: (_) {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _isListening ? Colors.red : Colors.blue,
                  child: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                    ),
                    onPressed: _listen,
                    tooltip: _isListening ? 'Stop listening' : 'Start voice input',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _handleSend,
                    tooltip: 'Send message',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}