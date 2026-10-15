import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../domain/report.dart';
import '../export/pdf_report.dart';

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

  /// Egy mentett fájl megnyitása a telefon alkalmazásával (pl. PDF-nézegető,
  /// onnan nyomtatható). false, ha nincs hozzá alkalmazás.
  Future<bool> viewFile({required String uri, required String mimeType});
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

  @override
  Future<bool> viewFile({required String uri, required String mimeType}) async =>
      await _channel.invokeMethod<bool>('viewFile', {
        'uri': uri,
        'mimeType': mimeType,
      }) ??
      false;
}

/// A PDF elkészítése (FR-11) – a tesztek lecserélhetik egy gyorsabb változatra.
typedef PdfRenderer = Future<Uint8List> Function(Report report);

/// Az app szolgáltatásai (fájlkezelés, óra, PDF) – a tesztek ezeket cserélik le.
class AppServices extends InheritedWidget {
  const AppServices({
    super.key,
    required this.fileAccess,
    this.clock = DateTime.now,
    this.renderPdf = renderReportPdf,
    required super.child,
  });

  final FileAccess fileAccess;

  final PdfRenderer renderPdf;

  /// Az „aktuális” idő – a tesztekben rögzített dátum (pl. egy adott csütörtök).
  final DateTime Function() clock;

  DateTime now() => clock();

  static AppServices of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppServices>()!;

  @override
  bool updateShouldNotify(AppServices oldWidget) =>
      fileAccess != oldWidget.fileAccess ||
      clock != oldWidget.clock ||
      renderPdf != oldWidget.renderPdf;
}
