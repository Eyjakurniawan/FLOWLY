/// Daftar ekspresi maskot. Harus di luar class (top-level).
enum MascotExpression {
  normal('maskot_normal.png'),
  wink('maskot_wink.png'),
  happy('maskot_happy.png'),
  flag('maskot_bendera.png'),
  coin('maskot_koin.png');

  final String file;
  const MascotExpression(this.file);

  String get path => 'assets/images/$file';
}

class AppConstants {
  AppConstants._();

  static const String supabaseUrl = 'https://ukxnjaajtquugnastdps.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_fsBPtKF_NWsBCE4wy7Qelw_RLEFRTUj';

  /// Deep link untuk callback login Google (harus sama dengan yang
  /// didaftarkan di Supabase -> Authentication -> URL Configuration).
  static const String oauthRedirect = 'com.kelompok7.flowly://callback';

  static const String appName = 'Flowly';
  static const String tagline = 'Atur uang, ikuti alurnya.';
}