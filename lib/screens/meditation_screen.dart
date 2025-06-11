import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utilities/appcolors.dart';
import '../models/meditation_step.dart';
import '../services/voice_service.dart';
import 'image_generation_screen.dart';
import 'history_screen.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen>
    with TickerProviderStateMixin {
  late AnimationController _menuController;
  late Animation<Offset> _slideAnimation;
  bool _isMenuOpen = false;
  int _currentPageIndex = 1;
  final int _totalPages = 6;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final VoiceService _voiceService = VoiceService();

  bool _isAudioPlaying = true;
  bool _isRecording = false;
  String _currentTranscription = '';
  final Map<int, String> _userResponses = {};

  @override
  void initState() {
    super.initState();

    _menuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _menuController, curve: Curves.easeInOut),
    );

    _playCurrentAudio();
    _initializeVoiceService();
  }

  Future<void> _initializeVoiceService() async {
    await _voiceService.initialize();
  }

  Future<void> _playCurrentAudio() async {
    try {
      setState(() {
        _isAudioPlaying = true;
        _isRecording = false;
      });

      await _audioPlayer.stop();
      final step = MeditationSteps.steps[_currentPageIndex - 1];
      await _audioPlayer.play(AssetSource('audio/${step.audioFile}'));

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _isAudioPlaying = false;
        });

        if (_currentPageIndex == _totalPages) {
          _navigateToImageGeneration();
        } else {
          _startVoiceRecording();
        }
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _startVoiceRecording() async {
    setState(() {
      _isRecording = true;
      _currentTranscription = '';
    });

    await _voiceService.startListening(
      onResult: (text) {
        setState(() {
          _currentTranscription = text;
        });
      },
      localeId: 'ru-RU',
    );

    _checkAndRestartRecording();
  }

  void _checkAndRestartRecording() {
    Future.delayed(const Duration(seconds: 2), () {
      if (_isRecording && !_voiceService.isListening && mounted) {
        debugPrint('Restarting voice recording...');
        _voiceService
            .startListening(
              onResult: (text) {
                setState(() {
                  _currentTranscription = text;
                });
              },
              localeId: 'ru-RU',
            )
            .then((_) => _checkAndRestartRecording());
      }
    });
  }

  Future<void> _stopVoiceRecording() async {
    await _voiceService.stopListening();

    if (_currentTranscription.isNotEmpty) {
      _userResponses[_currentPageIndex] = _currentTranscription;
    }

    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _navigateToImageGeneration() async {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (context) => ImageGenerationScreen(
                userResponses: Map.from(_userResponses),
              ),
        ),
      );
    }
  }

  void _previousPage() async {
    if (_isRecording) {
      await _stopVoiceRecording();
    }

    if (_currentPageIndex > 1) {
      setState(() {
        _currentPageIndex--;
      });
      _playCurrentAudio();
    }
  }

  void _nextPage() async {
    if (_isRecording) {
      await _stopVoiceRecording();
    }

    if (_currentPageIndex < _totalPages) {
      setState(() {
        _currentPageIndex++;
      });
      _playCurrentAudio();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _menuController.dispose();
    if (_isRecording) {
      _voiceService.stopListening();
    }
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _menuController.forward();
      } else {
        _menuController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Stack(
        children: [
          Column(
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.55,
                    width: double.infinity,
                    child: Image.asset('images/top.png', fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    right: 16,
                    child: IconButton(
                      icon: Icon(
                        _isMenuOpen ? Icons.close : Icons.menu,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: _toggleMenu,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getPageTitle(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _getPageSubtitle(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                          height: 1.5,
                          fontFamily: 'Montserrat',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 35),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.lightBlue.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: _previousPage,
                            ),
                          ),
                          const SizedBox(width: 40),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color:
                                  _isRecording
                                      ? Colors.red.shade400
                                      : Colors.lightBlue.shade300.withValues(
                                        alpha: _isAudioPlaying ? 0.4 : 1.0,
                                      ),
                              shape: BoxShape.circle,
                              boxShadow:
                                  _isRecording
                                      ? [
                                        BoxShadow(
                                          color: Colors.red.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ]
                                      : null,
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isRecording ? Icons.mic : Icons.check,
                                color: Colors.white.withValues(
                                  alpha:
                                      _isAudioPlaying && !_isRecording
                                          ? 0.5
                                          : 1.0,
                                ),
                                size: 30,
                              ),
                              onPressed:
                                  _isRecording
                                      ? _stopVoiceRecording
                                      : (_isAudioPlaying ? null : _nextPage),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Container(
                  width: 150,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: (_currentPageIndex / _totalPages) * 150,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isMenuOpen)
            GestureDetector(
              onTap: _toggleMenu,
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                decoration: BoxDecoration(
                  color: AppColors.deep.withValues(alpha: 0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(-5, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.white,
                              size: 28,
                            ),
                            onPressed: _toggleMenu,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildMenuItem('ГЛАВНАЯ', () {
                                _toggleMenu();
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              }),
                              const SizedBox(height: 40),
                              _buildMenuItem('МОИ СНЫ', () {
                                _toggleMenu();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const HistoryScreen(),
                                  ),
                                );
                              }),
                              const SizedBox(height: 40),
                              _buildMenuItem('PRO ВЕРСИЯ', () {
                                _toggleMenu();
                              }),
                              const SizedBox(height: 40),
                              _buildMenuItem('АНАЛИЗ СНА PRO', () {
                                _toggleMenu();
                              }),
                              const SizedBox(height: 40),
                              _buildMenuItem('БОЛЬШЕ СНОВ PRO', () {
                                _toggleMenu();
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    if (_currentPageIndex >= 1 && _currentPageIndex <= _totalPages) {
      return MeditationSteps.steps[_currentPageIndex - 1].title;
    }
    return 'Внутренний мир оживает';
  }

  String _getPageSubtitle() {
    if (_currentPageIndex >= 1 && _currentPageIndex <= _totalPages) {
      return MeditationSteps.steps[_currentPageIndex - 1].description;
    }
    return 'Закройте глаза и доверьтесь\nпроцессу.';
  }

  Map<int, String> getUserResponses() {
    return Map.from(_userResponses);
  }

  Widget _buildMenuItem(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          fontFamily: 'Montserrat',
          letterSpacing: 1,
        ),
      ),
    );
  }
}
