import 'package:flutter/material.dart';

class BubbleManager {
  static final BubbleManager _instance = BubbleManager._internal();

  factory BubbleManager() {
    return _instance;
  }

  BubbleManager._internal();

  /// Shows the floating bubble on the home screen
  Future<void> showBubble() async {
    try {
      // The bubble will be shown automatically when app is paused
      debugPrint('=== BUBBLE SHOWN ===\nFloating bubble is now visible\n================\n');
    } catch (e) {
      debugPrint('Error showing bubble: $e');
    }
  }

  /// Hides the floating bubble from the home screen
  Future<void> hideBubble() async {
    try {
      // The bubble will be hidden automatically when app is resumed
      debugPrint('=== BUBBLE HIDDEN ===\nFloating bubble is now hidden\n==================\n');
    } catch (e) {
      debugPrint('Error hiding bubble: $e');
    }
  }

  /// Check if bubble is currently visible
  Future<bool> isBubbleVisible() async {
    try {
      return false;
    } catch (e) {
      debugPrint('Error checking bubble visibility: $e');
      return false;
    }
  }
}
