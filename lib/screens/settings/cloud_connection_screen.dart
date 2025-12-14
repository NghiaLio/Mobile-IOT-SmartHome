// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/settings/settings_cubit.dart';
import '../../services/connection_preferences_service.dart';
import '../share/join_device_screen.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Kết Nối Thiết Bị'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Status Icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isConnected
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                            ),
                            child: Icon(
                              _isConnected
                                  ? Icons.cloud_done
                                  : Icons.cloud_off,
                              color: _isConnected
                                  ? Colors.green
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
                              color: _isConnected
                                  ? Colors.green
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
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.devices,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Mã thiết bị: ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  Text(
                                    _connectedDeviceId!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (!_isConnected) ...[
              const SizedBox(height: 32),

              // Instructions Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Hướng dẫn kết nối',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
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
              ),

              const SizedBox(height: 24),

              // Device ID Input
              TextField(
                controller: _deviceIdController,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Mã thiết bị ESP',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  hintText: 'Ví dụ: esp123',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  prefixIcon: Icon(
                    Icons.devices,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
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
                        elevation: 2,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Divider with "hoặc"
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'hoặc',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      thickness: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Join with QR Code Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const JoinDeviceScreen(),
                      ),
                    ).then((_) {
                      // Refresh connection status when coming back
                      _checkConnection();
                      _loadConnectedDevice();
                    });
                  },
                  icon: Icon(
                    Icons.qr_code_scanner,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    'Tham Gia Bằng Mã QR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
