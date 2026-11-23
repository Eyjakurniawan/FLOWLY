import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/support_service.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';
import '../widgets/finance/common.dart';
import '../widgets/finance/home_header.dart';
import '../widgets/mascot_view.dart';
import '../widgets/primary_button.dart';

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

const _faqs = [
  _Faq(
    'Bagaimana cara mencatat transaksi?',
    'Tekan tombol + di menu bawah, isi nominal (maksimal Rp999.999.999.999), pilih kategori dan dompet, lalu simpan. Tanggal bisa dipilih dari hari akunmu dibuat sampai hari ini.',
  ),
  _Faq(
    'Bagaimana mengubah atau menghapus transaksi?',
    'Ketuk transaksinya di Transaksi, Laporan, atau detail dompet, lalu pilih Ubah atau Hapus. Saldo dompet ikut menyesuaikan.',
  ),
  _Faq(
    'Kenapa transaksiku ditolak?',
    'Pengeluaran tidak bisa melebihi saldo dompet. Ubah atau hapus juga ditolak jika membuat saldo dompet minus. Kecilkan nominal, pilih dompet lain, atau catat pemasukan dulu.',
  ),
  _Faq(
    'Kenapa saldo dompet tidak bisa diedit?',
    'Saldo awal hanya bisa diisi satu kali. Setelah itu saldo dihitung otomatis dari transaksi. Untuk koreksi, catat transaksi pemasukan atau pengeluaran.',
  ),
  _Faq(
    'Apa yang terjadi jika dompet dihapus?',
    'Dompet yang dihapus tidak bisa dikembalikan dan saldonya tidak lagi dihitung di total saldo. Riwayat transaksinya tetap bisa dilihat di Laporan.',
  ),
  _Faq(
    'Bagaimana membuat rencana?',
    'Buka Rencana, tekan "+ Buat rencana", lalu isi nama, anggaran, kategori, dan target selesai (mulai besok). Pilih saran alokasi harian, mingguan, atau bulanan untuk melihat saran target dan saran setoran.',
  ),
  _Faq(
    'Bagaimana cara kerja anggaran?',
    'Buka Profil lalu Anggaran (atau ketuk kartu Anggaran di Beranda), tekan "+ Buat anggaran", pilih kategori dan isi batas per bulan. Pengeluaran di kategori itu dihitung otomatis dan direset tiap awal bulan. Batasnya lunak: pengeluaran yang melewati batas tetap bisa dicatat, tapi kamu diingatkan. "Aman dipakai per hari" adalah sisa anggaran dibagi sisa hari di bulan ini. Riwayat tiap bulan bisa dilihat dengan memilih bulan di halaman Anggaran. Perubahan batas berlaku mulai bulan ini, bulan lalu tetap memakai batas lamanya. Anggaran membatasi pengeluaran, sedangkan Rencana mengumpulkan tabungan.',
  ),
  _Faq(
    'Bagaimana mencatat setoran rencana?',
    'Ketuk rencana, pilih tanggal, isi nominal setoran sendiri, lalu tekan Setor. Nominal tidak boleh melebihi sisa target.',
  ),
  _Faq(
    'Apa bedanya rencana aktif dan tercapai?',
    'Rencana aktif belum terkumpul penuh. Begitu penuh, statusnya tercapai dan tidak lagi dihitung aktif.',
  ),
  _Faq(
    'Kenapa kategori tidak bisa dihapus?',
    'Kategori yang masih dipakai transaksi tidak bisa dihapus. Ubah atau hapus transaksinya dulu.',
  ),
  _Faq(
    'Bagaimana mengubah ukuran huruf?',
    'Buka Profil, Pengaturan, lalu geser pengatur Ukuran huruf dari A kecil ke A besar (85% sampai 105%). Ukuran diterapkan saat geseran dilepas dan tersimpan di perangkat ini. Tekan Atur ulang untuk kembali ke 100%.',
  ),
  _Faq(
    'Bagaimana menghapus akun?',
    'Buka Profil, Pengaturan, lalu Hapus akun dan ketik HAPUS. Semua data dihapus permanen dan tidak bisa dikembalikan.',
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
                padding: EdgeInsets.fromLTRB(16, 10, 16, Helpers.navClearance(context)),
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
                        child: Text('Bantuan dan Dukungan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const FlowlyCard(
                    padding: EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Row(
                      children: [
                        MascotView(size: 84),
                        SizedBox(width: 18),
                        Expanded(
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
                        const Text('Ceritakan kendalamu, laporanmu langsung diterima tim Flowly.',
                            style: TextStyle(
                                fontSize: 12.5, color: AppColors.textGrey)),
                        const SizedBox(height: 14),
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