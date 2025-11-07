import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/celebration_screen.dart' show SpriteSheetAnimation;

class CelebrationScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const CelebrationScreen({super.key, required this.onComplete});

  @override
  ConsumerState<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends ConsumerState<CelebrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Start animations
    _confettiController.repeat();
    _scaleController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    screenHeight -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                children: [
                  SizedBox(height: isSmallScreen ? 12 : 20),

                  // Top animation
                  Center(
                    child: SpriteSheetAnimation(
                      assetPath: 'assets/images/sprites/happy_tiger.png',
                      columns: 4,
                      rows: 4,
                      fps: 10,
                      scaleTo: Size(
                        isSmallScreen ? 250 : 300,
                        isSmallScreen ? 250 : 300,
                      ),
                    ),
                  ),

                  // Celebration Content
                  ScaleTransition(
                    scale: _scaleController,
                    child: FadeTransition(
                      opacity: _fadeController,
                      child: Column(
                        children: [
                          // Title
                          Text(
                            'You\'re all set!',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              fontSize: isSmallScreen ? 24 : null,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: isSmallScreen ? 8 : 12),

                          // Description
                          Text(
                            'You\'ve completed your setup and set your first weekly goal.',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              height: 1.4,
                              fontSize: isSmallScreen ? 16 : null,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: isSmallScreen ? 16 : 24),

                          // Achievement Card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: isSmallScreen ? 40 : 50,
                                  height: isSmallScreen ? 40 : 50,
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.emoji_events,
                                    color: Colors.white,
                                    size: isSmallScreen ? 20 : 24,
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 12 : 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Achievement Unlocked',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber.shade700,
                                              fontSize: isSmallScreen
                                                  ? 12
                                                  : null,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Getting Started',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.7),
                                              fontSize: isSmallScreen
                                                  ? 12
                                                  : null,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 24 : 32),

                  // Start Button
                  FadeTransition(
                    opacity: _fadeController,
                    child: SizedBox(
                      width: double.infinity,
                      height: isSmallScreen ? 48 : 56,
                      child: FilledButton(
                        onPressed: () {
                          // Complete onboarding and go to home
                          widget.onComplete();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Start My First Focus',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double animationValue;

  ConfettiPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw confetti pieces
    for (int i = 0; i < 20; i++) {
      final x = (size.width * (i / 20.0) + animationValue * 50) % size.width;
      final y =
          (size.height * 0.2 + animationValue * 100 + i * 10) % size.height;

      paint.color = _getConfettiColor(i);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 4, height: 4),
        paint,
      );
    }
  }

  Color _getConfettiColor(int index) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
