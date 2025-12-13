// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/device/device_cubit.dart';
import '../../cubits/speech/speech_cubit.dart';
import '../../cubits/settings/settings_cubit.dart';
import '../../cubits/rfid/rfid_cubit.dart';
import '../settings/cloud_connection_screen.dart';
import '../rfid/rfid_cards_screen.dart';
import '../share/share_device_screen.dart';
import '../../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDeviceConnected = false;

  @override
  void initState() {
    super.initState();
    // Initialize speech recognition when entering home screen
    context.read<SpeechCubit>().initSpeech();
    _checkDeviceConnection();
  }

  Future<void> _checkDeviceConnection() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      final isConnected = await context.read<SettingsCubit>().isDeviceConnected(
        authState.user.uid,
      );
      if (mounted) {
        setState(() {
          _isDeviceConnected = isConnected;
        });
      }
    }
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
      ).then((_) {
        // Refresh connection status when coming back
        _checkDeviceConnection();
      });
    }
  }

  void _handleAddDevice(BuildContext context) {
    // Navigate to CloudConnectionScreen to add device
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
      ).then((_) {
        // Refresh connection status when coming back
        _checkDeviceConnection();
      });
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
                    // Header compact
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        children: [
                          // Icon và Title ngang
                          Container(
                            padding: const EdgeInsets.all(8),
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
                                  color: Colors.amber.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.home_rounded,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Nhà Thông Minh',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Action Buttons
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.withOpacity(0.2),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () => _handleAddDevice(context),
                              tooltip: 'Thêm thiết bị',
                            ),
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            color: Colors.deepPurple.shade800,
                            onSelected: (value) {
                              if (value == 'settings') {
                                _handleGoToSettings(context);
                              } else if (value == 'share') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ShareDeviceScreen(),
                                  ),
                                );
                              } else if (value == 'logout') {
                                _handleSignOut(context);
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  PopupMenuItem(
                                    value: 'share',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.share,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Chia sẻ',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'settings',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.settings,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Cài đặt',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'logout',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.logout,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Đăng xuất',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                          ),
                        ],
                      ),
                    ),

                    // Speech Status - Chỉ hiện khi có activity
                    BlocBuilder<SpeechCubit, SpeechState>(
                      builder: (context, state) {
                        if (state is SpeechListening) {
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.mic,
                                  color: Colors.red.shade300,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Đang lắng nghe...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (state is SpeechResult &&
                            state.recognizedWords.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade300,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Bạn nói: "${state.recognizedWords}"',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (state is SpeechError) {
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.orange.shade300,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    state.message,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),

                    // Device List với Floating Mic Button
                    Expanded(
                      child:
                          _isDeviceConnected
                              ? BlocBuilder<DeviceCubit, DeviceState>(
                                builder: (context, state) {
                                  if (state is! DeviceLoaded) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  return Stack(
                                    children: [
                                      // Device List
                                      ListView(
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          12,
                                          20,
                                          100,
                                        ),
                                        children: [
                                          // Warning Alerts
                                          if (state.gasLevel > 1200)
                                            _buildWarningCard(
                                              icon: Icons.cloud,
                                              title: 'CẢNH BÁO KHÍ GAS!',
                                              message:
                                                  'Mức gas: ${state.gasLevel} ppm (>1200)',
                                              color: Colors.red,
                                            ),
                                          if (state.flameDetected == 1)
                                            _buildWarningCard(
                                              icon: Icons.local_fire_department,
                                              title: 'CẢNH BÁO LỬA!',
                                              message: 'Phát hiện lửa trong khu vực',
                                              color: Colors.orange,
                                            ),
                                          if (state.rainDetected == 0)
                                            _buildWarningCard(
                                              icon: Icons.water_drop,
                                              title: 'CẢNH BÁO MƯA!',
                                              message: 'Phát hiện mưa, đóng cửa sổ',
                                              color: Colors.blue,
                                            ),
                                          if (state.gasLevel > 1200 ||
                                              state.flameDetected == 1 ||
                                              state.rainDetected == 0)
                                            const SizedBox(height: 16),

                                          // Sensors Info Grid
                                          _buildSectionTitle('Cảm Biến'),
                                          const SizedBox(height: 12),
                                          GridView.count(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            childAspectRatio: 1.3,
                                            children: [
                                              _buildSensorCard(
                                                icon: Icons.thermostat,
                                                title: 'Nhiệt độ',
                                                value:
                                                    '${state.temperature.toStringAsFixed(1)}°C',
                                                color: Colors.orange,
                                              ),
                                              _buildSensorCard(
                                                icon: Icons.water_damage,
                                                title: 'Độ ẩm',
                                                value: '${state.humidity}%',
                                                color: Colors.blue,
                                              ),
                                              _buildSensorCard(
                                                icon: Icons.cloud,
                                                title: 'Khí Gas',
                                                value: '${state.gasLevel} ppm',
                                                color: state.gasLevel > 1200
                                                    ? Colors.red
                                                    : Colors.green,
                                                isWarning: state.gasLevel > 1200,
                                              ),
                                              _buildSensorCard(
                                                icon: Icons.door_front_door,
                                                title: 'Góc cửa',
                                                value: '${state.doorAngle}°',
                                                color: Colors.purple,
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 24),

                                          // Controls
                                          _buildSectionTitle('Điều Khiển'),
                                          const SizedBox(height: 12),

                                          // Light Device
                                          _buildModernDeviceCard(
                                            context: context,
                                            icon: Icons.lightbulb_rounded,
                                            title: 'Đèn Phòng',
                                            subtitle: 'Phòng khách',
                                            value: state.lightState,
                                            onChanged: (value) {
                                              context
                                                  .read<DeviceCubit>()
                                                  .toggleLight(value);
                                            },
                                            gradientColors: [
                                              Colors.amber.shade400,
                                              Colors.orange.shade600,
                                            ],
                                            glowColor: Colors.amber,
                                          ),

                                          const SizedBox(height: 16),

                                          // Fan Device
                                          _buildModernDeviceCard(
                                            context: context,
                                            icon: Icons.air,
                                            title: 'Quạt Trần',
                                            subtitle: 'Phòng ngủ',
                                            value: state.fanState,
                                            onChanged: (value) {
                                              context
                                                  .read<DeviceCubit>()
                                                  .toggleFan(value);
                                            },
                                            gradientColors: [
                                              Colors.blue.shade400,
                                              Colors.cyan.shade600,
                                            ],
                                            glowColor: Colors.blue,
                                          ),

                                          const SizedBox(height: 16),

                                          // AC Device
                                          _buildModernDeviceCard(
                                            context: context,
                                            icon: Icons.ac_unit_rounded,
                                            title: 'Điều Hòa',
                                            subtitle: 'Phòng làm việc',
                                            value: state.acState,
                                            onChanged: (value) {
                                              context
                                                  .read<DeviceCubit>()
                                                  .toggleAC(value);
                                            },
                                            gradientColors: [
                                              Colors.cyan.shade400,
                                              Colors.teal.shade600,
                                            ],
                                            glowColor: Colors.cyan,
                                          ),

                                          const SizedBox(height: 24),

                                          // RFID Cards Section
                                          _buildSectionTitle('Thẻ RFID'),
                                          const SizedBox(height: 12),
                                          _buildRfidCard(context),
                                        ],
                                      ),

                                      // Floating Microphone Button
                                      Positioned(
                                        right: 20,
                                        bottom: 20,
                                        child: BlocBuilder<
                                          SpeechCubit,
                                          SpeechState
                                        >(
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
                                                padding: const EdgeInsets.all(
                                                  20,
                                                ),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    colors:
                                                        isListening
                                                            ? [
                                                              Colors
                                                                  .red
                                                                  .shade400,
                                                              Colors
                                                                  .red
                                                                  .shade600,
                                                            ]
                                                            : [
                                                              Colors
                                                                  .purple
                                                                  .shade400,
                                                              Colors
                                                                  .purple
                                                                  .shade600,
                                                            ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color:
                                                          isListening
                                                              ? Colors.red
                                                                  .withOpacity(
                                                                    0.6,
                                                                  )
                                                              : Colors.purple
                                                                  .withOpacity(
                                                                    0.5,
                                                                  ),
                                                      blurRadius:
                                                          isListening ? 20 : 12,
                                                      spreadRadius:
                                                          isListening ? 5 : 2,
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  isListening
                                                      ? Icons.mic
                                                      : Icons.mic_none,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              )
                              : Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                        child: Icon(
                                          Icons.devices_other,
                                          size: 64,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Chưa có thiết bị nào được kết nối',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Nhấn nút + ở góc trên bên phải để\nthêm thiết bị của bạn',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 32),
                                      ElevatedButton.icon(
                                        onPressed:
                                            () => _handleAddDevice(context),
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          'Thêm Thiết Bị',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.green.shade500,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color:
              value
                  ? glowColor.withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
          width: 2,
        ),
        boxShadow:
            value
                ? [
                  BoxShadow(
                    color: glowColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon with gradient background
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(colors: gradientColors),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status and Switch
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Transform.scale(
                      scale: 0.9,
                      child: Switch(
                        value: value,
                        onChanged: onChanged,
                        activeColor: glowColor,
                        activeTrackColor: glowColor.withOpacity(0.5),
                        inactiveThumbColor: Colors.grey.shade500,
                        inactiveTrackColor: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            value
                                ? glowColor.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        value ? 'Đang bật' : 'Đã tắt',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: value ? glowColor : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildWarningCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.2),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.3),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(
          color: isWarning
              ? color.withOpacity(0.6)
              : Colors.white.withOpacity(0.1),
          width: isWarning ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRfidCard(BuildContext context) {
    return BlocBuilder<RfidCubit, RfidState>(
      builder: (context, state) {
        int cardCount = 0;
        if (state is RfidLoaded) {
          cardCount = state.cards.length;
        } else if (state is RfidCardAdded) {
          cardCount = state.allCards.length;
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RfidCardsScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.shade400,
                  Colors.purple.shade600,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thẻ RFID',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$cardCount thẻ đã đăng ký',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
