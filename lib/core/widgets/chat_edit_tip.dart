import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';

/// A subtle hint that the user can also edit this item conversationally in chat.
/// `example` is a short quoted phrase, e.g. '"move my dentist reminder to 6pm"'.
class ChatEditTip extends StatelessWidget {
  const ChatEditTip({super.key, required this.example});

  final String example;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: AppRadii.rMd,
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Tip: just ask AIVA in chat — e.g. '),
                  TextSpan(
                    text: example,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: context.palette.muted),
            ),
          ),
        ],
      ),
    );
  }
}
