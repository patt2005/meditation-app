import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../utilities/appcolors.dart';
import '../providers/app_provider.dart';
import '../models/story.dart';
import 'dream_details_screen.dart';
import 'history_screen.dart';

class DreamResultScreen extends StatefulWidget {
  final Uint8List dreamImage;
  final Map<int, String> userResponses;

  const DreamResultScreen({
    super.key,
    required this.dreamImage,
    required this.userResponses,
  });

  @override
  State<DreamResultScreen> createState() => _DreamResultScreenState();
}

class _DreamResultScreenState extends State<DreamResultScreen> {
  bool _isMenuOpen = false;
  String? _savedStoryId;

  @override
  void initState() {
    super.initState();
    _saveStory();
  }

  Future<void> _saveStory() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final imageService = appProvider.imageService;
    
    final storyId = DateTime.now().millisecondsSinceEpoch.toString();
    
    try {
      final imagePath = await appProvider.storageService.saveStoryImage(
        widget.dreamImage,
        storyId,
      );
      
      final prompt = imageService.generatePromptFromResponses(widget.userResponses);
      
      final story = Story(
        id: storyId,
        createdAt: DateTime.now(),
        prompt: prompt,
        imagePath: imagePath,
        userResponses: widget.userResponses,
        title: 'Сон ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
      );
      
      appProvider.addStory(story);
      
      setState(() {
        _savedStoryId = storyId;
      });
    } catch (e) {
      debugPrint('Error saving story: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.memory(
              widget.dreamImage,
              fit: BoxFit.cover,
            ),
          ),
          
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
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
              onPressed: () {
                setState(() {
                  _isMenuOpen = !_isMenuOpen;
                });
              },
            ),
          ),
          
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      // TODO: Implement share functionality
                    },
                  ),
                ),
              ],
            ),
          ),
          
          Positioned(
            bottom: 150,
            right: 40,
            child: FloatingActionButton(
              backgroundColor: Colors.lightBlue.shade300,
              onPressed: () {
                if (_savedStoryId != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DreamDetailsScreen(
                        storyId: _savedStoryId!,
                      ),
                    ),
                  );
                }
              },
              child: const Icon(
                Icons.menu_book,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isMenuOpen = false;
                  });
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
          
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: 0,
            right: _isMenuOpen ? 0 : -MediaQuery.of(context).size.width * 0.75,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.75,
            child: Container(
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
                          onPressed: () {
                            setState(() {
                              _isMenuOpen = false;
                            });
                          },
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
                              setState(() {
                                _isMenuOpen = false;
                              });
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            }),
                            const SizedBox(height: 40),
                            _buildMenuItem('НОВАЯ МЕДИТАЦИЯ', () {
                              setState(() {
                                _isMenuOpen = false;
                              });
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            }),
                            const SizedBox(height: 40),
                            _buildMenuItem('МОИ СНЫ', () {
                              setState(() {
                                _isMenuOpen = false;
                              });
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const HistoryScreen(),
                                ),
                              );
                            }),
                            const SizedBox(height: 40),
                            _buildMenuItem('PRO ВЕРСИЯ', () {
                              setState(() {
                                _isMenuOpen = false;
                              });
                              // TODO: Navigate to pro version
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
        ],
      ),
    );
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