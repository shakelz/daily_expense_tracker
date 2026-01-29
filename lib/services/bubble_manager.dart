import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class BubbleManager {
  static final BubbleManager _instance = BubbleManager._internal();
  bool _isBubbleVisible = false;

  factory BubbleManager() {
    return _instance;
  }

  BubbleManager._internal();

  /// Shows the floating bubble on the home screen
  Future<void> showBubble() async {
    if (kIsWeb) return; // Overlay not available on web
    
    try {
      if (_isBubbleVisible) {
        debugPrint('Bubble already visible, skipping...');
        return;
      }

      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "Expense Bubble",
        overlayContent: "Add Transaction",
        height: 120,
        width: 120,
        alignment: OverlayAlignment.bottomRight,
        margin: 10,
      );

      _isBubbleVisible = true;
      debugPrint('=== BUBBLE SHOWN ===\nFloating bubble is now visible\n================\n');
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
