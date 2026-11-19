import 'package:flutter/material.dart';

import '../services/notification_store.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/finance/add_transaction_sheet.dart';
import '../widgets/finance/common.dart';
import '../widgets/finance/home_header.dart';
import '../widgets/mascot_view.dart';

String _whenLabel(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Baru saja';
  if (d.inMinutes < 60) return '${d.inMinutes} mnt lalu';
  if (d.inHours < 24) return '${d.inHours} jam lalu';
  return Fmt.dayLabel(t);
}

/// Halaman Notifikasi. Dibuka dari ikon lonceng di header
/// dan dari menu Notifikasi di Profile (halamannya sama).
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _store = NotificationStore.instance;

  /// "Anchor" ke baris Pengingat catat harian.
  final _dailyKey = GlobalKey();
  bool _flashDaily = false;

  /// Membuka sheet "Jam pengingat".
  Future<void> _pickTime() async {
    final picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReminderSheet(hour: _store.hour, minute: _store.minute),
    );
    if (picked != null) _store.setReminderTime(picked.hour, picked.minute);
  }

  /// Dipanggil saat sebuah notifikasi diketuk.
  void _handleTap(AppNotification n) {
    _store.markRead(n.id);
    switch (n.action) {
      case NotificationAction.addTransaction:
        showAddTransactionSheet(context); // sama seperti tombol + di tengah
        break;
      case NotificationAction.dailyReminderSetting:
        _goToDailySetting();
        break;
      case NotificationAction.none:
        break;
    }
  }

  /// Scroll ke "Pengingat catat harian", sorot sebentar, lalu buka sheet jam.
  Future<void> _goToDailySetting() async {
    final ctx = _dailyKey.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      alignment: 0.3,
    );
    if (!mounted) return;
    setState(() => _flashDaily = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _flashDaily = false);
    await _pickTime();
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
              child: HomeHeader(bellEnabled: false),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _store,
                builder: (context, _) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 124),
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chevron_left_rounded,
                                  size: 28),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Notifikasi',
                              style: TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildRecent(),
                      const SizedBox(height: 14),
                      _buildSettings(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Terbaru

  /// Konfirmasi dulu sebelum menghapus satu notifikasi.
  Future<void> _confirmRemove(AppNotification item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(
        title: 'Hapus notifikasi?',
        message: '\u201C${item.title}\u201D akan dihapus.',
      ),
    );
    if (ok == true && mounted) _store.remove(item.id);
  }

  /// Konfirmasi dulu sebelum menghapus semua notifikasi.
  Future<void> _confirmClearAll() async {
    final count = _store.items.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(
        title: 'Hapus semua notifikasi?',
        message: '$count notifikasi akan dihapus.',
      ),
    );
    if (ok == true && mounted) _store.clear();
  }

  Widget _buildRecent() {
    final items = _store.items;
    return FlowlyCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Terbaru',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              _LinkText(
                label: 'Tandai dibaca',
                enabled: _store.hasUnread,
                onTap: _store.markAllRead,
              ),
              const SizedBox(width: 16),
              _LinkText(
                label: 'Hapus',
                enabled: !_store.isEmpty,
                onTap: _confirmClearAll,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Belum ada notifikasi.',
                  style:
                      TextStyle(fontSize: 12.5, color: AppColors.textGrey)),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: Color(0xFFE6EBF7)),
              _NotificationTile(
                item: items[i],
                onTap: () => _handleTap(items[i]),
                onDismiss: () => _confirmRemove(items[i]),
              ),
            ],
        ],
      ),
    );
  }

  // ------------------------------------------------- Pengaturan notifikasi

  Widget _buildSettings() {
    return FlowlyCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pengaturan notifikasi',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          _SwitchRow(
            key: _dailyKey,
            highlight: _flashDaily,
            title: 'Pengingat catat harian',
            subtitle: 'Setiap hari pukul ${_store.timeLabel} • ketuk untuk ubah',
            boldText: _store.timeLabel,
            value: _store.dailyOn,
            onChanged: _store.setDailyOn,
            onTap: _pickTime,
          ),
          const Divider(height: 1, color: Color(0xFFE6EBF7)),
          _SwitchRow(
            title: 'Pengingat rencana',
            subtitle: 'Ingatkan setoran sesuai alokasi',
            value: _store.planningOn,
            onChanged: _store.setPlanningOn,
          ),
          const Divider(height: 1, color: Color(0xFFE6EBF7)),
          _SwitchRow(
            title: 'Ringkasan mingguan',
            subtitle:
                'Setiap Senin pagi: pemasukan, pengeluaran, dan kategori terbesar',
            value: _store.weeklyOn,
            onChanged: _store.setWeeklyOn,
          ),
        ],
      ),
    );
  }
}

// ======================================================== widget kecil

class _LinkText extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _LinkText({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: enabled ? AppColors.link : AppColors.hint,
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _NotificationTile({
    required this.item,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Image.asset(
                item.mood.path,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(item.body,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                          height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_whenLabel(item.time),
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textGrey)),
                    if (!item.read) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onDismiss,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textGrey),
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

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? boldText; // bagian dari subtitle yang ditebalkan (mis. jam)
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTap;
  final bool highlight;
  const _SwitchRow({
    super.key,
    required this.title,
    required this.subtitle,
    this.boldText,
    required this.value,
    required this.onChanged,
    this.onTap,
    this.highlight = false,
  });

  Widget _buildSubtitle() {
    const base = TextStyle(
        fontSize: 12, color: AppColors.textGrey, height: 1.35);
    final bold = boldText;
    final i = bold == null ? -1 : subtitle.indexOf(bold);
    if (bold == null || i < 0) return Text(subtitle, style: base);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: subtitle.substring(0, i)),
          TextSpan(
            text: bold,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          TextSpan(text: subtitle.substring(i + bold.length)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFDCE6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    _buildSubtitle(),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: AppColors.link,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFD7E0F5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================ Sheet "Jam pengingat"

class _ReminderSheet extends StatefulWidget {
  final int hour;
  final int minute;
  const _ReminderSheet({required this.hour, required this.minute});

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  static const _dark = Color(0xFF0F1B3D);
  static const _orange = Color(0xFFE8482C);
  static const _band = Color(0xFFE3EBFA);
  static const _muted = Color(0xFF7C88A8);
  static const _minuteStep = 5;
  static const _minuteCount = 60 ~/ _minuteStep; // 12

  static const _presets = <(String, int, int)>[
    ('07.00 Pagi', 7, 0),
    ('12.00 Siang', 12, 0),
    ('18.00 Sore', 18, 0),
    ('20.00 Malam', 20, 0),
  ];

  late int _h; // 0..23
  late int _mi; // indeks menit 0..11 (kelipatan 5)
  late final FixedExtentScrollController _hc;
  late final FixedExtentScrollController _mc;

  @override
  void initState() {
    super.initState();
    _h = widget.hour;
    _mi = (widget.minute / _minuteStep).round() % _minuteCount;
    _hc = FixedExtentScrollController(initialItem: _h);
    _mc = FixedExtentScrollController(initialItem: _mi);
  }

  @override
  void dispose() {
    _hc.dispose();
    _mc.dispose();
    super.dispose();
  }

  int get _minute => _mi * _minuteStep;

  String _two(int v) => v.toString().padLeft(2, '0');
  String get _label => '${_two(_h)}.${_two(_minute)}';

  bool _isPreset(int h, int m) => _h == h && _minute == m;

  void _applyPreset(int h, int m) {
    _hc.animateToItem(h,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    _mc.animateToItem(m ~/ _minuteStep,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required int selected,
    required ValueChanged<int> onChanged,
  }) {
    return SizedBox(
      width: 84,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ).createShader(rect),
        child: ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: 40,
          diameterRatio: 1.8,
          perspective: 0.003,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (i) => onChanged(i % count),
          childDelegate: ListWheelChildLoopingListDelegate(
            children: List.generate(count, (i) {
              final sel = i == selected;
              final value = count == 24 ? i : i * _minuteStep;
              return Center(
                child: Text(
                  _two(value),
                  style: TextStyle(
                    fontSize: sel ? 26 : 20,
                    fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                    color: sel ? _dark : _muted,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DCE8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Jam pengingat',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Pilih jam notifikasi harian untuk mencatat transaksi.',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
              const SizedBox(height: 10),

              // ---- wheel jam : menit
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _band,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _wheel(
                          controller: _hc,
                          count: 24,
                          selected: _h,
                          onChanged: (v) => setState(() => _h = v),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(':',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _dark)),
                        ),
                        _wheel(
                          controller: _mc,
                          count: _minuteCount,
                          selected: _mi,
                          onChanged: (v) => setState(() => _mi = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ---- preset
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final p in _presets) ...[
                      GestureDetector(
                        onTap: () => _applyPreset(p.$2, p.$3),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          decoration: BoxDecoration(
                            color:
                                _isPreset(p.$2, p.$3) ? _dark : _band,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            p.$1,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _isPreset(p.$2, p.$3)
                                  ? Colors.white
                                  : _dark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ---- preview notifikasi
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/maskot_normal.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Floy • $_label',
                              style: const TextStyle(
                                  fontSize: 11.5, color: AppColors.textGrey)),
                          const SizedBox(height: 2),
                          const Text('Sudah catat pengeluaran hari ini?',
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ---- tombol simpan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .pop(TimeOfDay(hour: _h, minute: _minute)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Simpan jam',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================== Dialog konfirmasi hapus

class _DeleteConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  const _DeleteConfirmDialog({required this.title, required this.message});

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
            SizedBox(
              width: 100,
              height: 96,
              child: Stack(
                clipBehavior: Clip.none,
                children: const [
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
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
                      child: const Text('Ya, hapus',
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