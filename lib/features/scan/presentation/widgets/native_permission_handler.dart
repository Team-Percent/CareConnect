import 'dart:io';
import 'package:flutter/services.dart';

class NativePermissionHandler {
  static const MethodChannel _channel = MethodChannel('app.permissions/camera');

  static Future<bool> checkCameraPermission() async {
    if (Platform.isIOS) {
      try {
        final bool hasPermission =
            await _channel.invokeMethod('checkCameraPermission');
        return hasPermission;
      } on PlatformException {
        return false;
      }
    }
    return true;
  }

  static Future<bool> requestCameraPermission() async {
    if (Platform.isIOS) {
      try {
        final bool granted =
            await _channel.invokeMethod('requestCameraPermission');
        return granted;
      } on PlatformException {
        return false;
      }
    }
    return true;
  }

  static Future<void> openAppSettings() async {
    if (Platform.isIOS) {
      try {
        await _channel.invokeMethod('openSettings');
      } on PlatformException {
        // ignore error
      }
    }
  }
}
