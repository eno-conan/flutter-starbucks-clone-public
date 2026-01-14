import 'package:flutter/material.dart';
import '../../../../constants/my_colors.dart';

/// Utility class for showing loading overlay
class LoadingOverlay {
  static OverlayEntry? _overlayEntry;

  /// Show loading overlay
  static void show(BuildContext context) {
    _overlayEntry = OverlayEntry(
      builder: (context) => ColoredBox(
        color: Colors.black54,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(MyColors.greenButton),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Hide loading overlay
  static void hide(BuildContext context) {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
