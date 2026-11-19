class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-+]+@([\w\-]+\.)+[a-zA-Z]{2,}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email wajib diisi';
    if (!_emailRegex.hasMatch(v)) return 'Format email tidak valid';
    return null;
  }

  /// Untuk pendaftaran: minimal 8 karakter.
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Kata sandi wajib diisi';
    if (v.length < 8) return 'Minimal 8 karakter';
    return null;
  }

  /// Untuk masuk: cukup tidak kosong.
  static String? requiredPassword(String? value) {
    if (value == null || value.isEmpty) return 'Kata sandi wajib diisi';
    return null;
  }

  /// Skor kekuatan kata sandi 0..4.
  /// +1 panjang >= 8, +1 huruf besar & kecil, +1 angka, +1 simbol.
  static int passwordStrength(String password) {
    if (password.isEmpty) return 0;
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[^\w\s]').hasMatch(password)) score++;
    return score;
  }
}
