import 'dart:convert';
import 'dart:html' as html;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:id_token_generator/data/auth/firebase_auth_repository.dart';
import 'package:id_token_generator/domain/auth/auth_repository.dart';
import 'package:id_token_generator/presentation/auth/bloc/auth_bloc.dart';
import 'package:id_token_generator/presentation/auth/pages/unauthenticated_page.dart';
import 'package:id_token_generator/presentation/auth/pages/authenticated_page.dart';
import 'package:id_token_generator/presentation/settings/firebase_config_dialog.dart';
import 'package:id_token_generator/presentation/settings/config_required_page.dart';
import 'package:id_token_generator/core/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> _hasFirebaseConfig() async {
  if (!kIsWeb) return true; // Non-web platforms use default config
  
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(AppPrefsKeys.firebaseWebConfig);
    return raw != null && raw.trim().isNotEmpty;
  } catch (_) {
    return false;
  }
}

Future<FirebaseOptions> _getFirebaseOptions() async {
  if (!kIsWeb) {
    throw UnsupportedError('This app requires Firebase configuration for web platform');
  }
  
  // Load user-provided config from SharedPreferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? raw = prefs.getString(AppPrefsKeys.firebaseWebConfig);
  
  if (raw == null || raw.trim().isEmpty) {
    throw StateError('Firebase configuration is required. Please configure Firebase settings first.');
  }
  
  // Parse the JSON config
  String text = raw.trim();
  final int firstBrace = text.indexOf('{');
  final int lastBrace = text.lastIndexOf('}');
  if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
    text = text.substring(firstBrace, lastBrace + 1);
  }
  
  final Map<String, dynamic> config = json.decode(text) as Map<String, dynamic>;
  
  // Validate required fields
  final String? apiKey = config['apiKey'] as String?;
  final String? appId = config['appId'] as String?;
  final String? projectId = config['projectId'] as String?;
  final String? messagingSenderId = config['messagingSenderId']?.toString();
  
  if (apiKey == null || appId == null || projectId == null || messagingSenderId == null || 
      apiKey.isEmpty || appId.isEmpty || projectId.isEmpty || messagingSenderId.isEmpty) {
    throw FormatException('Missing required Firebase config fields. Please configure all required fields.');
  }
  
  // authDomain is required for authentication - generate from projectId if not provided
  String? authDomain = config['authDomain'] as String?;
  if (authDomain == null || authDomain.trim().isEmpty) {
    authDomain = '$projectId.firebaseapp.com';
    debugPrint('authDomain not provided, using default: $authDomain');
  }
  
  // Create FirebaseOptions from user config
  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain,
    storageBucket: config['storageBucket'] as String?,
    measurementId: config['measurementId'] as String?,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  
  // Check if Firebase configuration exists (for web platform)
  if (kIsWeb) {
    final bool hasConfig = await _hasFirebaseConfig();
    if (!hasConfig) {
      // Show configuration required screen without initializing Firebase
      runApp(const ConfigRequiredApp());
      return;
    }
  }
  
  // Initialize Firebase with user configuration
  try {
    final FirebaseOptions options = await _getFirebaseOptions();
    await Firebase.initializeApp(options: options);
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }
    runApp(const MyApp());
  } catch (e) {
    // If initialization fails, show configuration screen
    debugPrint('Firebase initialization failed: $e');
    if (kIsWeb) {
      runApp(const ConfigRequiredApp());
    } else {
      rethrow;
    }
  }
}

class ConfigRequiredApp extends StatelessWidget {
  const ConfigRequiredApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme lightScheme = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 87, 207, 66),
      brightness: Brightness.light,
    );
    final ColorScheme darkScheme = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 87, 207, 66),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'ID Token Generator',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: lightScheme.surface,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: darkScheme.surface,
      ),
      home: const ConfigRequiredPage(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme lightScheme = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 87, 207, 66),
      brightness: Brightness.light,
    );
    final ColorScheme darkScheme = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 87, 207, 66),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'ID Token Generator',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: lightScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: lightScheme.surface,
          foregroundColor: lightScheme.onSurface,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: lightScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 1,
          surfaceTintColor: lightScheme.surfaceTint,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: lightScheme.inverseSurface,
          contentTextStyle: TextStyle(color: lightScheme.onInverseSurface),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: Typography.material2021(
          platform: TargetPlatform.android,
        ).black,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: darkScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: darkScheme.surface,
          foregroundColor: darkScheme.onSurface,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: darkScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 1,
          surfaceTintColor: darkScheme.surfaceTint,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: darkScheme.outlineVariant),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: darkScheme.inverseSurface,
          contentTextStyle: TextStyle(color: darkScheme.onInverseSurface),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: Typography.material2021(
          platform: TargetPlatform.android,
        ).white,
      ),
      home: RepositoryProvider<AuthRepository>(
        create: (_) => FirebaseAuthRepository(),
        child: Builder(
          builder: (context) {
            return BlocProvider<AuthBloc>(
              create: (_) =>
                  AuthBloc(repository: context.read<AuthRepository>()),
              child: const RootPage(),
            );
          },
        ),
      ),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  bool _hasConfig = false;

  @override
  void initState() {
    super.initState();
    _reloadHasConfig();
  }

  Future<void> _reloadHasConfig() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(AppPrefsKeys.firebaseWebConfig);
    setState(() {
      _hasConfig = raw != null && raw.trim().isNotEmpty;
    });
  }

  Future<void> _clearConfig() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppPrefsKeys.firebaseWebConfig);
    setState(() {
      _hasConfig = false;
    });
    // Automatically reload the page
    if (kIsWeb) {
      html.window.location.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            const Icon(Icons.verified_user_rounded),
            const SizedBox(width: 8),
            const Text('ID Token Generator'),
          ],
        ),
        actions: [
          if (_hasConfig)
            TextButton.icon(
              onPressed: _clearConfig,
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Clear configuration'),
            ),
          IconButton(
            tooltip: 'Firebase settings',
            onPressed: () async {
              await FirebaseConfigDialog.show(context);
              await _reloadHasConfig();
            },
            icon: const Icon(Icons.settings_suggest_rounded),
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state.isAuthenticated) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () => context.read<AuthBloc>().add(
                            const AuthSignOutRequested(),
                          ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state.isAuthenticated && state.user != null) {
            return AuthenticatedPage(user: state.user!);
          }
          return const UnauthenticatedPage();
        },
      ),
    );
  }
}
