import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/story.dart';
import '../services/storage_service.dart';
import '../services/image_generation_service.dart';

class AppProvider extends ChangeNotifier {
  // User preferences
  bool _isDarkMode = false;
  String _selectedLanguage = 'ru-RU';
  bool _soundEnabled = true;
  
  // Meditation state
  final Map<int, String> _currentMeditationResponses = {};
  
  // Stories collection
  final List<Story> _stories = [];
  
  // Services
  final StorageService _storageService = StorageService();
  final ImageGenerationService _imageService = ImageGenerationService();
  
  // Pro version status
  bool _isProVersion = false;
  
  // Getters
  bool get isDarkMode => _isDarkMode;
  String get selectedLanguage => _selectedLanguage;
  bool get soundEnabled => _soundEnabled;
  Map<int, String> get currentMeditationResponses => Map.from(_currentMeditationResponses);
  List<Story> get stories => List.from(_stories);
  bool get isProVersion => _isProVersion;
  StorageService get storageService => _storageService;
  ImageGenerationService get imageService => _imageService;
  
  // Dark mode
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _savePreferences();
    notifyListeners();
  }
  
  void setDarkMode(bool value) {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      _savePreferences();
      notifyListeners();
    }
  }
  
  // Language
  void setLanguage(String language) {
    if (_selectedLanguage != language) {
      _selectedLanguage = language;
      _savePreferences();
      notifyListeners();
    }
  }
  
  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    _savePreferences();
    notifyListeners();
  }
  
  void setSoundEnabled(bool value) {
    if (_soundEnabled != value) {
      _soundEnabled = value;
      _savePreferences();
      notifyListeners();
    }
  }
  
  // Meditation responses
  void updateMeditationResponse(int step, String response) {
    _currentMeditationResponses[step] = response;
    notifyListeners();
  }
  
  void clearMeditationResponses() {
    _currentMeditationResponses.clear();
    notifyListeners();
  }
  
  // Stories management
  void addStory(Story story) {
    _stories.insert(0, story); // Add to beginning for newest first
    _saveStories(); // Auto-save when adding
    notifyListeners();
  }
  
  Future<void> removeStory(String storyId) async {
    final story = getStoryById(storyId);
    if (story != null) {
      // Delete the image file
      await _storageService.deleteStoryImage(story.imagePath);
      // Remove from list
      _stories.removeWhere((s) => s.id == storyId);
      await _saveStories(); // Auto-save when removing
      notifyListeners();
    }
  }
  
  Story? getStoryById(String storyId) {
    try {
      return _stories.firstWhere((story) => story.id == storyId);
    } catch (e) {
      return null;
    }
  }
  
  void updateStory(Story updatedStory) {
    final index = _stories.indexWhere((s) => s.id == updatedStory.id);
    if (index != -1) {
      _stories[index] = updatedStory;
      _saveStories(); // Auto-save when updating
      notifyListeners();
    }
  }
  
  void toggleStoryFavorite(String storyId) {
    final story = getStoryById(storyId);
    if (story != null) {
      final updatedStory = story.copyWith(isFavorite: !story.isFavorite);
      updateStory(updatedStory);
    }
  }
  
  List<Story> get favoriteStories {
    return _stories.where((story) => story.isFavorite).toList();
  }
  
  // Pro version
  void setProVersion(bool value) {
    if (_isProVersion != value) {
      _isProVersion = value;
      _savePreferences();
      notifyListeners();
    }
  }
  
  void purchaseProVersion() {
    _isProVersion = true;
    _savePreferences();
    notifyListeners();
  }
  
  // Statistics
  int get totalStoriesCount => _stories.length;
  
  int get storiesThisWeek {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _stories.where((story) => story.createdAt.isAfter(weekAgo)).length;
  }
  
  int get storiesThisMonth {
    final now = DateTime.now();
    final monthAgo = DateTime(now.year, now.month - 1, now.day);
    return _stories.where((story) => story.createdAt.isAfter(monthAgo)).length;
  }
  
  // Clear all data (for logout or reset)
  Future<void> clearAllData() async {
    _currentMeditationResponses.clear();
    
    // Clear all story images
    await _storageService.clearAllStoryImages();
    _stories.clear();
    
    _isDarkMode = false;
    _selectedLanguage = 'ru-RU';
    _soundEnabled = true;
    _isProVersion = false;
    
    // Clear saved data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }
  
  // Persistence functions
  static const String _storiesKey = 'meditation_app_stories';
  static const String _preferencesKey = 'meditation_app_preferences';
  
  // Save stories to SharedPreferences
  Future<void> _saveStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storiesJson = _stories.map((story) => story.toJson()).toList();
      final jsonString = json.encode(storiesJson);
      await prefs.setString(_storiesKey, jsonString);
      debugPrint('Saved ${_stories.length} stories');
    } catch (e) {
      debugPrint('Error saving stories: $e');
    }
  }
  
  // Load stories from SharedPreferences
  Future<void> loadStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storiesKey);
      
      if (jsonString != null) {
        final storiesJson = json.decode(jsonString) as List;
        _stories.clear();
        
        for (final storyJson in storiesJson) {
          try {
            final story = Story.fromJson(storyJson);
            // Verify image still exists
            if (await _storageService.imageExists(story.imagePath)) {
              _stories.add(story);
            } else {
              debugPrint('Image not found for story ${story.id}, skipping');
            }
          } catch (e) {
            debugPrint('Error loading story: $e');
          }
        }
        
        debugPrint('Loaded ${_stories.length} stories');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading stories: $e');
    }
  }
  
  // Save user preferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesData = {
        'isDarkMode': _isDarkMode,
        'selectedLanguage': _selectedLanguage,
        'soundEnabled': _soundEnabled,
        'isProVersion': _isProVersion,
      };
      final jsonString = json.encode(preferencesData);
      await prefs.setString(_preferencesKey, jsonString);
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }
  
  // Load user preferences
  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_preferencesKey);
      
      if (jsonString != null) {
        final preferencesData = json.decode(jsonString) as Map<String, dynamic>;
        _isDarkMode = preferencesData['isDarkMode'] ?? false;
        _selectedLanguage = preferencesData['selectedLanguage'] ?? 'ru-RU';
        _soundEnabled = preferencesData['soundEnabled'] ?? true;
        _isProVersion = preferencesData['isProVersion'] ?? false;
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }
  
  // Load all data (call from splash screen)
  Future<void> loadAllData() async {
    await loadPreferences();
    await loadStories();
  }
}