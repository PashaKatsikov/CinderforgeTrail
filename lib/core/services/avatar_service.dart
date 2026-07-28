import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Manages the on-device profile avatar.
///
/// Picks an image from the gallery or the camera, resizes it to a square of
/// [_kSize] pixels and saves it to the app's documents directory so it
/// survives across restarts without any network.
class AvatarService {
  static const _kFile = 'profile_avatar.jpg';
  static const _kSize = 512;

  final _picker = ImagePicker();

  /// Returns the saved avatar file, or null when none has been set.
  Future<File?> load() async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/$_kFile');
    return f.existsSync() ? f : null;
  }

  /// Opens the system image picker for [source] (gallery or camera) and saves
  /// the result.  Returns the new file on success, null if the user cancels.
  Future<File?> pick(ImageSource source) async {
    final xfile = await _picker.pickImage(
      source: source,
      maxWidth: _kSize.toDouble(),
      maxHeight: _kSize.toDouble(),
      imageQuality: 88,
      preferredCameraDevice: CameraDevice.front,
    );
    if (xfile == null) return null;
    return _save(xfile);
  }

  Future<File> _save(XFile xfile) async {
    final dir = await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/$_kFile');
    final bytes = await xfile.readAsBytes();
    await dest.writeAsBytes(bytes, flush: true);
    return dest;
  }

  Future<void> delete() async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/$_kFile');
    if (f.existsSync()) await f.delete();
  }
}
