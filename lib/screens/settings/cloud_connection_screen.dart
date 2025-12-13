// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/settings/settings_cubit.dart';
import '../../services/connection_preferences_service.dart';

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
  String? _connectedDeviceId;
  final TextEditingController _deviceIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadConnectedDevice();
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final isConnected = await context.read<SettingsCubit>().isDeviceConnected(
      widget.userUid,
    );
    if (mounted) {
      setState(() {
        _isConnected = isConnected;
      });
    }
  }

  Future<void> _loadConnectedDevice() async {
    final deviceId = await ConnectionPreferencesService.getConnectedDeviceId();
    if (mounted) {
      setState(() {
        _connectedDeviceId = deviceId;
      });
    }
  }

  void _handleConnectToCloud() {
    if (_deviceIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mã thiết bị'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    context.read<SettingsCubit>().connectToCloud(
      userUid: widget.userUid,
      deviceId: _deviceIdController.text.trim(),
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
              // Header compact
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kết Nối Thiết Bị',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Thêm thiết bị ESP của bạn',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // Connection Status Card
                      BlocListener<SettingsCubit, SettingsState>(
                        listener: (context, state) {
                          if (state is CloudConnectionSuccess) {
                            _checkConnection();
                            _loadConnectedDevice(); // Reload device ID after success
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(child: Text(state.message)),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            // Go back to HomeScreen
                            Future.delayed(const Duration(seconds: 1), () {
                              if (mounted) {
                                Navigator.pop(context);
                              }
                            });
                          } else if (state is SettingsError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(child: Text(state.message)),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                        child: BlocBuilder<SettingsCubit, SettingsState>(
                          builder: (context, state) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white.withOpacity(0.08),
                                border: Border.all(
                                  color:
                                      _isConnected
                                          ? Colors.greenAccent.withOpacity(0.5)
                                          : Colors.orange.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Status Icon
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          _isConnected
                                              ? Colors.greenAccent.withOpacity(
                                                0.2,
                                              )
                                              : Colors.orange.withOpacity(0.2),
                                    ),
                                    child: Icon(
                                      _isConnected
                                          ? Icons.cloud_done
                                          : Icons.cloud_off,
                                      color:
                                          _isConnected
                                              ? Colors.greenAccent
                                              : Colors.orange,
                                      size: 48,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Status Text
                                  Text(
                                    _isConnected
                                        ? 'Đã Kết Nối'
                                        : 'Chưa Kết Nối',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _isConnected
                                              ? Colors.greenAccent
                                              : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isConnected
                                        ? 'Thiết bị của bạn đã được kết nối với Cloud'
                                        : 'Vui lòng nhập mã thiết bị để kết nối',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  // Show connected device ID
                                  if (_isConnected &&
                                      _connectedDeviceId != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.greenAccent.withOpacity(
                                            0.3,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.devices,
                                            size: 16,
                                            color: Colors.greenAccent,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Mã thiết bị: ',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _connectedDeviceId!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.greenAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      if (!_isConnected) ...[
                        const SizedBox(height: 32),

                        // Instructions Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.blue.withOpacity(0.1),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade300,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Hướng dẫn kết nối',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              _buildInstruction(
                                '1',
                                'Lấy mã thiết bị từ ESP của bạn',
                              ),
                              SizedBox(height: 8),
                              _buildInstruction('2', 'Nhập mã vào ô bên dưới'),
                              SizedBox(height: 8),
                              _buildInstruction(
                                '3',
                                'Nhấn nút "Kết Nối" để hoàn tất',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Device ID Input
                        TextField(
                          controller: _deviceIdController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Mã thiết bị ESP',
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                            hintText: 'Ví dụ: esp123',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                            ),
                            prefixIcon: Icon(
                              Icons.devices,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.green.shade400,
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Connect Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: BlocBuilder<SettingsCubit, SettingsState>(
                            builder: (context, state) {
                              final isLoading = state is SettingsLoading;
                              return ElevatedButton.icon(
                                onPressed:
                                    isLoading ? null : _handleConnectToCloud,
                                icon: Icon(
                                  isLoading
                                      ? Icons.hourglass_empty
                                      : Icons.cloud_upload,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  isLoading ? 'Đang kết nối...' : 'Kết Nối',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade500,
                                  disabledBackgroundColor: Colors.grey.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: isLoading ? 0 : 4,
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
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

  Widget _buildInstruction(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withOpacity(0.3),
            border: Border.all(color: Colors.blue.shade300, width: 1.5),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade300,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
