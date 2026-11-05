import 'package:flutter/material.dart';

enum StateKind { loading, error, empty }

/// Widget reusable untuk 3 kondisi state:
/// - Loading: indikator progress berputar halus
/// - Error: ikon peringatan dengan tombol coba lagi
/// - Empty: ilustrasi kotak kosong dengan pesan ramah
class StateView extends StatelessWidget {
  final StateKind kind;
  final String message;
  final VoidCallback? onRetry;

  const StateView.loading({super.key})
    : kind = StateKind.loading,
      message = 'Sedang memuat data film...',
      onRetry = null;

  const StateView.error({super.key, required this.message, this.onRetry})
    : kind = StateKind.error;

  const StateView.empty({super.key, required this.message})
    : kind = StateKind.empty,
      onRetry = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (kind == StateKind.loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final isError = kind == StateKind.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.movie_outlined,
              size: 40,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
