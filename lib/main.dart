import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:id_token_generator/firebase_options.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:id_token_generator/data/auth/firebase_auth_repository.dart';
import 'package:id_token_generator/domain/auth/auth_repository.dart';
import 'package:id_token_generator/presentation/auth/bloc/auth_bloc.dart';
import 'package:id_token_generator/presentation/auth/pages/unauthenticated_page.dart';
import 'package:id_token_generator/presentation/auth/pages/authenticated_page.dart';
import 'package:id_token_generator/presentation/settings/firebase_config_dialog.dart';
import 'package:id_token_generator/core/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }
  runApp(const MyApp());
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration cleared. Using default.'),
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
        ),
      );
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
