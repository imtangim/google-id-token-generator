import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';

class FirebaseConfigDialog {
  static Future<bool> show(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String existing =
        prefs.getString(AppPrefsKeys.firebaseWebConfig) ?? '';

    final Map<String, dynamic>? prefill = _tryParseJson(existing);
    final TextEditingController apiKeyCtrl = TextEditingController(
      text: prefill?['apiKey'] ?? '',
    );
    final TextEditingController appIdCtrl = TextEditingController(
      text: prefill?['appId'] ?? '',
    );
    final TextEditingController projectIdCtrl = TextEditingController(
      text: prefill?['projectId'] ?? '',
    );
    final TextEditingController senderIdCtrl = TextEditingController(
      text: prefill?['messagingSenderId']?.toString() ?? '',
    );
    final TextEditingController authDomainCtrl = TextEditingController(
      text: prefill?['authDomain'] ?? '',
    );
    final TextEditingController storageBucketCtrl = TextEditingController(
      text: prefill?['storageBucket'] ?? '',
    );
    final TextEditingController measurementIdCtrl = TextEditingController(
      text: prefill?['measurementId'] ?? '',
    );

    String? error;
    bool applying = false;
    bool result = false;

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
                                  'Important: After saving, add your hosting domain to Firebase → Authentication → Settings → Authorized domains. Add your domain and "localhost" for local dev.',
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
                            await prefs.remove(AppPrefsKeys.firebaseWebConfig);
                            apiKeyCtrl.clear();
                            appIdCtrl.clear();
                            projectIdCtrl.clear();
                            senderIdCtrl.clear();
                            authDomainCtrl.clear();
                            storageBucketCtrl.clear();
                            measurementIdCtrl.clear();
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
                            AppPrefsKeys.firebaseWebConfig,
                            normalized,
                          );
                          result = true;
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                  child: const Text('Save & Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  static Map<String, dynamic>? _tryParseJson(String raw) {
    try {
      // If provided a JS snippet, carve out the JSON object
      String text = raw.trim();
      final int firstBrace = text.indexOf('{');
      final int lastBrace = text.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        text = text.substring(firstBrace, lastBrace + 1);
      }
      return json.decode(text) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
