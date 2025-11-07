import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import '../onboarding_controller.dart';
import '../../../core/focus_shield/focus_shield_channel.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const PermissionsScreen({super.key, required this.onNext, this.onBack});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  bool _notificationsEnabled = false;
  bool _doNotDisturbEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = ref
        .read(onboardingControllerProvider)
        .notificationsEnabled;
    _doNotDisturbEnabled = ref
        .read(onboardingControllerProvider)
        .doNotDisturbEnabled;

    // Check DND permission status on init
    _checkDNDPermission();
  }

  Future<void> _checkDNDPermission() async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      final hasPermission = await FocusShieldChannel.hasDNDPermission();
      if (mounted) {
        setState(() {
          _doNotDisturbEnabled = hasPermission;
        });
        ref
            .read(onboardingControllerProvider.notifier)
            .updateDoNotDisturb(hasPermission);
      }
    } catch (e) {
      debugPrint('Error checking DND permission: $e');
    }
  }

  Future<void> _requestNotificationPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await Permission.notification.request();
      setState(() {
        _notificationsEnabled = status.isGranted;
      });

      ref
          .read(onboardingControllerProvider.notifier)
          .updateNotifications(_notificationsEnabled);
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestDoNotDisturbPermission() async {
    if (!Platform.isAndroid) {
      // DND is Android-only
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Do Not Disturb is only available on Android'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if permission is already granted
      final hasPermission = await FocusShieldChannel.hasDNDPermission();
      if (hasPermission) {
        setState(() {
          _doNotDisturbEnabled = true;
          _isLoading = false;
        });
        ref
            .read(onboardingControllerProvider.notifier)
            .updateDoNotDisturb(true);
        return;
      }

      // Open DND settings screen
      final success = await FocusShieldChannel.openDNPSettings();
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Opening DND settings... Please grant permission and return to the app.',
            ),
            duration: Duration(seconds: 3),
          ),
        );

        // Poll for permission after returning from settings
        // Check every second for up to 10 seconds
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) break;

          final granted = await FocusShieldChannel.hasDNDPermission();
          if (granted) {
            setState(() {
              _doNotDisturbEnabled = true;
              _isLoading = false;
            });
            ref
                .read(onboardingControllerProvider.notifier)
                .updateDoNotDisturb(true);
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('DND permission granted!')),
              );
            }
            return;
          }
        }

        // Re-check permission one more time
        final finalCheck = await FocusShieldChannel.hasDNDPermission();
        setState(() {
          _doNotDisturbEnabled = finalCheck;
          _isLoading = false;
        });
        ref
            .read(onboardingControllerProvider.notifier)
            .updateDoNotDisturb(finalCheck);

        if (mounted && !finalCheck) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'DND permission not granted. You can enable it later in settings.',
              ),
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to open DND settings')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error requesting DND permission: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      'Permissions',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 20 : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              SizedBox(height: isSmallScreen ? 12 : 16),

              Text(
                'Help us help you stay focused',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: isSmallScreen ? 18 : null,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isSmallScreen ? 24 : 48),

              // Permissions List
              Column(
                children: [
                  _buildPermissionCard(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    description:
                        'Allow notifications so we can remind you when your break is over?',
                    isEnabled: _notificationsEnabled,
                    onToggle: _requestNotificationPermission,
                    theme: theme,
                    isSmallScreen: isSmallScreen,
                  ),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  _buildPermissionCard(
                    icon: Icons.do_not_disturb,
                    title: 'Do Not Disturb',
                    description:
                        'Enable Do Not Disturb during focus sessions to stay distraction-free?',
                    isEnabled: _doNotDisturbEnabled,
                    onToggle: _requestDoNotDisturbPermission,
                    theme: theme,
                    isSmallScreen: isSmallScreen,
                  ),
                ],
              ),

              SizedBox(height: isSmallScreen ? 20 : 24),

              // Skip or Continue
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onNext,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Maybe Later'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: isSmallScreen ? 48 : 56,
                      child: FilledButton(
                        onPressed: _isLoading ? null : widget.onNext,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Allow',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isEnabled,
    required VoidCallback onToggle,
    required ThemeData theme,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: isEnabled
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: isEnabled ? 2 : 1,
        ),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: isSmallScreen ? 50 : 60,
            height: isSmallScreen ? 50 : 60,
            decoration: BoxDecoration(
              color: isEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isEnabled ? Colors.white : theme.colorScheme.primary,
              size: isSmallScreen ? 24 : 30,
            ),
          ),

          SizedBox(width: isSmallScreen ? 12 : 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isEnabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontSize: isSmallScreen ? 14 : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                    fontSize: isSmallScreen ? 12 : null,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: isSmallScreen ? 12 : 16),

          // Toggle Button
          if (isEnabled)
            Container(
              width: isSmallScreen ? 20 : 24,
              height: isSmallScreen ? 20 : 24,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: isSmallScreen ? 12 : 16,
              ),
            )
          else
            TextButton(
              onPressed: onToggle,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 6 : 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Allow',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 12 : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
