import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'firebase_options.dart';
import 'dart:developer';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const SmartHomeScreen(),
    );
  }
}

class SmartHomeScreen extends StatefulWidget {
  const SmartHomeScreen({super.key});

  @override
  State<SmartHomeScreen> createState() => _SmartHomeScreenState();
}

class _SmartHomeScreenState extends State<SmartHomeScreen> {
  // Kết nối với Firebase Realtime Database (có databaseURL)
  final DatabaseReference _database =
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://smart-944cb-default-rtdb.asia-southeast1.firebasedatabase.app/',
      ).ref();

  // Trạng thái của các thiết bị
  bool _lightSwitch = false;
  bool _fanSwitch = false;
  bool _acSwitch = false;

  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _loadLedState();
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize();
      print('SpeechToText initialized: $_speechEnabled');
    } catch (e) {
      print('SpeechToText init error: $e');
    }
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    if (_speechEnabled) {
      await _speechToText.listen(onResult: _onSpeechResult, localeId: 'vi_VN');
      setState(() {});
    } else {
      print('SpeechToText chưa được khởi tạo!');
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    if (_lastWords.toLowerCase().contains("bật đèn")) {
      setState(() {
        _lightSwitch = true;
      });
      _updateLedState(true);
    } else if (_lastWords.toLowerCase().contains("tắt đèn")) {
      setState(() {
        _lightSwitch = false;
      });
      _updateLedState(false);
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    print('SpeechRecognitionResult: ${result.recognizedWords}');
    setState(() {
      _lastWords = result.recognizedWords;
    });
    log(result.recognizedWords);
  }

  // Đọc trạng thái LED từ Firebase
  void _loadLedState() {
    _database.child('esp32/ledState').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        setState(() {
          _lightSwitch = data == 1;
        });
      }
    });
  }

  // Cập nhật trạng thái LED lên Firebase
  Future<void> _updateLedState(bool value) async {
    try {
      await _database.child('esp32/ledState').set(value ? 1 : 0);
      log('Đã gửi lên Firebase: ledState = ${value ? 1 : 0}');
    } catch (e) {
      log('Lỗi khi cập nhật lên Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple.shade900,
                  Colors.deepPurple.shade700,
                  Colors.purple.shade600,
                  Colors.pink.shade500,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header với icon và title
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.shade400,
                                Colors.orange.shade600,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.home_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nhà Thông Minh',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Điều khiển thiết bị của bạn',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hiển thị trạng thái micro và kết quả nhận dạng
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        Text(
                          _speechEnabled
                              ? (_speechToText.isListening
                                  ? 'Đang lắng nghe...'
                                  : 'Micro đã sẵn sàng')
                              : 'Micro chưa được khởi tạo hoặc chưa cấp quyền!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bạn nói: "$_lastWords"',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Danh sách thiết bị
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        const SizedBox(height: 20),

                        // Thiết bị 1: Đèn
                        _buildModernDeviceCard(
                          icon: Icons.lightbulb_rounded,
                          title: 'Đèn Phòng',
                          subtitle: 'Phòng khách',
                          value: _lightSwitch,
                          onChanged: (value) {
                            setState(() {
                              _lightSwitch = value;
                            });
                            _updateLedState(value);
                          },
                          gradientColors: [
                            Colors.amber.shade400,
                            Colors.orange.shade600,
                          ],
                          glowColor: Colors.amber,
                        ),

                        const SizedBox(height: 20),

                        // Thiết bị 2: Quạt
                        _buildModernDeviceCard(
                          icon: Icons.air,
                          title: 'Quạt Trần',
                          subtitle: 'Phòng ngủ',
                          value: _fanSwitch,
                          onChanged: (value) {
                            setState(() {
                              _fanSwitch = value;
                            });
                          },
                          gradientColors: [
                            Colors.blue.shade400,
                            Colors.cyan.shade600,
                          ],
                          glowColor: Colors.blue,
                        ),

                        const SizedBox(height: 20),

                        // Thiết bị 3: Điều hòa
                        _buildModernDeviceCard(
                          icon: Icons.ac_unit_rounded,
                          title: 'Điều Hòa',
                          subtitle: 'Phòng làm việc',
                          value: _acSwitch,
                          onChanged: (value) {
                            setState(() {
                              _acSwitch = value;
                            });
                          },
                          gradientColors: [
                            Colors.cyan.shade400,
                            Colors.teal.shade600,
                          ],
                          glowColor: Colors.cyan,
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Nút micro nổi
          Positioned(
            bottom: 32,
            right: 32,
            child: FloatingActionButton(
              backgroundColor:
                  _speechToText.isListening
                      ? Colors.redAccent
                      : Colors.deepPurple,
              onPressed:
                  _speechToText.isListening ? _stopListening : _startListening,
              tooltip:
                  _speechToText.isListening ? 'Dừng thu âm' : 'Bắt đầu thu âm',
              elevation: 8,
              child: Icon(
                _speechToText.isListening
                    ? Icons.mic_off_rounded
                    : Icons.mic_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiện đại cho thiết bị
  Widget _buildModernDeviceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required List<Color> gradientColors,
    required Color glowColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              value
                  ? gradientColors
                  : [Colors.grey.shade800, Colors.grey.shade900],
        ),
        boxShadow: [
          if (value)
            BoxShadow(
              color: glowColor.withOpacity(0.6),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Icon thiết bị với animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(value ? 0.25 : 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 36, color: Colors.white),
                ),

                const SizedBox(width: 16),

                // Thông tin thiết bị
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: value ? Colors.greenAccent : Colors.grey,
                              boxShadow:
                                  value
                                      ? [
                                        BoxShadow(
                                          color: Colors.greenAccent.withOpacity(
                                            0.8,
                                          ),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            value ? 'Đang bật' : 'Đang tắt',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  value
                                      ? Colors.greenAccent
                                      : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Switch với animation
                Transform.scale(
                  scale: 1.1,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white.withOpacity(0.5),
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
