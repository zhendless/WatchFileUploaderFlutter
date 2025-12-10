import 'dart:async';
import 'dart:io';
import 'package:watcher/watcher.dart';
import 'package:path/path.dart' as path;

class FileWatcherService {
  DirectoryWatcher? _watcher;
  StreamSubscription? _subscription;
  String? _watchedPath;
  final StreamController<File> _newFileController =
      StreamController<File>.broadcast();

  // Stream of new files detected
  Stream<File> get newFileStream => _newFileController.stream;

  // Check if currently watching
  bool get isWatching => _watcher != null && _subscription != null;

  // Get the currently watched path
  String? get watchedPath => _watchedPath;

  // Start watching a directory
  Future<void> startWatching(String directoryPath) async {
    // Stop any existing watcher
    await stopWatching();

    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw Exception('Directory does not exist: $directoryPath');
    }

    _watchedPath = directoryPath;
    _watcher = DirectoryWatcher(directoryPath);

    _subscription = _watcher!.events.listen(
      (event) {
        if (event.type == ChangeType.ADD) {
          _handleNewFile(event.path);
        }
      },
      onError: (error) {
        print('File watcher error: $error');
      },
    );

    print('Started watching: $directoryPath');
  }

  // Handle new file detection
  void _handleNewFile(String filePath) async {
    final file = File(filePath);

    // Filter out temporary and system files
    final fileName = path.basename(filePath);
    if (_shouldIgnoreFile(fileName)) {
      return;
    }

    // Check if file exists and is not a directory
    if (!await file.exists() || await FileSystemEntity.isDirectory(filePath)) {
      return;
    }

    // Wait a bit to ensure file is fully written
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if file still exists and is accessible
    if (await file.exists()) {
      try {
        // Try to open the file to ensure it's not locked
        final raf = await file.open(mode: FileMode.read);
        await raf.close();

        // Emit the new file
        _newFileController.add(file);
      } catch (e) {
        print('File not ready or locked: $filePath');
      }
    }
  }

  // Check if file should be ignored
  bool _shouldIgnoreFile(String fileName) {
    // Ignore hidden files, temp files, and system files
    final ignorePatterns = [
      r'^\.', // Hidden files
      r'~$', // Temp files
      r'^~\$', // Office temp files
      r'\.tmp$', // Temp files
      r'\.temp$', // Temp files
      r'^Thumbs\.db$', // Windows thumbnail cache
      r'^desktop\.ini$', // Windows desktop config
    ];

    for (final pattern in ignorePatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(fileName)) {
        return true;
      }
    }

    return false;
  }

  // Stop watching
  Future<void> stopWatching() async {
    await _subscription?.cancel();
    _subscription = null;
    _watcher = null;
    _watchedPath = null;
    print('Stopped watching');
  }

  // Dispose resources
  void dispose() {
    stopWatching();
    _newFileController.close();
  }
}
