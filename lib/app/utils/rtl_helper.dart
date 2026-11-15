import 'package:flutter/material.dart';
import '../services/language_service.dart';

/// RTL Helper utility for handling Right-to-Left language support
/// Ensures Kurdish and Arabic languages display correctly with RTL layout
class RTLHelper {
  /// Check if current language is RTL (Arabic or Kurdish)
  static bool isRTL(BuildContext context) {
    final locale = LanguageService.getLocale();
    return locale.languageCode == 'ar' || locale.languageCode == 'ku';
  }

  /// Get text direction based on current language
  static TextDirection getTextDirection(BuildContext context) {
    return isRTL(context) ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Create RTL-aware padding
  /// For RTL languages (Arabic/Kurdish), left and right are swapped
  static EdgeInsets fromLTRB(
    BuildContext context,
    double left,
    double top,
    double right,
    double bottom,
  ) {
    if (isRTL(context)) {
      // Swap left and right for RTL
      return EdgeInsets.fromLTRB(right, top, left, bottom);
    }
    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }

  /// Create RTL-aware padding with only left/right
  static EdgeInsets symmetric(
    BuildContext context, {
    double? horizontal,
    double? vertical,
  }) {
    // Symmetric padding doesn't need RTL adjustment
    return EdgeInsets.symmetric(
      horizontal: horizontal ?? 0,
      vertical: vertical ?? 0,
    );
  }

  /// Create RTL-aware padding with only specific sides
  static EdgeInsets only(
    BuildContext context, {
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    if (isRTL(context)) {
      // Swap left and right for RTL
      return EdgeInsets.only(
        left: right ?? 0,
        top: top ?? 0,
        right: left ?? 0,
        bottom: bottom ?? 0,
      );
    }
    return EdgeInsets.only(
      left: left ?? 0,
      top: top ?? 0,
      right: right ?? 0,
      bottom: bottom ?? 0,
    );
  }

  /// Create RTL-aware margin
  static EdgeInsets marginFromLTRB(
    BuildContext context,
    double left,
    double top,
    double right,
    double bottom,
  ) {
    return fromLTRB(context, left, top, right, bottom);
  }

  /// Get RTL-aware alignment
  static Alignment getAlignment(BuildContext context, Alignment defaultAlignment) {
    if (isRTL(context)) {
      // Mirror horizontal alignment for RTL
      if (defaultAlignment == Alignment.centerLeft) {
        return Alignment.centerRight;
      } else if (defaultAlignment == Alignment.centerRight) {
        return Alignment.centerLeft;
      } else if (defaultAlignment == Alignment.topLeft) {
        return Alignment.topRight;
      } else if (defaultAlignment == Alignment.topRight) {
        return Alignment.topLeft;
      } else if (defaultAlignment == Alignment.bottomLeft) {
        return Alignment.bottomRight;
      } else if (defaultAlignment == Alignment.bottomRight) {
        return Alignment.bottomLeft;
      }
    }
    return defaultAlignment;
  }

  /// Get RTL-aware start alignment (left for LTR, right for RTL)
  static Alignment getStartAlignment(BuildContext context) {
    return isRTL(context) ? Alignment.centerRight : Alignment.centerLeft;
  }

  /// Get RTL-aware end alignment (right for LTR, left for RTL)
  static Alignment getEndAlignment(BuildContext context) {
    return isRTL(context) ? Alignment.centerLeft : Alignment.centerRight;
  }
}



