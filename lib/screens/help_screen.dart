import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import '../services/support_service.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';
import '../widgets/finance/common.dart';
import '../widgets/finance/home_header.dart';
import '../widgets/mascot_view.dart';
import '../widgets/primary_button.dart';

const _supportEmail = 'support@flowly.app';

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

const _faqs = [
  _Faq(
    'Bagaimana cara mencatat transaksi?',
    'Tekan tombol + di tengah menu bawah, isi nominal, pilih kategori dan dompet, lalu simpan.',
  ),
  _Faq(
    'Bagaimana menambah dompet atau dompet digital?',
    'Buka tab Dompet lalu tekan "+ Tambah dompet", atau langsung dari form catat transaksi.',
  ),
  _Faq(
    'Bagaimana membuat rencana?',
    'Buka Rencana dari beranda atau menu Profil, tekan "+ Buat rencana", lalu isi nama, rencana anggaran, kategori, target selesai, dan pilih saran alokasi harian, mingguan, atau bulanan. Nominal setoran kamu isi sendiri.',
  ),
  _Faq(
    'Bagaimana mencatat setoran rencana?',
    'Ketuk rencana, atur tanggal (boleh hari sebelumnya), isi nominal, lalu Setor. Semua setoran tercatat di Riwayat setoran.',
  ),
  _Faq(
    'Bagaimana cara kerja kalkulator tabungan?',
    'Masukkan target dana dan tanggal selesai (dana yang sudah terkumpul boleh diisi). Kalkulator langsung menampilkan setoran yang dibutuhkan per hari, minggu, atau bulan.',
  ),
  _Faq(
    'Bagaimana mengubah jam pengingat?',
    'Buka Notifikasi, ketuk Pengingat catat harian, lalu pilih jam yang kamu inginkan.',
  ),
  _Faq(
    'Bagaimana mengubah atau menghapus kategori?',
    'Buka Profil, Pengaturan, lalu Kelola kategori dan dompet. Kamu bisa mengubah nama dan warna kategori, atau menghapusnya. Kategori yang masih dipakai transaksi tidak bisa dihapus.',
  ),
];

/// Halaman Bantuan & Dukungan (dibuka dari menu Profile).
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final Set<int> _open = {};

  void _toggle(int i) {
    setState(() {
      if (!_open.add(i)) _open.remove(i);
    });
  }

  Future<void> _copyEmail() async {
    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    if (!mounted) return;
    Helpers.showSnack(context, 'Alamat email disalin.');
  }

  Future<void> _openReport() async {
    final sent = await showFlowlySheet<bool>(
      context,
      (_) => const _ReportSheet(),
    );
    if (sent == true && mounted) {
      Helpers.showSnack(context, 'Laporan terkirim. Terima kasih!');
    }
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
                          child:
                              const Icon(Icons.chevron_left_rounded, size: 28),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Bantuan & Dukungan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FlowlyCard(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Row(
                      children: [
                        const MascotView(size: 84),
                        const SizedBox(width: 18),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Floy siap membantu',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800)),
                              SizedBox(height: 4),
                              Text(
                                'Cari jawabannya di bawah, atau hubungi tim kami.',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textGrey,
                                    height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FlowlyCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: Column(
                      children: [
                        for (var i = 0; i < _faqs.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: Color(0xFFE6EBF7)),
                          _FaqTile(
                            faq: _faqs[i],
                            open: _open.contains(i),
                            onTap: () => _toggle(i),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FlowlyCard(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Masih butuh bantuan?',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        const Text('Tim kami siap membantu di hari kerja.',
                            style: TextStyle(
                                fontSize: 12.5, color: AppColors.textGrey)),
                        const SizedBox(height: 14),
                        _OutlineAction(
                          label: 'Email $_supportEmail',
                          onTap: _copyEmail,
                        ),
                        const SizedBox(height: 10),
                        _OutlineAction(
                          label: 'Laporkan masalah',
                          onTap: _openReport,
                        ),
                      ],
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
}

class _FaqTile extends StatelessWidget {
  final _Faq faq;
  final bool open;
  final VoidCallback onTap;
  const _FaqTile({required this.faq, required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(faq.question,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Icon(open ? Icons.remove_rounded : Icons.add_rounded,
                    size: 20, color: AppColors.textDark),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: open
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10, right: 24),
                      child: Text(faq.answer,
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textGrey,
                              height: 1.45)),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDark,
          side: const BorderSide(color: AppColors.textDark, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Sheet "Laporkan masalah".
class _ReportSheet extends StatefulWidget {
  const _ReportSheet();

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const _types = [
    'Bug atau kesalahan',
    'Saldo tidak sesuai',
    'Saran fitur',
    'Lainnya',
  ];
  static const _minChars = 10;

  final _text = TextEditingController();
  String _type = _types.first;
  bool _sending = false;
  String? _error;

  bool get _canSend => _text.text.trim().length >= _minChars;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await SupportService.sendReport(type: _type, message: _text.text.trim());
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Laporan belum terkirim. Periksa koneksi lalu coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Laporkan masalah',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            'Ceritakan apa yang terjadi, laporanmu langsung diterima tim Flowly.',
            style: TextStyle(
                fontSize: 12, color: AppColors.textGrey, height: 1.4),
          ),
          const FieldLabel('Jenis masalah'),
          // Satu baris, geser ke samping (tidak turun ke bawah).
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final t in _types) ...[
                  ChoiceBubble(
                    label: t,
                    selected: t == _type,
                    onTap: () => setState(() => _type = t),
                  ),
                  if (t != _types.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const FieldLabel('Ceritakan masalahnya'),
          TextField(
            controller: _text,
            minLines: 4,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(1000)],
            // Font monospace (DM Mono) untuk teks ketikan dan petunjuknya.
            style: GoogleFonts.dmMono(fontSize: 14, color: AppColors.textDark),
            decoration: flowlyField('Minimal 10 karakter').copyWith(
              hintStyle: GoogleFonts.dmMono(fontSize: 14, color: AppColors.hint),
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.primary)),
            ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Kirim laporan',
            loading: _sending,
            onPressed: _canSend ? _send : null,
          ),
        ],
      ),
    );
  }
}