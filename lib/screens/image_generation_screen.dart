import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utilities/appcolors.dart';
import '../services/image_generation_service.dart';
import 'dream_result_screen.dart';

class ImageGenerationScreen extends StatefulWidget {
  final Map<int, String> userResponses;

  const ImageGenerationScreen({super.key, required this.userResponses});

  @override
  State<ImageGenerationScreen> createState() => _ImageGenerationScreenState();
}

class _ImageGenerationScreenState extends State<ImageGenerationScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  final ImageGenerationService _imageService = ImageGenerationService();
  String _statusText = 'Создаем ваш сон';
  String? _errorMessage;

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playCompletionAudio() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/Completion.mp3'));

      _audioPlayer.onPlayerComplete.listen((event) {
        debugPrint("Audio is completed to play...");
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();

    _playCompletionAudio();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _startImageGeneration();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _startImageGeneration() async {
    try {
      if (!_imageService.isApiKeySet()) {
        setState(() {
          _errorMessage =
              'API ключ не настроен. Пожалуйста, добавьте ключ Stability AI.';
        });
        return;
      }

      final imageData = await _imageService.generateImage(
        userResponses: widget.userResponses,
        onStatusUpdate: (status) {
          if (mounted) {
            setState(() {
              _statusText = status;
            });
          }
        },
      );

      if (imageData != null && mounted) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (context) => DreamResultScreen(
                    dreamImage: imageData,
                    userResponses: widget.userResponses,
                  ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка создания изображения: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  AppColors.deep.withValues(alpha: 0.3),
                  AppColors.primaryBackground,
                ],
              ),
            ),
          ),

          // Animated particles
          ...List.generate(6, (index) => _buildFloatingParticle(index)),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  Colors.lightBlue.shade300.withValues(
                                    alpha: 0,
                                  ),
                                  Colors.lightBlue.shade300,
                                  Colors.lightBlue.shade300.withValues(
                                    alpha: 0,
                                  ),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.deep.withValues(alpha: 0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.lightBlue.shade300.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white,
                            Colors.lightBlue.shade300,
                            Colors.white,
                          ],
                          stops:
                              [
                                _shimmerAnimation.value - 0.3,
                                _shimmerAnimation.value,
                                _shimmerAnimation.value + 0.3,
                              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
                        ).createShader(bounds);
                      },
                      child: Text(
                        _errorMessage ?? _statusText,
                        style: TextStyle(
                          color:
                              _errorMessage != null
                                  ? Colors.red.shade300
                                  : Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Subtitle
                Text(
                  'Искусственный интеллект\nанализирует ваши ответы',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontFamily: 'Montserrat',
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                if (_errorMessage != null)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _statusText = 'Создаем ваш сон';
                      });
                      _startImageGeneration();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue.shade300,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Попробовать снова',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),

                if (_errorMessage == null)
                  Container(
                    width: 200,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return Stack(
                          children: [
                            Container(
                              width: 200 * (_shimmerController.value),
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.lightBlue.shade300,
                                    Colors.white,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = math.Random(index);
    final size = 4.0 + random.nextDouble() * 8;
    final duration = 10 + random.nextInt(10);
    final delay = random.nextInt(5);

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final progress = ((_shimmerController.value + delay / duration) % 1.0);
        final x = MediaQuery.of(context).size.width * random.nextDouble();
        final y = MediaQuery.of(context).size.height * progress;

        return Positioned(
          left: x,
          top: y,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.lightBlue.shade300.withValues(
                alpha: 0.3 * (1 - progress),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.lightBlue.shade300.withValues(
                    alpha: 0.5 * (1 - progress),
                  ),
                  blurRadius: size,
                  spreadRadius: size / 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
