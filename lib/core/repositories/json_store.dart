import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Minimal local JSON file persistence. Each repository owns one file under
/// the app's documents directory (`.../photographic_memory/<fileName>`).
/// Writes go to a temp file and are renamed into place so a crash or kill
/// mid-write can never leave a half-written, corrupt file behind — this is
/// what makes session recovery safe.
class JsonStore {
  JsonStore(this.fileName);

  final String fileName;
  Directory? _dir;

  Future<File> _file() async {
    _dir ??= await getApplicationDocumentsDirectory();
    final path = '${_dir!.path}/photographic_memory/$fileName';
    final file = File(path);
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    return file;
  }

  Future<dynamic> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      return jsonDecode(content);
    } catch (_) {
      // A corrupt or unreadable file should never crash the app — treat it
      // as "nothing stored yet" rather than propagating the error upward.
      return null;
    }
  }

  Future<void> write(dynamic data) async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(data));
    if (await file.exists()) {
      await file.delete();
    }
    await tmp.rename(file.path);
  }
}
