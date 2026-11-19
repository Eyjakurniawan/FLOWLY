import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'auth_service.dart';

/// Foto profil disimpan di penyimpanan aplikasi (per akun), jadi tidak
/// perlu izin storage dan tetap ada setelah aplikasi ditutup.
class ProfilePhotoService extends ChangeNotifier {
  ProfilePhotoService._();
  static final ProfilePhotoService instance = ProfilePhotoService._();

  final ImagePicker _picker = ImagePicker();

  File? _photo;
  int _version = 0;

  /// Foto profil akun yang sedang masuk (null = belum ada).
  File? get photo => _photo;

  /// Naik tiap foto berganti, dipakai sebagai key supaya gambar dimuat ulang.
  int get version => _version;

  String? get _uid => AuthService.instance.currentUser?.id;

  Future<File?> _target() async {
    final uid = _uid;
    if (uid == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/profile_$uid.jpg');
  }

  /// Baca foto akun yang sedang masuk dari penyimpanan.
  Future<void> load() async {
    final f = await _target();
    final next = (f != null && await f.exists()) ? f : null;
    if (next != null) await FileImage(next).evict();
    _photo = next;
    _version++;
    notifyListeners();
  }

  /// Buka kamera atau galeri. Hasilnya file sementara (belum disimpan);
  /// null kalau user membatalkan. Panggil [save] untuk menyimpannya.
  Future<File?> pick(ImageSource source) async {
    final x = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    return x == null ? null : File(x.path);
  }

  Future<void> save(File source) async {
    final target = await _target();
    if (target == null) return;
    if (await target.exists()) {
      await FileImage(target).evict();
    }
    await source.copy(target.path);
    await FileImage(target).evict();
    _photo = target;
    _version++;
    notifyListeners();
  }

  Future<void> remove() async {
    final target = await _target();
    if (target != null && await target.exists()) {
      await FileImage(target).evict();
      await target.delete();
    }
    _photo = null;
    _version++;
    notifyListeners();
  }
}