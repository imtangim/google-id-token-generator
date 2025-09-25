import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthorCard extends StatelessWidget {
  const AuthorCard({super.key});

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
