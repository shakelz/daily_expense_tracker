import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class BubbleManager {
  static final BubbleManager _instance = BubbleManager._internal();
  bool _isBubbleVisible = false;
  bool _isInitialized = false;

  factory BubbleManager() {
    return _instance;
  }

  BubbleManager._internal();

  /// Initialize the overlay window
  Future<void> initialize() async {
    if (kIsWeb || _isInitialized) return;
    
    try {
      _isInitialized = true;
      debugPrint('BubbleManager initialized');
    } catch (e) {
      debugPrint('Error initializing BubbleManager: $e');
    }
  }

  /// Handle tap on the bubble
  static void handleOverlayTap(String? tap) {
    if (tap == 'default') {
      debugPrint('Bubble tapped - opening transaction form');
      // Bubble was tapped
    }
  }

  /// Shows the floating bubble on the home screen
  Future<void> showBubble() async {
    if (kIsWeb) return; // Overlay not available on web
    
    try {
      if (_isBubbleVisible) {
        debugPrint('Bubble already visible, skipping...');
        return;
      }

      // Initialize if not already done
      if (!_isInitialized) {
        await initialize();
      }

      final bool isPermissionGranted = await FlutterOverlayWindow.isPermissionGranted();
      
      if (!isPermissionGranted) {
        debugPrint('Overlay permission not granted. Requesting...');
        await FlutterOverlayWindow.requestPermission();
        return;
      }

      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "Expense Tracker",
        overlayContent: "Add Transaction",
        height: 100,
        width: 100,
        alignment: OverlayAlignment.bottomRight,
      );

      _isBubbleVisible = true;
      debugPrint('=== BUBBLE SHOWN ===\nFloating bubble is now visible on homescreen\n================\n');
    } catch (e) {
      debugPrint('Error showing bubble: $e');
    }
  }

  /// Hides the floating bubble from the home screen
  Future<void> hideBubble() async {
    if (kIsWeb) return; // Overlay not available on web
    
    try {
      await FlutterOverlayWindow.closeOverlay();
      _isBubbleVisible = false;
      debugPrint('=== BUBBLE HIDDEN ===\nFloating bubble is now hidden\n==================\n');
    } catch (e) {
      debugPrint('Error hiding bubble: $e');
    }
  }

  /// Check if bubble is currently visible
  Future<bool> isBubbleVisible() async {
    try {
      return _isBubbleVisible;
    } catch (e) {
      debugPrint('Error checking bubble visibility: $e');
      return false;
    }
  }
}
