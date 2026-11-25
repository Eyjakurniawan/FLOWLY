import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/notification_store.dart';
import '../services/profile_photo_service.dart';
import '../utils/constants.dart';
import '../services/setup_service.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';
import '../widgets/finance/common.dart';
import '../widgets/finance/home_header.dart';
import '../widgets/mascot_view.dart';
import '../widgets/primary_button.dart';
import 'about_screen.dart';
import 'budget_screen.dart';
import 'help_screen.dart';
import 'notification_screen.dart';
import 'planning_screen.dart';
import 'settings_screen.dart';
import 'splash_screen.dart';

/// Tab Profile: kartu profil, menu, dan tombol keluar.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _gap = SizedBox(height: 14);

  @override
  void initState() {
    super.initState();
    ProfilePhotoService.instance.load(); // muat foto profil akun ini
  }

  String get _email => AuthService.instance.currentUser?.email ?? '';
  String get _name => (SetupService.instance.nickname ?? '').trim();
  bool get _hasName => _name.isNotEmpty;

  Future<void> _editProfile() async {
    final saved = await showFlowlySheet<bool>(
      context,
      (_) => _ProfileSheet(initialName: _name, email: _email),
    );
    if (!mounted) return;
    if (saved == true) {
      setState(() {}); // baca ulang nama dari akun
      NotificationStore.instance.push(
        title: 'Profil diperbarui',
        body: 'Perubahan profil kamu sudah disimpan.',
        action: NotificationAction.openProfile,
        mood: MascotExpression.wink,
      );
      Helpers.showSnack(context, 'Profil diperbarui.');
    }
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _SignOutDialog(),
    );
    if (ok == true) await _signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: HomeHeader(),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 10, 16, Helpers.navClearance(context)),
                children: [
                  _buildBubble(),
                  _gap,
                  _buildProfileCard(),
                  _gap,
                  _buildMenu(),
                  _gap,
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _confirmSignOut,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(
                            color: AppColors.primary, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('Keluar',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble() {
    final text = _hasName
        ? 'Hai, $_name! Senang bertemu lagi. Yuk lanjut atur keuanganmu.'
        : 'Hai! Lengkapi profilmu supaya aku bisa menyapamu dengan nama.';
    return Row(
      children: [
        const MascotView(size: 76),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(text,
                style: const TextStyle(fontSize: 13.5, height: 1.35)),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return FlowlyCard(
      onTap: _editProfile,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ListenableBuilder(
            listenable: ProfilePhotoService.instance,
            builder: (_, __) => _Avatar(
              size: 56,
              initial: _hasName ? _name.substring(0, 1).toUpperCase() : '',
              photo: ProfilePhotoService.instance.photo,
              photoVersion: ProfilePhotoService.instance.version,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_hasName ? _name : 'Belum ada nama',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(_email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textGrey)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _editProfile,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textDark,
              side: const BorderSide(color: AppColors.textDark, width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(_hasName ? 'Ubah' : 'Lengkapi',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return FlowlyCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Column(
        children: [
          _MenuItem(
            title: 'Anggaran',
            subtitle: 'Batas belanja per kategori',
            onTap: () => _open(const BudgetScreen()),
          ),
          const _MenuDivider(),
          _MenuItem(
            title: 'Rencana',
            subtitle: 'Target tabungan dan kalkulator',
            onTap: () => _open(const PlanningScreen()),
          ),
          const _MenuDivider(),
          _MenuItem(
            title: 'Notifikasi',
            subtitle: 'Pengingat dan riwayat',
            onTap: () => _open(const NotificationScreen()),
          ),
          const _MenuDivider(),
          _MenuItem(
            title: 'Pengaturan',
            subtitle: 'Tampilan, kategori, dan dompet',
            onTap: () => _open(const SettingsScreen()),
          ),
          const _MenuDivider(),
          _MenuItem(
            title: 'Bantuan dan Dukungan',
            subtitle: 'Pertanyaan umum dan kontak',
            onTap: () => _open(const HelpScreen()),
          ),
          const _MenuDivider(),
          _MenuItem(
            title: 'Tentang Aplikasi',
            subtitle: 'Versi dan informasi',
            onTap: () => _open(const AboutScreen()),
          ),
        ],
      ),
    );
  }
}

// ======================================================== widget kecil

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: Color(0xFFE6EBF7));
}

class _MenuItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 22, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}

/// Lingkaran navy: inisial nama (atau ikon orang) + lencana kamera oranye.
class _Avatar extends StatelessWidget {
  final double size;
  final String initial;
  final File? photo;
  final int photoVersion;
  const _Avatar({
    required this.size,
    required this.initial,
    this.photo,
    this.photoVersion = 0,
  });

  @override
  Widget build(BuildContext context) {
    final badge = size * 0.34;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.navyBottom,
              shape: BoxShape.circle,
            ),
            child: photo != null
                ? ClipOval(
                    child: Image.file(
                      photo!,
                      key: ValueKey('${photo!.path}-$photoVersion'),
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white,
                          size: size * 0.5),
                    ),
                  )
                : initial.isEmpty
                    ? Icon(Icons.person_outline_rounded,
                        color: Colors.white, size: size * 0.5)
                    : Text(initial,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: size * 0.42,
                            fontWeight: FontWeight.w800)),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: badge,
              height: badge,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(Icons.photo_camera_rounded,
                  size: badge * 0.5, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================================= sheet Profil kamu

class _ProfileSheet extends StatefulWidget {
  final String initialName;
  final String email;
  const _ProfileSheet({required this.initialName, required this.email});

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _emailCtl = TextEditingController(text: widget.email);
  bool _saving = false;
  String? _error;

  /// Foto yang baru dipilih (belum disimpan) dan penanda "hapus foto".
  /// Baru diterapkan saat user menekan "Simpan profil".
  File? _pendingPhoto;
  bool _removePhoto = false;

  File? get _shownPhoto =>
      _removePhoto ? null : (_pendingPhoto ?? ProfilePhotoService.instance.photo);

  @override
  void dispose() {
    _name.dispose();
    _emailCtl.dispose();
    super.dispose();
  }

  Future<void> _pickFrom(ImageSource source) async {
    try {
      final file = await ProfilePhotoService.instance.pick(source);
      if (file == null || !mounted) return;
      setState(() {
        _pendingPhoto = file;
        _removePhoto = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      Helpers.showSnack(context, 'Tidak bisa membuka foto. Coba lagi.');
    }
  }

  Future<void> _choosePhoto() async {
    FocusScope.of(context).unfocus();
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih dari galeri'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Ambil foto'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              if (_shownPhoto != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.primary),
                  title: const Text('Hapus foto',
                      style: TextStyle(color: AppColors.primary)),
                  onTap: () => Navigator.pop(ctx, 'remove'),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'gallery':
        await _pickFrom(ImageSource.gallery);
      case 'camera':
        await _pickFrom(ImageSource.camera);
      case 'remove':
        setState(() {
          _pendingPhoto = null;
          _removePhoto = true;
        });
    }
  }

  bool get _canSave => _name.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final res = await SetupService.instance.updateNickname(_name.text);
    if (!mounted) return;
    if (res.success) {
      try {
        if (_pendingPhoto != null) {
          await ProfilePhotoService.instance.save(_pendingPhoto!);
        } else if (_removePhoto) {
          await ProfilePhotoService.instance.remove();
        }
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _error = 'Nama tersimpan, tapi foto gagal disimpan. Coba lagi.';
        });
        return;
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = res.message ?? 'Gagal menyimpan profil.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = _name.text.trim();
    return SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profil kamu',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _choosePhoto,
              child: _Avatar(
                size: 96,
                initial:
                    trimmed.isEmpty ? '' : trimmed.substring(0, 1).toUpperCase(),
                photo: _shownPhoto,
                photoVersion: ProfilePhotoService.instance.version,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: _choosePhoto,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Text(_shownPhoto == null ? 'Pilih foto' : 'Ubah foto',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.link)),
              ),
            ),
          ),
          const FieldLabel('Nama'),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(20)],
            decoration: flowlyField('Nama kamu', error: _error),
            onChanged: (_) => setState(() => _error = null),
          ),
          const FieldLabel('Email'),
          TextField(
            controller: _emailCtl,
            enabled: false,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
            decoration: flowlyField('').copyWith(
              fillColor: const Color(0xFFE5E7EB),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Email mengikuti akun yang kamu pakai untuk masuk, jadi tidak bisa diubah di sini.',
            style: TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Simpan profil',
            loading: _saving,
            onPressed: _canSave ? _save : null,
          ),
        ],
      ),
    );
  }
}


// ===================================================== dialog konfirmasi keluar

class _SignOutDialog extends StatelessWidget {
  const _SignOutDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 100,
              height: 96,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(child: MascotView(size: 88)),
                  Positioned(
                    top: -2,
                    right: 6,
                    child: Text('?',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mascotBlue)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Yakin mau keluar?',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'Kamu perlu masuk lagi untuk memakai Flowly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.5, color: AppColors.textGrey, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(
                            color: AppColors.textDark, width: 1.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Batal',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Ya, keluar',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}