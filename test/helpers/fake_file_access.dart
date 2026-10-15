import 'dart:typed_data';

import 'package:pulzar/platform/file_access.dart';

/// A rendszer fájlválasztója helyett: megjegyzi, mit mentett / nyitott meg az app.
class FakeFileAccess implements FileAccess {
  String? savedName;
  Uint8List? saved;
  Uint8List? toOpen;

  @override
  Future<String?> saveFile({
    required String name,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    savedName = name;
    saved = bytes;
    return 'content://fake/$name';
  }

  @override
  Future<Uint8List?> openFile() async => toOpen;

  /// A megnyitni kért fájlok (FR-11: Open a PDF mentése után).
  final viewed = <String>[];

  @override
  Future<bool> viewFile({required String uri, required String mimeType}) async {
    viewed.add(uri);
    return true;
  }
}
