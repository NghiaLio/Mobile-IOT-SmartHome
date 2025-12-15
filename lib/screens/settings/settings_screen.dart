// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme/theme_cubit.dart';
import '../../cubits/auth/auth_cubit.dart';
import 'cloud_connection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài Đặt')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          _buildSectionHeader('Giao Diện'),
          _buildThemeToggle(context),

          const SizedBox(height: 24),

          // Device Section
          _buildSectionHeader('Thiết Bị'),
          _buildDeviceSettings(context),

          const SizedBox(height: 24),

          // Account Section
          _buildSectionHeader('Tài Khoản'),
          _buildAccountInfo(context),
          const SizedBox(height: 8),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final isDarkMode =
            state is ThemeChanged
                ? state.isDarkMode
                : state is ThemeInitial
                ? state.isDarkMode
                : true;

        return Card(
          child: ListTile(
            leading: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Chế độ sáng/tối'),
            subtitle: Text(
              isDarkMode ? 'Đang dùng chế độ tối' : 'Đang dùng chế độ sáng',
            ),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) {
                context.read<ThemeCubit>().setTheme(value);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceSettings(BuildContext context) {
    final authState = context.read<AuthCubit>().state;

    if (authState is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.cloud,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Kết nối thiết bị'),
            subtitle: const Text('Quản lý kết nối Cloud'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
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
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.logout, color: Colors.red.shade600),
        title: const Text('Đăng xuất'),
        textColor: Colors.red.shade600,
        onTap: () {
          showDialog(
            context: context,
            builder:
                (dialogContext) => AlertDialog(
                  title: const Text('Đăng xuất?'),
                  content: const Text('Bạn có chắc muốn đăng xuất?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<AuthCubit>().signOut();
                        Navigator.pop(dialogContext);
                      },
                      child: Text(
                        'Đăng xuất',
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ),
                  ],
                ),
          );
        },
      ),
    );
  }

  Widget _buildAccountInfo(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }

    final email = authState.user.email ?? 'Không có email';
    final displayName = authState.user.displayName ?? '';

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.person,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(displayName.isNotEmpty ? displayName : email),
        subtitle: Text(email),
      ),
    );
  }
}
