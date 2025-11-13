import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/device/device_cubit.dart';
import '../../cubits/speech/speech_cubit.dart';
import '../settings/cloud_connection_screen.dart';
import '../../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize speech recognition when entering home screen
    context.read<SpeechCubit>().initSpeech();
  }

  void _handleSignOut(BuildContext context) {
    context.read<AuthCubit>().signOut();
  }

  void _handleGoToSettings(BuildContext context) {
    // Get the user UID from AuthCubit state
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CloudConnectionScreen(
                userUid: authState.user.uid,
                isFirstTime: false,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
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
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Nhà Thông Minh',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Settings and Logout Buttons
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.withOpacity(0.2),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.settings,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () => _handleGoToSettings(context),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red.withOpacity(0.2),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.logout,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () => _handleSignOut(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Speech Status and Results
                    BlocBuilder<SpeechCubit, SpeechState>(
                      builder: (context, state) {
                        String statusText = 'Micro chưa được khởi tạo';
                        String resultText = '';

                        if (state is SpeechReady) {
                          statusText = 'Micro đã sẵn sàng';
                        } else if (state is SpeechListening) {
                          statusText = 'Đang lắng nghe...';
                        } else if (state is SpeechResult) {
                          statusText = 'Micro đã sẵn sàng';
                          resultText = state.recognizedWords;
                        } else if (state is SpeechError) {
                          statusText = 'Lỗi: ${state.message}';
                        } else if (state is SpeechNotAvailable) {
                          statusText =
                              'Micro không khả dụng hoặc chưa cấp quyền';
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            children: [
                              Text(
                                statusText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bạn nói: "$resultText"',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Device List
                    Expanded(
                      child: BlocBuilder<DeviceCubit, DeviceState>(
                        builder: (context, state) {
                          if (state is! DeviceLoaded) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          return ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              const SizedBox(height: 20),

                              // Light Device
                              _buildModernDeviceCard(
                                context: context,
                                icon: Icons.lightbulb_rounded,
                                title: 'Đèn Phòng',
                                subtitle: 'Phòng khách',
                                value: state.lightState,
                                onChanged: (value) {
                                  context.read<DeviceCubit>().toggleLight(
                                    value,
                                  );
                                },
                                gradientColors: [
                                  Colors.amber.shade400,
                                  Colors.orange.shade600,
                                ],
                                glowColor: Colors.amber,
                              ),

                              const SizedBox(height: 20),

                              // Fan Device
                              _buildModernDeviceCard(
                                context: context,
                                icon: Icons.air,
                                title: 'Quạt Trần',
                                subtitle: 'Phòng ngủ',
                                value: state.fanState,
                                onChanged: (value) {
                                  context.read<DeviceCubit>().toggleFan(value);
                                },
                                gradientColors: [
                                  Colors.blue.shade400,
                                  Colors.cyan.shade600,
                                ],
                                glowColor: Colors.blue,
                              ),

                              const SizedBox(height: 20),

                              // AC Device
                              _buildModernDeviceCard(
                                context: context,
                                icon: Icons.ac_unit_rounded,
                                title: 'Điều Hòa',
                                subtitle: 'Phòng làm việc',
                                value: state.acState,
                                onChanged: (value) {
                                  context.read<DeviceCubit>().toggleAC(value);
                                },
                                gradientColors: [
                                  Colors.cyan.shade400,
                                  Colors.teal.shade600,
                                ],
                                glowColor: Colors.cyan,
                              ),

                              const SizedBox(height: 20),

                              // Microphone Button
                              Center(
                                child: BlocBuilder<SpeechCubit, SpeechState>(
                                  builder: (context, state) {
                                    final isListening =
                                        state is SpeechListening;
                                    return GestureDetector(
                                      onLongPress:
                                          isListening
                                              ? () {
                                                context
                                                    .read<SpeechCubit>()
                                                    .stopListening();
                                              }
                                              : () {
                                                context
                                                    .read<SpeechCubit>()
                                                    .startListening();
                                              },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors:
                                                isListening
                                                    ? [
                                                      Colors.red.shade400,
                                                      Colors.red.shade600,
                                                    ]
                                                    : [
                                                      Colors.purple.shade400,
                                                      Colors.purple.shade600,
                                                    ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  isListening
                                                      ? Colors.red.withOpacity(
                                                        0.6,
                                                      )
                                                      : Colors.purple
                                                          .withOpacity(0.6),
                                              blurRadius: isListening ? 25 : 15,
                                              spreadRadius: isListening ? 8 : 3,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          isListening
                                              ? Icons.mic
                                              : Icons.mic_none,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 32),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDeviceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required List<Color> gradientColors,
    required Color glowColor,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: gradientColors),
          boxShadow: [
            if (value)
              BoxShadow(
                color: glowColor.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 3,
              ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),

            const SizedBox(width: 16),

            // Title and Subtitle
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
                              value ? Colors.greenAccent : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Switch with animation
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
    );
  }
}
