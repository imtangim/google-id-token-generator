import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../shared/notice_card.dart';
import '../../shared/author_card.dart';
import '../../shared/token_card.dart';
import '../../../core/constants.dart';
import '../../../core/token_validator.dart';
import '../../../domain/auth/auth_repository.dart';

class AuthenticatedPage extends StatefulWidget {
  const AuthenticatedPage({super.key, required this.user});
  final User user;

  @override
  State<AuthenticatedPage> createState() => _AuthenticatedPageState();
}

class _AuthenticatedPageState extends State<AuthenticatedPage> {
  Timer? _tokenCheckTimer;
  Timer? _uiUpdateTimer;
  int _tick = 0; // Used to force rebuilds for countdown updates
  static const Duration _tokenCheckInterval = Duration(minutes: 1);
  static const Duration _uiUpdateInterval = Duration(seconds: 1); // Update UI every second
  static const Duration _expiringSoonThreshold = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    // Check tokens periodically for auto-refresh
    _tokenCheckTimer = Timer.periodic(_tokenCheckInterval, (_) {
      _checkAndRefreshTokensIfNeeded();
    });
    // Update UI every second to refresh countdown
    _uiUpdateTimer = Timer.periodic(_uiUpdateInterval, (_) {
      if (mounted) {
        setState(() {
          _tick++; // Increment to trigger rebuild
        });
      }
    });
    // Initial check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRefreshTokensIfNeeded();
    });
  }

  @override
  void dispose() {
    _tokenCheckTimer?.cancel();
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAndRefreshTokensIfNeeded() async {
    if (!mounted) return;
    final bloc = context.read<AuthBloc>();
    if (bloc.state.isBusy) return;

    try {
      final tokens = await _loadTokensWithExpiration(context);
      
      // Check if tokens are expired or expiring soon
      bool needsRefresh = false;
      
      if (tokens.googleIdToken != null) {
        final isExpired = TokenValidator.isExpired(tokens.googleIdToken!);
        final willExpireSoon = TokenValidator.willExpireWithin(
          tokens.googleIdToken!,
          _expiringSoonThreshold,
        );
        if (isExpired == true || willExpireSoon) {
          needsRefresh = true;
        }
      }
      
      if (tokens.firebaseIdToken != null) {
        final isExpired = TokenValidator.isExpired(tokens.firebaseIdToken!);
        final willExpireSoon = TokenValidator.willExpireWithin(
          tokens.firebaseIdToken!,
          _expiringSoonThreshold,
        );
        if (isExpired == true || willExpireSoon) {
          needsRefresh = true;
        }
      }

      if (needsRefresh && mounted && !bloc.state.isBusy) {
        bloc.add(const AuthRefreshRequested());
      }
    } catch (_) {
      // Ignore errors in automatic refresh check
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.user;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final bool isNarrow = maxWidth < 900;
        final bool isCompact = maxWidth < 600;
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
                    if (isNarrow)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                onPressed: context.read<AuthBloc>().state.isBusy
                                    ? null
                                    : () => context.read<AuthBloc>().add(
                                        const AuthRefreshRequested(),
                                      ),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Refresh tokens'),
                              ),
                              OutlinedButton.icon(
                                onPressed: context.read<AuthBloc>().state.isBusy
                                    ? null
                                    : () => context.read<AuthBloc>().add(
                                        const AuthSignOutRequested(),
                                      ),
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
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
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
                                onPressed: context.read<AuthBloc>().state.isBusy
                                    ? null
                                    : () => context.read<AuthBloc>().add(
                                        const AuthRefreshRequested(),
                                      ),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Refresh tokens'),
                              ),
                              OutlinedButton.icon(
                                onPressed: context.read<AuthBloc>().state.isBusy
                                    ? null
                                    : () => context.read<AuthBloc>().add(
                                        const AuthSignOutRequested(),
                                      ),
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text('Sign out'),
                              ),
                            ],
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),
                    BlocBuilder<AuthBloc, AuthState>(
                      buildWhen: (previous, current) =>
                          previous.tokensRefreshTimestamp !=
                          current.tokensRefreshTimestamp ||
                          previous.isBusy != current.isBusy,
                      builder: (context, state) {
                        // Listen to _tick changes to trigger rebuilds for countdown
                        // _tick is incremented every second via setState to force UI updates
                        // Using Builder to ensure rebuilds when _tick changes
                        return Builder(
                          builder: (context) {
                            // Reference _tick to ensure rebuilds when it changes
                            final _ = _tick;
                            return _buildTokenCards(context, state);
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final theme = Theme.of(context);
                        return Text(
                          'Note: Google and Firebase ID tokens are different. Use whichever your backend expects.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const NoticeCard(),
                    const SizedBox(height: 12),
                    const AuthorCard(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTokenCards(BuildContext context, AuthState state) {
    // This method is called every second when _tick changes (via setState)
    // Access isNarrow from the LayoutBuilder context
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 900;
        return FutureBuilder<_TokenInfo>(
          future: _loadTokensWithExpiration(context),
          builder: (context, snapshot) {
            final _TokenInfo tokens = snapshot.data ?? const _TokenInfo();
            
            // Recalculate time remaining dynamically based on current time
            // This ensures the countdown updates every second without restarting the future
            Duration? googleTimeRemaining = tokens.googleExpiration != null
                ? tokens.googleExpiration!.difference(DateTime.now().toUtc())
                : null;
            Duration? firebaseTimeRemaining = tokens.firebaseExpiration != null
                ? tokens.firebaseExpiration!.difference(DateTime.now().toUtc())
                : null;
            
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TokenCard(
                    title: 'Google ID Token (from Google credential)',
                    token: tokens.googleIdToken,
                    onCopy: () => _copyToClipboard(context, tokens.googleIdToken),
                    expirationTime: tokens.googleExpiration,
                    timeRemaining: googleTimeRemaining,
                    isExpired: tokens.googleExpiration != null
                        ? googleTimeRemaining?.isNegative ?? false
                        : null,
                    isExpiringSoon: googleTimeRemaining != null &&
                        !googleTimeRemaining.isNegative &&
                        googleTimeRemaining <= _expiringSoonThreshold,
                  ),
                  const SizedBox(height: 12),
                  TokenCard(
                    title: 'Firebase ID Token (from Firebase user)',
                    token: tokens.firebaseIdToken,
                    onCopy: () => _copyToClipboard(context, tokens.firebaseIdToken),
                    expirationTime: tokens.firebaseExpiration,
                    timeRemaining: firebaseTimeRemaining,
                    isExpired: tokens.firebaseExpiration != null
                        ? firebaseTimeRemaining?.isNegative ?? false
                        : null,
                    isExpiringSoon: firebaseTimeRemaining != null &&
                        !firebaseTimeRemaining.isNegative &&
                        firebaseTimeRemaining <= _expiringSoonThreshold,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TokenCard(
                    title: 'Google ID Token (from Google credential)',
                    token: tokens.googleIdToken,
                    onCopy: () => _copyToClipboard(context, tokens.googleIdToken),
                    expirationTime: tokens.googleExpiration,
                    timeRemaining: googleTimeRemaining,
                    isExpired: tokens.googleExpiration != null
                        ? googleTimeRemaining?.isNegative ?? false
                        : null,
                    isExpiringSoon: googleTimeRemaining != null &&
                        !googleTimeRemaining.isNegative &&
                        googleTimeRemaining <= _expiringSoonThreshold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TokenCard(
                    title: 'Firebase ID Token (from Firebase user)',
                    token: tokens.firebaseIdToken,
                    onCopy: () => _copyToClipboard(context, tokens.firebaseIdToken),
                    expirationTime: tokens.firebaseExpiration,
                    timeRemaining: firebaseTimeRemaining,
                    isExpired: tokens.firebaseExpiration != null
                        ? firebaseTimeRemaining?.isNegative ?? false
                        : null,
                    isExpiringSoon: firebaseTimeRemaining != null &&
                        !firebaseTimeRemaining.isNegative &&
                        firebaseTimeRemaining <= _expiringSoonThreshold,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<_TokenInfo> _loadTokensWithExpiration(BuildContext context) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final googleIdToken = prefs.getString(AppPrefsKeys.googleIdToken);
      final firebaseIdToken = prefs.getString(AppPrefsKeys.firebaseIdToken);

      // Get expiration info for Google token
      DateTime? googleExpiration;
      Duration? googleTimeRemaining;
      if (googleIdToken != null) {
        googleExpiration = TokenValidator.getExpirationTime(googleIdToken);
        googleTimeRemaining = TokenValidator.getTimeUntilExpiration(googleIdToken);
      }

      // Get expiration info for Firebase token
      DateTime? firebaseExpiration;
      Duration? firebaseTimeRemaining;
      if (firebaseIdToken != null) {
        // Try to get from Firebase Auth first (more reliable)
        try {
          final repository = context.read<AuthRepository>();
          final firebaseExp = await repository.getFirebaseTokenExpiration();
          if (firebaseExp != null) {
            firebaseExpiration = firebaseExp;
            firebaseTimeRemaining = firebaseExp.difference(DateTime.now().toUtc());
          } else {
            // Fallback to JWT decoding
            firebaseExpiration = TokenValidator.getExpirationTime(firebaseIdToken);
            firebaseTimeRemaining = TokenValidator.getTimeUntilExpiration(firebaseIdToken);
          }
        } catch (_) {
          // Fallback to JWT decoding
          firebaseExpiration = TokenValidator.getExpirationTime(firebaseIdToken);
          firebaseTimeRemaining = TokenValidator.getTimeUntilExpiration(firebaseIdToken);
        }
      }

      return _TokenInfo(
        googleIdToken: googleIdToken,
        firebaseIdToken: firebaseIdToken,
        googleExpiration: googleExpiration,
        googleTimeRemaining: googleTimeRemaining,
        firebaseExpiration: firebaseExpiration,
        firebaseTimeRemaining: firebaseTimeRemaining,
      );
    } catch (_) {
      return const _TokenInfo();
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String? text) async {
    if (text == null || text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
        ),
      );
    }
  }
}

class _TokenInfo {
  const _TokenInfo({
    this.googleIdToken,
    this.firebaseIdToken,
    this.googleExpiration,
    this.googleTimeRemaining,
    this.firebaseExpiration,
    this.firebaseTimeRemaining,
  });

  final String? googleIdToken;
  final String? firebaseIdToken;
  final DateTime? googleExpiration;
  final Duration? googleTimeRemaining;
  final DateTime? firebaseExpiration;
  final Duration? firebaseTimeRemaining;
}
