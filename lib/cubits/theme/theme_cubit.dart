import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

// States
abstract class ThemeState {}

class ThemeInitial extends ThemeState {
  final bool isDarkMode;
  ThemeInitial({this.isDarkMode = true});
}

class ThemeChanged extends ThemeState {
  final bool isDarkMode;
  ThemeChanged(this.isDarkMode);
}

// Cubit
class ThemeCubit extends Cubit<ThemeState> {
  static const String _themeKey = 'is_dark_mode';

  ThemeCubit() : super(ThemeInitial()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool(_themeKey) ?? true; // Default dark
      emit(ThemeChanged(isDarkMode));
    } catch (e) {
      log('Lỗi load theme: $e');
      emit(ThemeChanged(true));
    }
  }

  Future<void> toggleTheme() async {
    try {
      final currentState = state;
      final isDarkMode = currentState is ThemeChanged
          ? !currentState.isDarkMode
          : false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDarkMode);

      emit(ThemeChanged(isDarkMode));
      log('Đã chuyển theme: ${isDarkMode ? "Dark" : "Light"}');
    } catch (e) {
      log('Lỗi toggle theme: $e');
    }
  }

  Future<void> setTheme(bool isDarkMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDarkMode);
      emit(ThemeChanged(isDarkMode));
      log('Đã set theme: ${isDarkMode ? "Dark" : "Light"}');
    } catch (e) {
      log('Lỗi set theme: $e');
    }
  }
}

