import 'package:flutter/material.dart';

class TokenCard extends StatelessWidget {
  const TokenCard({
    super.key,
    required this.title,
    required this.token,
    required this.onCopy,
    this.expirationTime,
    this.timeRemaining,
    this.isExpired,
    this.isExpiringSoon = false,
  });

  final String title;
  final String? token;
  final VoidCallback onCopy;
  final DateTime? expirationTime;
  final Duration? timeRemaining;
  final bool? isExpired;
  final bool isExpiringSoon;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          if (isExpired == true)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 14,
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expired',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (isExpiringSoon)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 14,
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expiring Soon',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (isExpired == false && expirationTime != null)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 14,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Valid',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (expirationTime != null || timeRemaining != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatExpirationInfo(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
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

  String _formatExpirationInfo() {
    if (isExpired == true && expirationTime != null) {
      final expiredAgo = DateTime.now().difference(expirationTime!);
      if (expiredAgo.inDays > 0) {
        return 'Expired ${expiredAgo.inDays} day${expiredAgo.inDays > 1 ? 's' : ''} ago (${expirationTime!.toLocal().toString().split('.')[0]})';
      } else if (expiredAgo.inHours > 0) {
        return 'Expired ${expiredAgo.inHours} hour${expiredAgo.inHours > 1 ? 's' : ''} ago (${expirationTime!.toLocal().toString().split('.')[0]})';
      } else if (expiredAgo.inMinutes > 0) {
        return 'Expired ${expiredAgo.inMinutes} minute${expiredAgo.inMinutes > 1 ? 's' : ''} ago (${expirationTime!.toLocal().toString().split('.')[0]})';
      } else {
        return 'Expired ${expiredAgo.inSeconds} second${expiredAgo.inSeconds > 1 ? 's' : ''} ago (${expirationTime!.toLocal().toString().split('.')[0]})';
      }
    } else if (timeRemaining != null && !timeRemaining!.isNegative) {
      final remaining = timeRemaining!;
      String remainingStr;
      if (remaining.inDays > 0) {
        remainingStr = '${remaining.inDays}d ${remaining.inHours.remainder(24)}h remaining';
      } else if (remaining.inHours > 0) {
        remainingStr = '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m remaining';
      } else if (remaining.inMinutes > 0) {
        remainingStr = '${remaining.inMinutes}m ${remaining.inSeconds.remainder(60)}s remaining';
      } else {
        remainingStr = '${remaining.inSeconds}s remaining';
      }
      if (expirationTime != null) {
        return '$remainingStr • Expires: ${expirationTime!.toLocal().toString().split('.')[0]}';
      }
      return remainingStr;
    } else if (expirationTime != null) {
      return 'Expires: ${expirationTime!.toLocal().toString().split('.')[0]}';
    }
    return '';
  }
}
