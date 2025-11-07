import 'package:flutter/material.dart';

/// Reusable error state widget with retry functionality
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.title,
    this.details,
  });

  final String message;
  final VoidCallback onRetry;
  final String? title;
  final String? details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 24),
            Text(
              title ?? 'Something Went Wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper to parse Firebase errors into user-friendly messages
class ErrorMessageHelper {
  static String getUserFriendlyMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('internet')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }

    // Firebase auth errors
    if (errorString.contains('network-request-failed')) {
      return 'Network connection failed. Please check your internet and try again.';
    }

    if (errorString.contains('too-many-requests')) {
      return 'Too many requests. Please wait a moment and try again.';
    }

    if (errorString.contains('user-not-found') ||
        errorString.contains('invalid-credential')) {
      return 'Invalid login credentials. Please check your email and password.';
    }

    if (errorString.contains('email-already-in-use')) {
      return 'This email is already registered. Please sign in or use a different email.';
    }

    if (errorString.contains('weak-password')) {
      return 'Password is too weak. Please use a stronger password (at least 6 characters).';
    }

    // Firestore errors
    if (errorString.contains('permission-denied')) {
      return 'You don\'t have permission to perform this action.';
    }

    if (errorString.contains('unavailable')) {
      return 'Service temporarily unavailable. Please try again in a moment.';
    }

    if (errorString.contains('deadline-exceeded') ||
        errorString.contains('timeout')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    // Generic fallback
    return 'An error occurred. Please try again. If the problem persists, contact support.';
  }

  static String? getErrorDetails(Object error) {
    final errorString = error.toString();

    // Only show technical details for development
    if (errorString.contains('Exception:') || errorString.contains('Error:')) {
      // Extract the actual error message after the prefix
      final match = RegExp(
        r'(Exception|Error):\s*(.+)',
      ).firstMatch(errorString);
      if (match != null && match.groupCount >= 2) {
        return match.group(2);
      }
    }

    return null;
  }
}
