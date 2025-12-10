import 'dart:io';
import 'package:path/path.dart' as path;

class FileManagerService {
  // Move file to uploaded folder
  Future<bool> moveToUploadedFolder(File file) async {
    try {
      // Get the parent directory
      final parentDir = file.parent;

      // Create uploaded folder path
      final uploadedDir = Directory(path.join(parentDir.path, 'uploaded'));

      // Create uploaded folder if it doesn't exist
      if (!await uploadedDir.exists()) {
        await uploadedDir.create(recursive: true);
      }

      // Get the file name
      final fileName = path.basename(file.path);

      // Create destination path
      String destPath = path.join(uploadedDir.path, fileName);

      // Handle file name conflicts by appending timestamp
      if (await File(destPath).exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final nameWithoutExt = path.basenameWithoutExtension(fileName);
        final extension = path.extension(fileName);
        destPath = path.join(
          uploadedDir.path,
          '${nameWithoutExt}_$timestamp$extension',
        );
      }

      // Move the file
      await file.rename(destPath);

      print('Moved file to: $destPath');
      return true;
    } catch (e) {
      print('Error moving file: $e');
      return false;
    }
  }

  // Check if file is accessible
  Future<bool> isFileAccessible(File file) async {
    try {
      if (!await file.exists()) {
        return false;
      }

      // Try to open the file
      final raf = await file.open(mode: FileMode.read);
      await raf.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get file size
  Future<int> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  // Check if uploaded folder exists
  Future<bool> uploadedFolderExists(String parentPath) async {
    final uploadedDir = Directory(path.join(parentPath, 'uploaded'));
    return await uploadedDir.exists();
  }

  // Create uploaded folder
  Future<void> createUploadedFolder(String parentPath) async {
    final uploadedDir = Directory(path.join(parentPath, 'uploaded'));
    if (!await uploadedDir.exists()) {
      await uploadedDir.create(recursive: true);
    }
  }

  // Get uploaded folder path
  String getUploadedFolderPath(String parentPath) {
    return path.join(parentPath, 'uploaded');
  }
}
