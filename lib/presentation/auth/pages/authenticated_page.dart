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

class AuthenticatedPage extends StatelessWidget {
  const AuthenticatedPage({super.key, required this.user});
  final User user;

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
                    FutureBuilder<_Tokens>(
                      future: _loadTokens(),
                      builder: (context, snapshot) {
                        final _Tokens tokens = snapshot.data ?? const _Tokens();
                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TokenCard(
                                title:
                                    'Google ID Token (from Google credential)',
                                token: tokens.googleIdToken,
                                onCopy: () => _copyToClipboard(
                                  context,
                                  tokens.googleIdToken,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TokenCard(
                                title: 'Firebase ID Token (from Firebase user)',
                                token: tokens.firebaseIdToken,
                                onCopy: () => _copyToClipboard(
                                  context,
                                  tokens.firebaseIdToken,
                                ),
                              ),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TokenCard(
                                title:
                                    'Google ID Token (from Google credential)',
                                token: tokens.googleIdToken,
                                onCopy: () => _copyToClipboard(
                                  context,
                                  tokens.googleIdToken,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TokenCard(
                                title: 'Firebase ID Token (from Firebase user)',
                                token: tokens.firebaseIdToken,
                                onCopy: () => _copyToClipboard(
                                  context,
                                  tokens.firebaseIdToken,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Note: Google and Firebase ID tokens are different. Use whichever your backend expects.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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

  Future<_Tokens> _loadTokens() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return _Tokens(
        googleIdToken: prefs.getString(AppPrefsKeys.googleIdToken),
        firebaseIdToken: prefs.getString(AppPrefsKeys.firebaseIdToken),
      );
    } catch (_) {
      return const _Tokens();
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

class _Tokens {
  const _Tokens({this.googleIdToken, this.firebaseIdToken});
  final String? googleIdToken;
  final String? firebaseIdToken;
}
