import 'dart:developer';
import 'dart:convert';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:id_token_generator/firebase_options.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // This widget is the root of your application.
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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  bool _hasCustomConfig = false;

  String? _googleIdToken;
  String? _firebaseIdToken;
  String? _errorMessage;
  bool _working = false;
  StreamSubscription<User?>? _authSubscription;
  static const String _kPrefGoogleIdToken = 'google_id_token';
  static const String _kPrefFirebaseIdToken = 'firebase_id_token';
  static const String _kPrefTokenUpdatedAtMs = 'tokens_updated_at_ms';
  static const String _kPrefFirebaseWebConfig = 'firebase_web_config_json';

  @override
  void initState() {
    super.initState();
    unawaited(_initAuthAndSubscribe());
  }

  // Redirect flow removed; popup-based auth is used with web persistence.

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initAuthAndSubscribe() async {
    final FirebaseOptions? custom = await _loadSavedFirebaseOptions();
    if (custom != null) {
      _hasCustomConfig = true;
      await _switchToOptions(custom, subscribe: true);
    } else {
      _hasCustomConfig = false;
      _auth = FirebaseAuth.instance;
      if (kIsWeb) {
        try {
          await _auth.setPersistence(Persistence.LOCAL);
        } catch (_) {}
      }
      _authSubscription = _auth.userChanges().listen((user) async {
        if (!mounted) return;
        if (user == null) {
          setState(() {
            _googleIdToken = null;
            _firebaseIdToken = null;
          });
          await _clearPersistedTokens();
          return;
        }
        await _rehydrateTokensIfPossible(user);
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  Future<FirebaseOptions?> _loadSavedFirebaseOptions() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kPrefFirebaseWebConfig);
      if (raw == null || raw.trim().isEmpty) return null;
      return _parseOptionsFromConfigString(raw);
    } catch (_) {
      return null;
    }
  }

  FirebaseOptions? _parseOptionsFromConfigString(String raw) {
    // Accept either pure JSON { ... } or JS snippet like: const firebaseConfig = { ... };
    String jsonPart = raw.trim();
    final int firstBrace = jsonPart.indexOf('{');
    final int lastBrace = jsonPart.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      jsonPart = jsonPart.substring(firstBrace, lastBrace + 1);
    }
    Map<String, dynamic> map;
    try {
      map = json.decode(jsonPart) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
    String? apiKey = map['apiKey'] as String?;
    String? appId = map['appId'] as String?;
    String? messagingSenderId = map['messagingSenderId']?.toString();
    String? projectId = map['projectId'] as String?;
    String? authDomain = map['authDomain'] as String?;
    String? storageBucket = map['storageBucket'] as String?;
    String? measurementId = map['measurementId'] as String?;
    if ([
      apiKey,
      appId,
      messagingSenderId,
      projectId,
    ].any((e) => e == null || e.isEmpty)) {
      return null;
    }
    return FirebaseOptions(
      apiKey: apiKey!,
      appId: appId!,
      messagingSenderId: messagingSenderId!,
      projectId: projectId!,
      authDomain: authDomain,
      storageBucket: storageBucket,
      measurementId: measurementId,
    );
  }

  Future<FirebaseApp> _getOrInitApp(
    String name,
    FirebaseOptions options,
  ) async {
    try {
      return Firebase.app(name);
    } catch (_) {
      return Firebase.initializeApp(name: name, options: options);
    }
  }

  Future<void> _switchToOptions(
    FirebaseOptions options, {
    bool subscribe = false,
  }) async {
    _authSubscription?.cancel();
    try {
      await _auth.signOut();
    } catch (_) {}
    final FirebaseApp app = await _getOrInitApp('custom', options);
    _auth = FirebaseAuth.instanceFor(app: app);
    if (kIsWeb) {
      try {
        await _auth.setPersistence(Persistence.LOCAL);
      } catch (_) {}
    }
    _hasCustomConfig = true;
    if (subscribe) {
      _authSubscription = _auth.userChanges().listen((user) async {
        if (!mounted) return;
        if (user == null) {
          setState(() {
            _googleIdToken = null;
            _firebaseIdToken = null;
          });
          await _clearPersistedTokens();
          return;
        }
        await _rehydrateTokensIfPossible(user);
        if (!mounted) return;
        setState(() {});
      });
    }
    if (mounted) setState(() {});
  }

  Future<void> _switchToDefault() async {
    _authSubscription?.cancel();
    try {
      await _auth.signOut();
    } catch (_) {}
    _auth = FirebaseAuth.instance;
    if (kIsWeb) {
      try {
        await _auth.setPersistence(Persistence.LOCAL);
      } catch (_) {}
    }
    _authSubscription = _auth.userChanges().listen((user) async {
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _googleIdToken = null;
          _firebaseIdToken = null;
        });
        await _clearPersistedTokens();
        return;
      }
      await _rehydrateTokensIfPossible(user);
      if (!mounted) return;
      setState(() {});
    });
    _hasCustomConfig = false;
    if (mounted) setState(() {});
  }

  String _userInitials(User user) {
    final String display = (user.displayName?.trim().isNotEmpty == true)
        ? user.displayName!.trim()
        : (user.email ?? '').trim();
    if (display.isEmpty) return '?';
    final List<String> parts = display.split(RegExp(r'\s+'));
    String initials = '';
    for (final String part in parts) {
      if (part.isEmpty) continue;
      final String ch = part[0];
      if (RegExp(r'[A-Za-z]').hasMatch(ch)) {
        initials += ch.toUpperCase();
        if (initials.length == 2) break;
      }
    }
    if (initials.isEmpty) {
      initials = display[0].toUpperCase();
    }
    return initials;
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _working = true;
      _errorMessage = null;
    });
    try {
      // Ensure developer configured a custom Firebase web app before sign-in
      final bool isConfigured = await _ensureFirebaseConfigured();
      if (!isConfigured) {
        setState(() {
          _working = false;
        });
        return;
      }
      final googleProvider = GoogleAuthProvider();
      // googleProvider.addScope(
      //   'https://www.googleapis.com/auth/contacts.readonly',
      // );
      // googleProvider.setCustomParameters({'login_hint': 'user@example.com'});
      final UserCredential cred = await _auth.signInWithPopup(googleProvider);
      final OAuthCredential? oauth = cred.credential as OAuthCredential?;
      final String? googleToken = oauth?.idToken;
      final String? firebaseToken = await cred.user!.getIdToken();
      setState(() {
        _googleIdToken = googleToken;
        _firebaseIdToken = firebaseToken;
      });
      await _persistTokens(
        googleIdToken: googleToken,
        firebaseIdToken: firebaseToken,
      );
    } catch (e) {
      log(e.toString());
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _working = false;
      });
    }
  }

  Future<void> _refreshTokens() async {
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() {
      _working = true;
      _errorMessage = null;
    });
    try {
      final IdTokenResult result = await user.getIdTokenResult(true);
      final String? firebaseToken = result.token ?? await user.getIdToken();
      // For Google ID token on web, re-auth is needed; try to silently get it via reauth popup if needed.
      String? googleToken = _googleIdToken;
      try {
        final googleProvider = GoogleAuthProvider();
        final UserCredential cred = await user.reauthenticateWithPopup(
          googleProvider,
        );
        final OAuthCredential? oauth = cred.credential as OAuthCredential?;
        googleToken = oauth?.idToken ?? googleToken;
      } catch (_) {
        // Ignore if user cancels; keep previous Google token if available
      }
      setState(() {
        _firebaseIdToken = firebaseToken;
        _googleIdToken = googleToken;
      });
      await _persistTokens(
        googleIdToken: googleToken,
        firebaseIdToken: firebaseToken,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _working = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _working = true;
      _errorMessage = null;
    });
    try {
      await _auth.signOut();
      setState(() {
        _googleIdToken = null;
        _firebaseIdToken = null;
      });
      await _clearPersistedTokens();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _working = false;
      });
    }
  }

  Future<void> _persistTokens({
    String? googleIdToken,
    String? firebaseIdToken,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (googleIdToken != null) {
        await prefs.setString(_kPrefGoogleIdToken, googleIdToken);
      }
      if (firebaseIdToken != null) {
        await prefs.setString(_kPrefFirebaseIdToken, firebaseIdToken);
      }
      await prefs.setInt(
        _kPrefTokenUpdatedAtMs,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // Ignore storage errors silently
    }
  }

  Future<void> _clearPersistedTokens() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPrefGoogleIdToken);
      await prefs.remove(_kPrefFirebaseIdToken);
      await prefs.remove(_kPrefTokenUpdatedAtMs);
    } catch (_) {}
  }

  Future<void> _rehydrateTokensIfPossible(User user) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? storedGoogle = prefs.getString(_kPrefGoogleIdToken);
      String? storedFirebase = prefs.getString(_kPrefFirebaseIdToken);
      // If no firebase token stored, fetch a fresh one (session is persisted by Firebase Auth)
      storedFirebase ??= await user.getIdToken();
      if (!mounted) return;
      setState(() {
        _googleIdToken = storedGoogle;
        _firebaseIdToken = storedFirebase;
      });
      // Refresh and persist firebase token in background if needed
      try {
        final IdTokenResult fresh = await user.getIdTokenResult(true);
        final String? freshToken = fresh.token ?? storedFirebase;
        await _persistTokens(
          googleIdToken: storedGoogle,
          firebaseIdToken: freshToken,
        );
        if (!mounted) return;
        setState(() {
          _firebaseIdToken = freshToken;
        });
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _copyToClipboard(String? text) async {
    if (text == null || text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
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
          if (_hasCustomConfig)
            IconButton(
              tooltip: 'Clear configuration',
              onPressed: _working
                  ? null
                  : () async {
                      final SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.remove(_kPrefFirebaseWebConfig);
                      await _switchToDefault();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Configuration cleared. Using default.',
                          ),
                          behavior: SnackBarBehavior.floating,
                          showCloseIcon: true,
                        ),
                      );
                    },
              icon: Row(
                children: [
                  const Icon(Icons.delete_forever_rounded),
                  const Text('Clear configuration'),
                ],
              ),
            ),
          IconButton(
            tooltip: 'Firebase settings',
            onPressed: _working
                ? null
                : () async {
                    await _openSettingsDialog();
                  },
            icon: const Icon(Icons.settings_suggest_rounded),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextButton.icon(
                onPressed: _working ? null : _signOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth;
          final bool isNarrow = maxWidth < 900;
          final bool isCompact = maxWidth < 600;
          final theme = Theme.of(context);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12.0 : 24.0,
                  vertical: isCompact ? 12.0 : 20.0,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero/intro section when signed out
                      if (user == null) ...[
                        Container(
                          padding: EdgeInsets.all(isCompact ? 16 : 24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Generate Google and Firebase ID Tokens',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign in with Google to retrieve tokens for testing or backend integration. Works great on Flutter Web.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            border: Border.all(color: Colors.red.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_errorMessage!),
                        ),
                      if (user == null) ...[
                        Center(
                          child: FilledButton.icon(
                            onPressed: _working ? null : _signInWithGoogle,
                            icon: const Icon(Icons.login),
                            label: _working
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Continue with Google'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _NoticeCard(),
                      ] else ...[
                        if (isNarrow)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    foregroundImage: user.photoURL != null
                                        ? NetworkImage(user.photoURL!)
                                        : null,
                                    onForegroundImageError: (_, __) {},
                                    child: Text(
                                      _userInitials(user),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12, height: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.displayName ?? 'No name',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Text(
                                          user.email ?? 'No email',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        Text(
                                          'UID: ${user.uid}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _working ? null : _refreshTokens,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Refresh tokens'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _working ? null : _signOut,
                                    icon: const Icon(Icons.logout_rounded),
                                    label: const Text('Sign out'),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      foregroundImage: user.photoURL != null
                                          ? NetworkImage(user.photoURL!)
                                          : null,
                                      onForegroundImageError: (_, __) {},
                                      child: Text(
                                        _userInitials(user),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12, height: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.displayName ?? 'No name',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Text(
                                            user.email ?? 'No email',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          Text(
                                            'UID: ${user.uid}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _working ? null : _refreshTokens,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Refresh tokens'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _working ? null : _signOut,
                                    icon: const Icon(Icons.logout_rounded),
                                    label: const Text('Sign out'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),
                        _TokenCard(
                          title: 'Google ID Token (from Google credential)',
                          token: _googleIdToken,
                          onCopy: () => _copyToClipboard(_googleIdToken),
                        ),
                        const SizedBox(height: 12),
                        _TokenCard(
                          title: 'Firebase ID Token (from Firebase user)',
                          token: _firebaseIdToken,
                          onCopy: () => _copyToClipboard(_firebaseIdToken),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Note: Google and Firebase ID tokens are different. Use whichever your backend expects.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _NoticeCard(),
                        const SizedBox(height: 12),
                        const _AuthorCard(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _openSettingsDialog() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String existing = prefs.getString(_kPrefFirebaseWebConfig) ?? '';
    final FirebaseOptions? prefill = existing.isNotEmpty
        ? _parseOptionsFromConfigString(existing)
        : null;
    final TextEditingController apiKeyCtrl = TextEditingController(
      text: prefill?.apiKey ?? '',
    );
    final TextEditingController appIdCtrl = TextEditingController(
      text: prefill?.appId ?? '',
    );
    final TextEditingController projectIdCtrl = TextEditingController(
      text: prefill?.projectId ?? '',
    );
    final TextEditingController senderIdCtrl = TextEditingController(
      text: prefill?.messagingSenderId ?? '',
    );
    final TextEditingController authDomainCtrl = TextEditingController(
      text: prefill?.authDomain ?? '',
    );
    final TextEditingController storageBucketCtrl = TextEditingController(
      text: prefill?.storageBucket ?? '',
    );
    final TextEditingController measurementIdCtrl = TextEditingController(
      text: prefill?.measurementId ?? '',
    );
    String? error;
    bool applying = false;
    bool proceed = false;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final String currentDomain = Uri.base.host;
            return AlertDialog(
              title: const Text('Firebase Web configuration'),
              content: SizedBox(
                width: 600,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Enter your Firebase Web app config keys.'),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        border: Border.all(color: Colors.amber.shade700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Important: After saving, add your hosting domain to Firebase → Authentication → Settings → Authorized domains. For this site add "imtangim.github.io". For your own fork/custom host, add your domain as well, and add "localhost" for local dev.',
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Current domain: $currentDomain',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _copyToClipboard(currentDomain),
                                      icon: const Icon(
                                        Icons.copy_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Copy domain'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: apiKeyCtrl,
                            decoration: const InputDecoration(
                              labelText: 'apiKey *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: appIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'appId *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: projectIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'projectId *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: senderIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'messagingSenderId *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: authDomainCtrl,
                            decoration: const InputDecoration(
                              labelText: 'authDomain',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: storageBucketCtrl,
                            decoration: const InputDecoration(
                              labelText: 'storageBucket',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: measurementIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'measurementId',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if ((existing).isNotEmpty)
                  TextButton.icon(
                    onPressed: applying
                        ? null
                        : () async {
                            await prefs.remove(_kPrefFirebaseWebConfig);
                            apiKeyCtrl.clear();
                            appIdCtrl.clear();
                            projectIdCtrl.clear();
                            senderIdCtrl.clear();
                            authDomainCtrl.clear();
                            storageBucketCtrl.clear();
                            measurementIdCtrl.clear();
                            await _switchToDefault();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Configuration cleared. Using default.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  showCloseIcon: true,
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: const Text('Clear configuration'),
                  ),
                TextButton(
                  onPressed: applying
                      ? null
                      : () async {
                          // Use default app
                          await prefs.remove(_kPrefFirebaseWebConfig);
                          Navigator.of(context).pop('default');
                        },
                  child: const Text('Use default'),
                ),
                TextButton(
                  onPressed: applying
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: applying
                      ? null
                      : () async {
                          setState(() {
                            applying = true;
                            error = null;
                          });
                          final String apiKey = apiKeyCtrl.text.trim();
                          final String appId = appIdCtrl.text.trim();
                          final String projectId = projectIdCtrl.text.trim();
                          final String senderId = senderIdCtrl.text.trim();
                          if (apiKey.isEmpty ||
                              appId.isEmpty ||
                              projectId.isEmpty ||
                              senderId.isEmpty) {
                            setState(() {
                              applying = false;
                              error = 'Please fill all required fields (*).';
                            });
                            return;
                          }
                          final Map<String, dynamic> jsonMap = {
                            'apiKey': apiKey,
                            'appId': appId,
                            'projectId': projectId,
                            'messagingSenderId': senderId,
                          };
                          final String authDomain = authDomainCtrl.text.trim();
                          final String storageBucket = storageBucketCtrl.text
                              .trim();
                          final String measurementId = measurementIdCtrl.text
                              .trim();
                          if (authDomain.isNotEmpty) {
                            jsonMap['authDomain'] = authDomain;
                          }
                          if (storageBucket.isNotEmpty) {
                            jsonMap['storageBucket'] = storageBucket;
                          }
                          if (measurementId.isNotEmpty) {
                            jsonMap['measurementId'] = measurementId;
                          }
                          final String normalized = json.encode(jsonMap);
                          await prefs.setString(
                            _kPrefFirebaseWebConfig,
                            normalized,
                          );
                          final FirebaseOptions options = FirebaseOptions(
                            apiKey: apiKey,
                            appId: appId,
                            projectId: projectId,
                            messagingSenderId: senderId,
                            authDomain: authDomain.isEmpty ? null : authDomain,
                            storageBucket: storageBucket.isEmpty
                                ? null
                                : storageBucket,
                            measurementId: measurementId.isEmpty
                                ? null
                                : measurementId,
                          );
                          Navigator.of(context).pop(options);
                        },
                  child: const Text('Save & Apply'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) async {
      if (result == null) return;
      if (result == 'default') {
        await _switchToDefault();
        if (!mounted) return;
        setState(() {
          _errorMessage = null;
          _googleIdToken = null;
          _firebaseIdToken = null;
        });
        proceed = true;
        return;
      }
      if (result is FirebaseOptions) {
        await _switchToOptions(result, subscribe: true);
        if (!mounted) return;
        setState(() {
          _errorMessage = null;
          _googleIdToken = null;
          _firebaseIdToken = null;
        });
        proceed = true;
      }
    });
    return proceed;
  }

  Future<bool> _ensureFirebaseConfigured() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kPrefFirebaseWebConfig);
      // If a custom config is present and valid, assume configured
      if (raw != null && raw.trim().isNotEmpty) {
        final FirebaseOptions? options = _parseOptionsFromConfigString(raw);
        if (options != null) {
          return true;
        }
      }
      // Otherwise ask user to configure now
      final bool applied = await _openSettingsDialog();
      return applied;
    } catch (_) {
      // If anything goes wrong, require explicit configuration
      final bool applied = await _openSettingsDialog();
      return applied;
    }
  }
}

class _TokenCard extends StatelessWidget {
  final String title;
  final String? token;
  final VoidCallback onCopy;

  const _TokenCard({
    required this.title,
    required this.token,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Copy token to clipboard',
                  child: TextButton.icon(
                    onPressed: token == null || token!.isEmpty ? null : onCopy,
                    icon: const Icon(Icons.copy_all_rounded),
                    label: const Text('Copy'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(minHeight: 64, maxHeight: 260),
              child: SingleChildScrollView(
                child: SelectableText(
                  token ?? '—',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.privacy_tip_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy & Purpose',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We do not store or share any of your data. This site is intended solely for backend testing and development workflows.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard();

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    )) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.person_pin_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Created by Tangim Haque',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            _openUrl('https://github.com/imtangim'),
                        icon: const Icon(Icons.link_rounded),
                        label: const Text('GitHub Profile'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openUrl(
                          'https://github.com/imtangim/google-id-token-generator',
                        ),
                        icon: const Icon(Icons.code_rounded),
                        label: const Text('Source Code'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openUrl(
                          'https://imtangim.github.io/google-id-token-generator/',
                        ),
                        icon: const Icon(Icons.public_rounded),
                        label: const Text('Live Site'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
