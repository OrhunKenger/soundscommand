import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
FlutterLocalNotificationsPlugin();
final FlutterTts tts = FlutterTts();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
  const InitializationSettings initSettings =
  InitializationSettings(android: androidInit, iOS: iosInit);

  await notificationsPlugin.initialize(initSettings);
  await tts.setLanguage("tr-TR");
  await tts.setSpeechRate(0.9);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _keepListening = false;

  String myIban = "TR91 0001 5001 5800 7323 7086 00";
  String myName = "Orhun Sina Kenger";

  // Tetikleyici komutlar (daha doğal ifadeler)
  final List<String> triggerCommands = [
    "ibanımı söyle",
    "iban lazım",
    "ibanı gönder",
    "ibanı oku",
    "bana ibanı söyle",
    "ibanı ver",
    "hesap numaran ne",
    "iban bilgisini paylaş",
    "iban istiyorum",
    "ibanı atar mısın",
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _isListening = true;
        _keepListening = true;
      });
      _speech.listen(
        onResult: (val) {
          String command = val.recognizedWords.toLowerCase();
          for (var trigger in triggerCommands) {
            if (command.contains(trigger)) {
              _showNotificationAndSpeak();
              break;
            }
          }
        },
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      );

      _speech.statusListener = (status) {
        if (_keepListening && status == "notListening") {
          _startListening();
        }
      };
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
      _keepListening = false;
    });
  }

  Future<void> _showNotificationAndSpeak() async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails('channel_id', 'channel_name',
          importance: Importance.max, priority: Priority.high),
      iOS: DarwinNotificationDetails(),
    );
    await notificationsPlugin.show(
      0,
      'IBAN Bilgisi',
      '$myName\nIBAN: $myIban',
      details,
    );
    await tts.speak("İban ekrana düştü!");
  }

  void _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          name: myName,
          iban: myIban,
        ),
      ),
    );
    if (result != null && result is Map<String, String>) {
      setState(() {
        myName = result['name'] ?? myName;
        myIban = result['iban'] ?? myIban;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('IBAN Listener'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSettings,
            ),
          ],
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: _isListening ? _stopListening : _startListening,
            child: Text(_isListening ? 'Dinlemeyi Durdur' : 'Dinlemeye Başla'),
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final String name;
  final String iban;
  const SettingsPage({super.key, required this.name, required this.iban});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _nameController;
  late TextEditingController _ibanController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _ibanController = TextEditingController(text: widget.iban);
  }

  void _save() {
    Navigator.pop(context, {
      'name': _nameController.text,
      'iban': _ibanController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "İsim"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ibanController,
              decoration: const InputDecoration(labelText: "IBAN"),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              child: const Text("Kaydet"),
            )
          ],
        ),
      ),
    );
  }
}
