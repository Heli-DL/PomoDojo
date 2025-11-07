import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../features/progression/martial_rank.dart';

class CelebrationScreen extends StatefulWidget {
  const CelebrationScreen({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    this.description,
    this.icon,
    this.color,
    this.onContinue,
    this.buttonText,
    this.onClose,
    this.martialRank,
  });

  final CelebrationType type;
  final String title;
  final String subtitle;
  final String? description;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onContinue;
  final String? buttonText;
  final VoidCallback? onClose;
  final MartialRank? martialRank;

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  void _startAnimations() {
    // Add a small delay to ensure the screen is fully rendered
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _scaleController.forward();
          }
        });
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            _slideController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      final theme = Theme.of(context);
      final screenSize = MediaQuery.of(context).size;
      final isSmallScreen = screenSize.height < 600;

      return Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: isSmallScreen ? screenSize.height * 0.8 : 600,
            ),
            child: Material(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              elevation: 4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with close button
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () {
                                debugPrint('X button pressed');
                                // Close dialog first
                                if (widget.onClose != null) {
                                  widget.onClose!();
                                } else if (Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).canPop()) {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop();
                                }
                                // Call onContinue after closing (for chaining celebrations) only if provided
                                if (widget.onContinue != null) {
                                  Future.microtask(() {
                                    widget.onContinue!();
                                  });
                                }
                                debugPrint('Dialog closed via X button');
                              },
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Celebration content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: widget.type == CelebrationType.levelUp
                                    ? 8
                                    : 16,
                              ),
                              // Animation/Icon
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: _buildCelebrationIcon(theme),
                              ),
                              SizedBox(
                                height: widget.type == CelebrationType.levelUp
                                    ? 6
                                    : 24,
                              ),
                              // Title
                              SlideTransition(
                                position: _slideAnimation,
                                child: Text(
                                  widget.title,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            widget.color ??
                                            theme.colorScheme.primary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                height: widget.type == CelebrationType.levelUp
                                    ? 8
                                    : 16,
                              ),

                              // Subtitle
                              SlideTransition(
                                position: _slideAnimation,
                                child: Text(
                                  widget.subtitle,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              if (widget.description != null) ...[
                                SizedBox(
                                  height: widget.type == CelebrationType.levelUp
                                      ? 8
                                      : 16,
                                ),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: Text(
                                    widget.description!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],

                              SizedBox(
                                height: widget.type == CelebrationType.levelUp
                                    ? 12
                                    : 32,
                              ),

                              // Continue button
                              SlideTransition(
                                position: _slideAnimation,
                                child: _buildContinueButton(theme),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error building CelebrationScreen: $e');
      debugPrint('Stack trace: $stackTrace');
      // Return a simple error widget instead of crashing
      try {
        final theme = Theme.of(context);
        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.8),
          body: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    size: 60,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      if (context.mounted && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      widget.onContinue?.call();
                    },
                    child: Text(widget.buttonText ?? 'Close'),
                  ),
                ],
              ),
            ),
          ),
        );
      } catch (e2) {
        debugPrint('Error building fallback widget: $e2');
        // Last resort - return empty widget
        return const SizedBox.shrink();
      }
    }
  }

  Widget _buildCelebrationIcon(ThemeData theme) {
    final color = widget.color ?? theme.colorScheme.primary;
    final size = 120.0;

    switch (widget.type) {
      case CelebrationType.achievement:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 3),
          ),
          child: Icon(
            widget.icon ?? Icons.emoji_events,
            size: 60,
            color: color,
          ),
        );

      case CelebrationType.levelUp:
        // Show sprite animation directly without background
        // Sprite sheet has 36 frames with 6 frames per row (6x6)
        return SpriteSheetAnimation(
          assetPath: 'assets/images/sprites/happy_monkey.png',
          columns: 6,
          rows: 6,
          fps: 16,
          scaleTo: const Size(250, 250),
          fallback: Icon(Icons.trending_up, size: 120, color: color),
        );

      case CelebrationType.rankUp:
        // Show character image if rank is provided
        if (widget.martialRank != null) {
          final rankName = widget.martialRank!.name.toLowerCase();
          final imagePath = 'assets/images/${rankName}_1.png';
          // Use larger size for character image
          final characterSize = 180.0;

          return Container(
            width: characterSize,
            height: characterSize,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                imagePath,
                width: characterSize,
                height: characterSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to icon if image not found
                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          color,
                          color.withValues(alpha: 0.8),
                          color.withValues(alpha: 0.6),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.martialRank!.icon,
                      size: 90,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          );
        }
        // Fallback to icon if no rank provided
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: 0.8),
                color.withValues(alpha: 0.6),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.star, size: 60, color: Colors.white),
        );

      case CelebrationType.backgroundUnlock:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.image, size: 60, color: Colors.white),
        );
    }
  }

  Widget _buildContinueButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () {
          debugPrint('Close button pressed');
          // Close dialog first
          if (widget.onClose != null) {
            widget.onClose!();
          } else if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          // Call onContinue after closing (for chaining celebrations) only if provided
          if (widget.onContinue != null) {
            Future.microtask(() {
              widget.onContinue!();
            });
          }
          debugPrint('Dialog closed via close button');
        },
        style: FilledButton.styleFrom(
          backgroundColor: widget.color ?? theme.colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          widget.buttonText ?? 'Continue',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class SpriteSheetAnimation extends StatefulWidget {
  const SpriteSheetAnimation({
    super.key,
    required this.assetPath,
    this.columns = 8,
    this.rows = 1,
    this.fps = 16,
    this.scaleTo,
    this.fallback,
    this.frameWidth,
    this.frameHeight,
    this.loop = true,
  });

  final String assetPath;
  final int columns;
  final int rows;
  final int fps;
  final Size? scaleTo;
  final Widget? fallback;
  final int? frameWidth;
  final int? frameHeight;
  final bool loop;

  @override
  State<SpriteSheetAnimation> createState() => _SpriteSheetAnimationState();
}

class _SpriteSheetAnimationState extends State<SpriteSheetAnimation>
    with SingleTickerProviderStateMixin {
  ui.Image? _image;
  late final AnimationController _controller;
  late int _frameCount;
  late int _columns;
  late int _rows;

  @override
  void initState() {
    super.initState();
    _columns = widget.columns;
    _rows = widget.rows;
    if (_columns <= 0) _columns = 1;
    if (_rows <= 0) _rows = 1;
    _frameCount = (_columns * _rows).clamp(1, 10000);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (1000 * (_frameCount <= 0 ? 1 : _frameCount) / widget.fps)
            .round(),
      ),
    )..addListener(() => setState(() {}));
    if (widget.loop) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final loaded = frame.image;
      // If explicit frame dimensions provided, prefer them to compute grid
      final fw = widget.frameWidth;
      final fh = widget.frameHeight;
      if (fw != null && fh != null && fw > 0 && fh > 0) {
        _columns = (loaded.width / fw).floor().clamp(1, 10000);
        _rows = (loaded.height / fh).floor().clamp(1, 10000);
      } else if (_columns <= 0 || _rows <= 0) {
        // Auto-detect grid if requested or mismatch
        if (loaded.height > 0 && loaded.width % loaded.height == 0) {
          // horizontal strip
          _rows = 1;
          _columns = loaded.width ~/ loaded.height;
        } else if (loaded.width > 0 && loaded.height % loaded.width == 0) {
          // vertical strip
          _columns = 1;
          _rows = loaded.height ~/ loaded.width;
        } else {
          // fallback single frame
          _columns = 1;
          _rows = 1;
        }
      }
      _frameCount = (_columns * _rows).clamp(1, 10000);
      _controller.duration = Duration(
        milliseconds: (1000 * (_frameCount <= 0 ? 1 : _frameCount) / widget.fps)
            .round(),
      );
      _controller.reset();
      if (widget.loop) {
        _controller.repeat();
      } else {
        _controller.forward();
      }
      if (mounted) setState(() => _image = loaded);
    } catch (e) {
      // ignore; fallback will render
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return widget.fallback ?? const SizedBox.shrink();
    }
    final image = _image!;
    final providedFW = widget.frameWidth;
    final providedFH = widget.frameHeight;
    final frameWidth = providedFW != null && providedFW > 0
        ? providedFW
        : (image.width / _columns).floor();
    final frameHeight = providedFH != null && providedFH > 0
        ? providedFH
        : (image.height / _rows).floor();
    final current = (_controller.value * _frameCount).floor() % _frameCount;
    final col = current % _columns;
    final row = current ~/ _columns;
    final src = Rect.fromLTWH(
      (col * frameWidth).toDouble(),
      (row * frameHeight).toDouble(),
      frameWidth.toDouble(),
      frameHeight.toDouble(),
    );

    final targetSize =
        widget.scaleTo ?? Size(frameWidth.toDouble(), frameHeight.toDouble());

    return SizedBox(
      width: targetSize.width,
      height: targetSize.height,
      child: CustomPaint(painter: _SpritePainter(image, src)),
    );
  }
}

class _SpritePainter extends CustomPainter {
  _SpritePainter(this.image, this.srcRect);
  final ui.Image image;
  final Rect srcRect;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the sprite frame to fill the destination size
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..filterQuality = FilterQuality.low;
    canvas.drawImageRect(image, srcRect, dst, paint);
  }

  @override
  bool shouldRepaint(covariant _SpritePainter oldDelegate) {
    return oldDelegate.srcRect != srcRect || oldDelegate.image != image;
  }
}

enum CelebrationType { achievement, levelUp, rankUp, backgroundUnlock }

// Helper class to show celebration screens
class CelebrationHelper {
  static void showAchievement(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? description,
    IconData? icon,
    Color? color,
    VoidCallback? onContinue,
    String? buttonText,
    VoidCallback? onClose,
  }) {
    if (!context.mounted) {
      debugPrint('Context not mounted, cannot show achievement dialog');
      return;
    }

    try {
      // Use rootNavigator to ensure dialog shows on top of everything
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) {
          try {
            return CelebrationScreen(
              type: CelebrationType.achievement,
              title: title,
              subtitle: subtitle,
              description: description,
              icon: icon,
              color: color,
              onContinue: onContinue,
              buttonText: buttonText,
              onClose: onClose,
            );
          } catch (e) {
            debugPrint('Error building CelebrationScreen: $e');
            // Return a simple error dialog instead of crashing
            return AlertDialog(
              title: const Text('Achievement Unlocked!'),
              content: Text(subtitle),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onContinue?.call();
                  },
                  child: Text(buttonText ?? 'Close'),
                ),
              ],
            );
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Error showing achievement dialog: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  static void showLevelUp(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? description,
    Color? color,
    VoidCallback? onContinue,
    String? buttonText,
  }) {
    debugPrint('CelebrationHelper.showLevelUp called: $title - $subtitle');
    if (!context.mounted) {
      debugPrint('Context not mounted, cannot show level up dialog');
      return;
    }

    try {
      debugPrint('Calling showDialog for level up celebration');
      // Use rootNavigator to ensure dialog shows on top of everything
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) {
          debugPrint('Building CelebrationScreen for level up');
          void closeDialog() {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext, rootNavigator: true).pop();
            }
          }

          return CelebrationScreen(
            type: CelebrationType.levelUp,
            title: title,
            subtitle: subtitle,
            description: description,
            color: color,
            onContinue:
                onContinue, // Don't set fallback - button will use onClose if null
            onClose: closeDialog,
            buttonText: buttonText,
          );
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Error showing level up dialog: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  static void showRankUp(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? description,
    Color? color,
    VoidCallback? onContinue,
    MartialRank? martialRank,
    String? buttonText,
  }) {
    if (!context.mounted) {
      debugPrint('Context not mounted, cannot show rank up dialog');
      return;
    }

    try {
      // Use rootNavigator to ensure dialog shows on top of everything
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) {
          void closeDialog() {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext, rootNavigator: true).pop();
            }
          }

          return CelebrationScreen(
            type: CelebrationType.rankUp,
            title: title,
            subtitle: subtitle,
            description: description,
            color: color,
            onContinue:
                onContinue, // Don't set fallback - button will use onClose if null
            onClose: closeDialog,
            martialRank: martialRank,
            buttonText: buttonText,
          );
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Error showing rank up dialog: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  static Future<void> showBackgroundUnlock(
    BuildContext context, {
    required int backgroundNumber,
    required int level,
  }) {
    if (!context.mounted) {
      debugPrint('Context not mounted, cannot show background unlock dialog');
      return Future.value();
    }

    try {
      // Use rootNavigator to ensure dialog shows on top of everything
      return showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) {
          try {
            return BackgroundUnlockCelebrationScreen(
              backgroundNumber: backgroundNumber,
              level: level,
            );
          } catch (e) {
            debugPrint('Error building BackgroundUnlockCelebrationScreen: $e');
            // Return a simple error dialog instead of crashing
            return AlertDialog(
              title: const Text('Background Unlocked!'),
              content: Text('New background unlocked at level $level'),
              actions: [
                TextButton(
                  onPressed: () {
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Error showing background unlock dialog: $e');
      debugPrint('Stack trace: $stackTrace');
      return Future.value();
    }
  }
}

// Specialized celebration screen for background unlocks
class BackgroundUnlockCelebrationScreen extends StatefulWidget {
  final int backgroundNumber;
  final int level;

  const BackgroundUnlockCelebrationScreen({
    super.key,
    required this.backgroundNumber,
    required this.level,
  });

  @override
  State<BackgroundUnlockCelebrationScreen> createState() =>
      _BackgroundUnlockCelebrationScreenState();
}

class _BackgroundUnlockCelebrationScreenState
    extends State<BackgroundUnlockCelebrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _scaleController.forward();
          }
        });
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            _slideController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final safeNumber = widget.backgroundNumber.clamp(1, 20);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: screenSize.height * 0.9,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        onPressed: () {
                          if (Navigator.of(
                            context,
                            rootNavigator: true,
                          ).canPop()) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),

                  // Background image preview
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/images/backgrounds/background_$safeNumber.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Gradient overlay for text readability
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title and subtitle
                  SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),

                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    'New Background Unlocked!',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple[300],
                                      fontSize: screenSize.width < 360
                                          ? 16
                                          : 20,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Unlocked at Level ${widget.level}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Continue button
                        SizedBox(
                          width: 200,
                          child: FilledButton(
                            onPressed: () {
                              if (Navigator.of(
                                context,
                                rootNavigator: true,
                              ).canPop()) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Continue',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
