import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../shared/notice_card.dart';
import '../../shared/author_card.dart';
import '../../../core/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../settings/firebase_config_dialog.dart';

class UnauthenticatedPage extends StatelessWidget {
  const UnauthenticatedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              showCloseIcon: true,
            ),
          );
        }
      },
      child: Builder(
        builder: (context) {
          final isBusy = context.watch<AuthBloc>().state.isBusy;
          return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant),
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
          Center(
            child: FilledButton.icon(
              onPressed: isBusy
                  ? null
                  : () async {
                      final SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      final String? raw = prefs.getString(
                        AppPrefsKeys.firebaseWebConfig,
                      );
                      if (raw == null || raw.trim().isEmpty) {
                        final bool applied = await FirebaseConfigDialog.show(
                          context,
                        );
                        if (!applied) return;
                      }
                      if (context.mounted) {
                        context.read<AuthBloc>().add(
                          const AuthSignInRequested(),
                        );
                      }
                    },
              icon: const Icon(Icons.login),
              label: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue with Google'),
            ),
          ),
          const SizedBox(height: 12),
          const NoticeCard(),
          const SizedBox(height: 12),
          const AuthorCard(),
        ],
      ),
          );
        },
      ),
    );
  }
}
