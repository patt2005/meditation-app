import 'package:flutter/material.dart';
import 'dart:io';
import '../utilities/appcolors.dart';
import '../models/story.dart';
import '../services/storage_service.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class DreamDetailsScreen extends StatefulWidget {
  final String storyId;

  const DreamDetailsScreen({
    super.key,
    required this.storyId,
  });

  @override
  State<DreamDetailsScreen> createState() => _DreamDetailsScreenState();
}

class _DreamDetailsScreenState extends State<DreamDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pageController;
  late Animation<double> _pageAnimation;
  bool _isMenuOpen = false;
  int _currentPage = 0;
  final StorageService _storageService = StorageService();
  
  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pageAnimation = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _togglePage() {
    setState(() {
      _currentPage = _currentPage == 0 ? 1 : 0;
    });
    if (_currentPage == 1) {
      _pageController.forward();
    } else {
      _pageController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final story = appProvider.getStoryById(widget.storyId);
    
    if (story == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 60,
              ),
              const SizedBox(height: 20),
              const Text(
                'История не найдена',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue.shade300,
                ),
                child: const Text('Назад'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Stack(
        children: [
          // Background with book texture
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.deep.withValues(alpha: 0.8),
                  AppColors.primaryBackground,
                ],
              ),
            ),
          ),
          
          // Book content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Дневник снов',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isMenuOpen ? Icons.close : Icons.menu,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isMenuOpen = !_isMenuOpen;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                // Book pages
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Stack(
                      children: [
                        // Book background
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E6D3),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                // Book spine
                                Positioned(
                                  left: MediaQuery.of(context).size.width * 0.5 - 40,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 4,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.brown.shade300,
                                          Colors.brown.shade400,
                                          Colors.brown.shade300,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Page content
                                AnimatedBuilder(
                                  animation: _pageAnimation,
                                  builder: (context, child) {
                                    return Stack(
                                      children: [
                                        // Left page (Image)
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          bottom: 0,
                                          width: MediaQuery.of(context).size.width * 0.5 - 22,
                                          child: Transform(
                                            alignment: Alignment.centerRight,
                                            transform: Matrix4.identity()
                                              ..setEntry(3, 2, 0.001)
                                              ..rotateY(-_pageAnimation.value * 3.14159),
                                            child: _currentPage == 0
                                                ? _buildImagePage(story)
                                                : _buildTextPageBack(),
                                          ),
                                        ),
                                        
                                        // Right page (Text)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          bottom: 0,
                                          width: MediaQuery.of(context).size.width * 0.5 - 22,
                                          child: _buildTextPage(story),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Page turn button
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: GestureDetector(
                            onTap: _togglePage,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.brown.shade300,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _currentPage == 0 ? Icons.arrow_forward : Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        
                        // Favorite button
                        Positioned(
                          top: 20,
                          right: 20,
                          child: GestureDetector(
                            onTap: () {
                              appProvider.toggleStoryFavorite(story.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                story.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: Colors.red.shade400,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
          
          // Menu overlay
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
        ],
      ),
    );
  }
  
  Widget _buildImagePage(Story story) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFF5E6D3),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            _formatDate(story.createdAt),
            style: TextStyle(
              color: Colors.brown.shade700,
              fontSize: 14,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<bool>(
              future: _storageService.imageExists(story.imagePath),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(
                      File(story.imagePath),
                      fit: BoxFit.cover,
                    ),
                  );
                } else {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextPage(Story story) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFF5E6D3),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            story.title ?? 'Мой сон',
            style: TextStyle(
              color: Colors.brown.shade800,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Описание сна:',
            style: TextStyle(
              color: Colors.brown.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.prompt,
                    style: TextStyle(
                      color: Colors.brown.shade600,
                      fontSize: 14,
                      height: 1.6,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (story.userResponses.isNotEmpty) ...[
                    Text(
                      'Ваши ответы:',
                      style: TextStyle(
                        color: Colors.brown.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...story.userResponses.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '${_getStepTitle(entry.key)}: ${entry.value}',
                          style: TextStyle(
                            color: Colors.brown.shade600,
                            fontSize: 13,
                            fontFamily: 'Montserrat',
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextPageBack() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE8D7C3),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
  
  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Место';
      case 2:
        return 'Что видели';
      case 3:
        return 'Эмоции';
      case 4:
        return 'Цвета';
      case 5:
        return 'Детали';
      case 6:
        return 'Послание';
      default:
        return 'Шаг $step';
    }
  }
}