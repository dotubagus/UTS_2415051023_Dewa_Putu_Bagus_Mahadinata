import 'package:flutter/material.dart';

enum StateKind { loading, error, empty }

/// Satu widget untuk tiga kondisi: loading, error, empty.
class StateView extends StatelessWidget {
  final StateKind kind;
  final String message;
  final VoidCallback? onRetry;

  const StateView.loading({super.key})
      : kind = StateKind.loading,
        message = 'Memuat...',
        onRetry = null;

  const StateView.error({super.key, required this.message, this.onRetry})
      : kind = StateKind.error;

  const StateView.empty({super.key, required this.message})
      : kind = StateKind.empty,
        onRetry = null;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (kind == StateKind.loading)
              const CircularProgressIndicator()
            else
              Icon(
                kind == StateKind.error
                    ? Icons.error_outline
                    : Icons.movie_outlined,
                size: 56,
                color: color,
              ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
            ],
          ],
        ),
      ),
    );
  }
}