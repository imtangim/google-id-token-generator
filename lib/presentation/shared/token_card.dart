import 'package:flutter/material.dart';

class TokenCard extends StatelessWidget {
  const TokenCard({
    super.key,
    required this.title,
    required this.token,
    required this.onCopy,
  });

  final String title;
  final String? token;
  final VoidCallback onCopy;

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
