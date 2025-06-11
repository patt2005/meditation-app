import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<Directory> get _appDocDirectory async {
    final directory = await getApplicationDocumentsDirectory();
    return directory;
  }

  Future<Directory> get _storiesDirectory async {
    final appDir = await _appDocDirectory;
    final storiesDir = Directory(path.join(appDir.path, 'stories'));
    
    if (!await storiesDir.exists()) {
      await storiesDir.create(recursive: true);
    }
    
    return storiesDir;
  }

  Future<String> saveStoryImage(Uint8List imageData, String storyId) async {
    try {
      final storiesDir = await _storiesDirectory;
      final fileName = 'story_${storyId}_${DateTime.now().millisecondsSinceEpoch}.webp';
      final filePath = path.join(storiesDir.path, fileName);
      
      final file = File(filePath);
      await file.writeAsBytes(imageData);
      
      debugPrint('Image saved to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error saving image: $e');
      throw Exception('Failed to save image: $e');
    }
  }

  Future<Uint8List?> loadStoryImage(String imagePath) async {
    try {
      final file = File(imagePath);
      
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        debugPrint('Image file not found: $imagePath');
        return null;
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
      return null;
    }
  }

  // Delete image from local storage
  Future<bool> deleteStoryImage(String imagePath) async {
    try {
      final file = File(imagePath);
      
      if (await file.exists()) {
        await file.delete();
        debugPrint('Image deleted: $imagePath');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  // Check if image exists
  Future<bool> imageExists(String imagePath) async {
    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get all story images
  Future<List<FileSystemEntity>> getAllStoryImages() async {
    try {
      final storiesDir = await _storiesDirectory;
      final files = storiesDir.listSync()
          .where((file) => file is File && file.path.endsWith('.webp'))
          .toList();
      
      return files;
    } catch (e) {
      debugPrint('Error getting story images: $e');
      return [];
    }
  }

  // Clear all stored images (use with caution)
  Future<void> clearAllStoryImages() async {
    try {
      final storiesDir = await _storiesDirectory;
      
      if (await storiesDir.exists()) {
        await storiesDir.delete(recursive: true);
        debugPrint('All story images cleared');
      }
    } catch (e) {
      debugPrint('Error clearing story images: $e');
    }
  }

  // Get storage info
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final storiesDir = await _storiesDirectory;
      final files = await getAllStoryImages();
      
      int totalSize = 0;
      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      
      return {
        'totalFiles': files.length,
        'totalSizeBytes': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'path': storiesDir.path,
      };
    } catch (e) {
      debugPrint('Error getting storage info: $e');
      return {
        'totalFiles': 0,
        'totalSizeBytes': 0,
        'totalSizeMB': '0.00',
        'path': 'Unknown',
      };
    }
  }
}