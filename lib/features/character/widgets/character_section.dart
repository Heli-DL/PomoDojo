import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../progression/progression_model.dart';
import '../../auth/user_model.dart';

class CharacterImageSection extends StatelessWidget {
  const CharacterImageSection({
    super.key,
    this.progression,
    this.userModel,
    this.height = 200,
  });

  final Object? progression;
  final UserModel? userModel;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Determine the character key to drive art/emoji (tiger/monkey/otter/panda/dragon)
    final String rawName = userModel?.characterName ?? '';
    final String candidateKey = rawName.toLowerCase();
    final Set<String> allowed = {'tiger', 'monkey', 'otter', 'panda', 'dragon'};
    final String character = allowed.contains(candidateKey)
        ? candidateKey
        : 'tiger';
    // Display name: use user's characterName if provided, otherwise default by key
    final String characterName = rawName.isNotEmpty
        ? rawName
        : _getCharacterName(character);

    // Get current rank for character image
    final ProgressionModel? prog = progression is ProgressionModel
        ? progression as ProgressionModel
        : null;
    final String rankKey = prog?.rank.name.toLowerCase() ?? 'novice';

    // Get current background (use selected if available, otherwise highest unlocked, default to 1)
    int currentBackground = 1;
    try {
      final selected = userModel?.selectedBackground;
      final unlocked = userModel?.unlockedBackgrounds;
      if (selected != null && unlocked != null && unlocked.contains(selected)) {
        currentBackground = selected;
      } else if (unlocked != null && unlocked.isNotEmpty) {
        // Fallback to highest unlocked
        currentBackground = unlocked.last;
      }
    } catch (e) {
      // Safe fallback if there's any issue
      currentBackground = 1;
    }
    currentBackground = currentBackground.clamp(1, 20);

    debugPrint(
      '🎨 Character Screen - Background: $currentBackground, Unlocked: ${userModel?.unlockedBackgrounds}, Selected: ${userModel?.selectedBackground}',
    );

    final Color? headlineColor = Theme.of(
      context,
    ).textTheme.headlineSmall?.color;
    final Color? bodyColor = Theme.of(context).textTheme.bodySmall?.color;

    return Column(
      children: [
        // Large Character Image with Background - using aspect ratio
        _BackgroundImageContainer(
          backgroundNumber: currentBackground,
          rankKey: rankKey,
          character: character,
        ),

        const SizedBox(height: 16),

        // Character Name
        Text(
          characterName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: headlineColor,
          ),
        ),

        const SizedBox(height: 8),

        // Character Description
        Text(
          _getCharacterDescription(character),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: bodyColor),
        ),
      ],
    );
  }

  // --- Internals -------------------------------------------------------------

  String _getCharacterName(String character) {
    switch (character.toLowerCase()) {
      case 'tiger':
        return 'Tiger';
      case 'monkey':
        return 'Monkey';
      case 'otter':
        return 'Otter';
      case 'panda':
        return 'Panda';
      case 'dragon':
        return 'Dragon';
      default:
        return 'Tiger';
    }
  }

  String _getCharacterDescription(String character) {
    switch (character.toLowerCase()) {
      case 'tiger':
        return 'Relentless focus and fierce discipline.';
      case 'monkey':
        return 'Playful agility with quick bursts of energy.';
      case 'otter':
        return 'Calm, smooth, and adaptable flow.';
      case 'panda':
        return 'Gentle persistence with steady growth.';
      case 'dragon':
        return 'Powerful momentum and fiery determination.';
      default:
        return 'Relentless focus and fierce discipline.';
    }
  }
}

// Widget that maintains the aspect ratio of the background image
class _BackgroundImageContainer extends StatefulWidget {
  final int backgroundNumber;
  final String rankKey;
  final String character;

  const _BackgroundImageContainer({
    required this.backgroundNumber,
    required this.rankKey,
    required this.character,
  });

  @override
  State<_BackgroundImageContainer> createState() =>
      _BackgroundImageContainerState();
}

// Cache aspect ratios to avoid reloading the same images
final _aspectRatioCache = <int, double>{};

class _BackgroundImageContainerState extends State<_BackgroundImageContainer> {
  double? _aspectRatio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImageAspectRatio();
  }

  Future<void> _loadImageAspectRatio() async {
    final safeNumber = widget.backgroundNumber.clamp(1, 20);

    // Check cache first
    if (_aspectRatioCache.containsKey(safeNumber)) {
      if (mounted) {
        setState(() {
          _aspectRatio = _aspectRatioCache[safeNumber];
          _isLoading = false;
        });
      }
      return;
    }

    final imagePath = 'assets/images/backgrounds/background_$safeNumber.png';

    try {
      final ByteData data = await rootBundle.load(imagePath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 200, // Load smaller size for aspect ratio calculation
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;
      final calculatedRatio = image.width / image.height;

      // Cache the aspect ratio
      _aspectRatioCache[safeNumber] = calculatedRatio;

      if (mounted) {
        setState(() {
          _aspectRatio = calculatedRatio;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Default to 16:9 if we can't load the image
      const defaultRatio = 16 / 9;
      _aspectRatioCache[safeNumber] = defaultRatio;
      if (mounted) {
        setState(() {
          _aspectRatio = defaultRatio;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _aspectRatio == null) {
      // Show a placeholder while loading
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[300],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return AspectRatio(
      aspectRatio: _aspectRatio!,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image - fills entire container maintaining aspect ratio
              Image.asset(
                'assets/images/backgrounds/background_${widget.backgroundNumber.clamp(1, 20)}.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: 1200, // Optimize memory - limit to reasonable size
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
              // Character image at bottom center
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: _buildRankCharacterImageForBackground(
                      widget.rankKey,
                      widget.character,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for building rank character image in background container
  Widget _buildRankCharacterImageForBackground(
    String rankKey,
    String character,
  ) {
    // Map rank names to image file names
    final rankImageMap = {
      'novice': 'novice_1',
      'apprentice': 'apprentice_1',
      'disciple': 'disciple_1',
      'adept': 'adept_1',
      'master': 'master_1',
      'grandmaster': 'grandmaster_1',
    };

    final imageName = rankImageMap[rankKey.toLowerCase()] ?? 'novice_1';

    return Image.asset(
      'assets/images/$imageName.png',
      fit: BoxFit.contain,
      cacheWidth: 200, // Optimize memory usage
      cacheHeight: 200,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to gradient emoji if image not found
        return _buildCharacterImageFallback(character);
      },
    );
  }

  Widget _buildCharacterImageFallback(String character) {
    final base = _getCharacterColorHelper(character);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [base.withValues(alpha: 0.30), base.withValues(alpha: 0.10)],
        ),
      ),
      child: Center(
        child: Text(
          _getCharacterEmojiHelper(character),
          style: const TextStyle(fontSize: 80),
        ),
      ),
    );
  }

  Color _getCharacterColorHelper(String character) {
    switch (character.toLowerCase()) {
      case 'tiger':
        return Colors.orange;
      case 'monkey':
        return Colors.brown;
      case 'otter':
        return Colors.blue;
      case 'panda':
        return Colors.grey;
      case 'dragon':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getCharacterEmojiHelper(String character) {
    switch (character.toLowerCase()) {
      case 'tiger':
        return '🐯';
      case 'monkey':
        return '🐒';
      case 'otter':
        return '🦦';
      case 'panda':
        return '🐼';
      case 'dragon':
        return '🐉';
      default:
        return '🐯';
    }
  }
}
