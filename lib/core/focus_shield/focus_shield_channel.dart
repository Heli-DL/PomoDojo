import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class FocusShieldChannel {
  static const MethodChannel _channel = MethodChannel('focus_shield');

  /// Enable Do Not Disturb mode
  static Future<bool> enableDND() async {
    if (!Platform.isAndroid) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod('enableDND');
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to enable DND: ${e.message}');
      return false;
    }
  }

  /// Disable Do Not Disturb mode
  static Future<bool> disableDND() async {
    if (!Platform.isAndroid) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod('disableDND');
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to disable DND: ${e.message}');
      return false;
    }
  }

  /// Check if DND permission is granted
  static Future<bool> hasDNDPermission() async {
    if (!Platform.isAndroid) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod('hasDNDPermission');
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to check DND permission: ${e.message}');
      return false;
    }
  }

  /// Open DND policy access settings
  static Future<bool> openDNPSettings() async {
    if (!Platform.isAndroid) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod('openDNPSettings');
      return result as bool? ?? true;
    } on PlatformException catch (e) {
      debugPrint('Failed to open DND settings: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error opening DND settings: $e');
      return false;
    }
  }
}
