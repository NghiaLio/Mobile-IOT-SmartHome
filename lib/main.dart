import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/device/device_cubit.dart';
import 'cubits/speech/speech_cubit.dart';
import 'cubits/settings/settings_cubit.dart';
import 'cubits/rfid/rfid_cubit.dart';
import 'cubits/share/share_cubit.dart';
import 'cubits/theme/theme_cubit.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final database =
        FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
              'https://smart-944cb-default-rtdb.asia-southeast1.firebasedatabase.app/',
        ).ref();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit(authService)),
        BlocProvider(
          create: (context) => DeviceCubit(database),
        ),
        BlocProvider(create: (context) => SpeechCubit(SpeechToText())),
        BlocProvider(create: (context) => SettingsCubit(database)),
        BlocProvider(create: (context) => RfidCubit(database)),
        BlocProvider(create: (context) => ShareCubit(database)),
        BlocProvider(create: (context) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          final isDarkMode = themeState is ThemeChanged
              ? themeState.isDarkMode
              : themeState is ThemeInitial
                  ? themeState.isDarkMode
                  : true;

          return MaterialApp(
            title: 'Smart Home Control',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.light(
                primary: Colors.blue.shade700,
                secondary: Colors.blue.shade500,
                surface: Colors.white,
                // ignore: deprecated_member_use
                background: Colors.grey.shade50,
                error: Colors.red.shade600,
              ),
              scaffoldBackgroundColor: Colors.grey.shade50,
              cardColor: Colors.white,
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.dark(
                primary: Colors.blue.shade400,
                secondary: Colors.blue.shade300,
                surface: Colors.grey.shade900,
                // ignore: deprecated_member_use
                background: Colors.grey.shade900,
                error: Colors.red.shade400,
              ),
              scaffoldBackgroundColor: Colors.grey.shade900,
              cardColor: Colors.grey.shade800,
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.grey.shade800,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AuthAuthenticated) {
          // Sau khi đăng nhập, luôn vào màn hình chính
          return const HomeScreen();
        }

        return const AuthScreen();
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;

  @override
  Widget build(BuildContext context) {
    return _isSignIn
        ? LoginScreen(
          onSignUpTap: () {
            setState(() => _isSignIn = false);
          },
        )
        : SignUpScreen(
          onSignInTap: () {
            setState(() => _isSignIn = true);
          },
        );
  }
}
