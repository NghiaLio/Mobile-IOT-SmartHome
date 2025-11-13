import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/connection_preferences_service.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/device/device_cubit.dart';
import 'cubits/speech/speech_cubit.dart';
import 'cubits/settings/settings_cubit.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/settings/cloud_connection_screen.dart';
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
          create: (context) => DeviceCubit(database, deviceId: 'esp123'),
        ),
        BlocProvider(create: (context) => SpeechCubit(SpeechToText())),
        BlocProvider(create: (context) => SettingsCubit(database)),
      ],
      child: MaterialApp(
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
        home: const AuthWrapper(),
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
  late Future<bool> _checkConnectionFuture;

  @override
  void initState() {
    super.initState();
    _checkConnectionFuture = ConnectionPreferencesService.isConnected();
  }

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
          return FutureBuilder<bool>(
            future: _checkConnectionFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final isConnected = snapshot.data ?? false;

              if (isConnected) {
                // Already connected, go directly to HomeScreen
                return const HomeScreen();
              } else {
                // Not connected, show CloudConnectionScreen for first-time setup
                return CloudConnectionScreen(
                  userUid: state.user.uid,
                  isFirstTime: true,
                );
              }
            },
          );
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
