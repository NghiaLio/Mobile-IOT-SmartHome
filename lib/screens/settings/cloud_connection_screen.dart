import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/settings/settings_cubit.dart';
import '../home/home_screen.dart';

class CloudConnectionScreen extends StatefulWidget {
  final String userUid;
  // true = lần đầu sau khi login, false = từ settings button
  final bool isFirstTime;

  const CloudConnectionScreen({
    super.key,
    required this.userUid,
    this.isFirstTime = false,
  });

  @override
  State<CloudConnectionScreen> createState() => _CloudConnectionScreenState();
}

class _CloudConnectionScreenState extends State<CloudConnectionScreen> {
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final isConnected = await context.read<SettingsCubit>().isDeviceConnected(
      deviceId: 'esp123',
    );

    if (mounted) {
      setState(() {
        _isConnected = isConnected;
      });
    }
  }

  void _handleConnectToCloud() {
    context.read<SettingsCubit>().connectToCloud(
      userUid: widget.userUid,
      deviceId: 'esp123',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cài Đặt',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quản lý kết nối Cloud',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        if (widget.isFirstTime && !_isConnected) {
                          // Lần đầu chưa kết nối → không cho thoát
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Vui lòng kết nối Cloud trước khi tiếp tục',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } else {
                          // Đã kết nối hoặc từ settings → cho thoát bình thường
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User UID Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ID Người Dùng',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.userUid,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã sao chép UID'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Text(
                                'Nhấn để sao chép',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Connection Status
                      Text(
                        'Trạng Thái Kết Nối',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      BlocListener<SettingsCubit, SettingsState>(
                        listener: (context, state) {
                          if (state is CloudConnectionSuccess) {
                            _checkConnection();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.message),
                                backgroundColor: Colors.green,
                              ),
                            );
                            // Navigate to HomeScreen after success
                            Future.delayed(const Duration(seconds: 1), () {
                              if (mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            });
                          } else if (state is SettingsError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.message),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: BlocBuilder<SettingsCubit, SettingsState>(
                          builder: (context, state) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white.withOpacity(0.1),
                                border: Border.all(
                                  color:
                                      _isConnected
                                          ? Colors.greenAccent
                                          : Colors.orange.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              _isConnected
                                                  ? Colors.greenAccent
                                                  : Colors.orange,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  _isConnected
                                                      ? Colors.greenAccent
                                                          .withOpacity(0.8)
                                                      : Colors.orange
                                                          .withOpacity(0.6),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _isConnected
                                            ? 'Đã Kết Nối'
                                            : 'Chưa Kết Nối',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              _isConnected
                                                  ? Colors.greenAccent
                                                  : Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _isConnected
                                        ? 'Thiết bị của bạn đã được kết nối với Cloud'
                                        : 'Nhấn nút bên dưới để kết nối thiết bị với Cloud',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Connect Button
                      if (!_isConnected)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: BlocBuilder<SettingsCubit, SettingsState>(
                            builder: (context, state) {
                              final isLoading = state is SettingsLoading;
                              return ElevatedButton(
                                onPressed:
                                    isLoading ? null : _handleConnectToCloud,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade500,
                                  disabledBackgroundColor: Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                ),
                                child:
                                    isLoading
                                        ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          'Kết Nối Với Cloud',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                              );
                            },
                          ),
                        )
                      else
                        // Logout Button when connected
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              context.read<AuthCubit>().signOut();
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade500,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                            ),
                            child: const Text(
                              'Đăng Xuất',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
