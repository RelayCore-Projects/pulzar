import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Fájl mentése / megnyitása a rendszer fájlválasztójával (ADR-010).
abstract class FileAccess {
  /// A felhasználó választja ki a helyet (pl. Letöltések, Google Drive).
  /// null, ha megszakította.
  Future<String?> saveFile({
    required String name,
    required Uint8List bytes,
    required String mimeType,
  });

  /// null, ha megszakította.
  Future<Uint8List?> openFile();
}

/// Android Storage Access Framework, saját csatornán (android/…/MainActivity.kt).
class ChannelFileAccess implements FileAccess {
  const ChannelFileAccess();

  static const _channel = MethodChannel('hu.relaycore.pulzar/files');

  @override
  Future<String?> saveFile({
    required String name,
    required Uint8List bytes,
    required String mimeType,
  }) =>
      _channel.invokeMethod<String>('saveFile', {
        'name': name,
        'bytes': bytes,
        'mimeType': mimeType,
      });

  @override
  Future<Uint8List?> openFile() => _channel.invokeMethod<Uint8List>('openFile');
}

/// Az app szolgáltatásai (most: fájlkezelés) – a tesztek ezt cserélik le.
class AppServices extends InheritedWidget {
  const AppServices({super.key, required this.fileAccess, required super.child});

  final FileAccess fileAccess;

  static AppServices of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppServices>()!;

  @override
  bool updateShouldNotify(AppServices oldWidget) =>
      fileAccess != oldWidget.fileAccess;
}
