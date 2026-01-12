import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_config_dialog.dart';
import '../../../core/constants.dart';

class ConfigRequiredPage extends StatefulWidget {
  const ConfigRequiredPage({super.key});

  @override
  State<ConfigRequiredPage> createState() => _ConfigRequiredPageState();
}

class _ConfigRequiredPageState extends State<ConfigRequiredPage> {
  bool _isConfiguring = false;

  Future<void> _openConfigDialog() async {
    setState(() {
      _isConfiguring = true;
    });
    
    final bool configured = await FirebaseConfigDialog.show(context);
    
    setState(() {
      _isConfiguring = false;
    });
    
    if (configured && mounted) {
      // Check if config was actually saved
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(AppPrefsKeys.firebaseWebConfig);
      
      if (raw != null && raw.trim().isNotEmpty) {
        // Automatically reload the page
        if (kIsWeb) {
          html.window.location.reload();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.settings_applications_rounded,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Firebase Configuration Required',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Before you can use this app, you need to configure your Firebase Web app settings.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You can find these settings in your Firebase Console:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Firebase Console → Project Settings → Your apps → Web app → Config',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _isConfiguring ? null : _openConfigDialog,
                  icon: _isConfiguring
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.settings_rounded),
                  label: Text(_isConfiguring ? 'Opening configuration...' : 'Configure Firebase'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

