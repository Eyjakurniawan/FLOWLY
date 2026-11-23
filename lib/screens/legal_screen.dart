import 'package:flutter/material.dart';

import '../utils/helpers.dart';

import '../utils/app_colors.dart';
import '../widgets/finance/common.dart';
import '../widgets/finance/home_header.dart';

class _Section {
  final String title;
  final String body;
  const _Section(this.title, this.body);
}

const _intro =
    'Draf contoh • Diperbarui 20 Oktober 2026. Tinjau bersama konsultan hukum sebelum rilis.';

const _terms = [
  _Section(
    'Tentang layanan',
    'Flowly adalah aplikasi pencatat keuangan pribadi. Flowly tidak menyimpan uang, tidak memproses pembayaran, dan bukan penasihat keuangan.',
  ),
  _Section(
    'Akun',
    'Kamu bertanggung jawab atas kerahasiaan akun dan kata sandimu serta atas data yang kamu masukkan.',
  ),
  _Section(
    'Penggunaan yang wajar',
    'Jangan menyalahgunakan aplikasi, mencoba mengakses data pengguna lain, atau mengganggu layanan.',
  ),
  _Section(
    'Keakuratan data',
    'Saldo, grafik, dan saran dihitung dari catatan yang kamu isi. Hasilnya hanya sebaik data yang dimasukkan.',
  ),
  _Section(
    'Perubahan layanan',
    'Fitur dan ketentuan ini bisa berubah. Perubahan penting akan diberitahukan lewat aplikasi.',
  ),
  _Section(
    'Kontak',
    'Pertanyaan tentang ketentuan ini bisa dikirim lewat Bantuan dan Dukungan.',
  ),
];

const _privacy = [
  _Section(
    'Data yang kami kumpulkan',
    'Data akun (nama, email) dan data keuangan yang kamu catat: transaksi, dompet, rencana, dan setoran.',
  ),
  _Section(
    'Cara kami memakai data',
    'Untuk menampilkan saldo, grafik, pengingat, dan saran di aplikasi. Kami tidak menjual datamu.',
  ),
  _Section(
    'Penyimpanan dan keamanan',
    'Data disimpan terenkripsi dan hanya bisa diakses dengan akunmu.',
  ),
  _Section(
    'Berbagi data',
    'Data hanya dibagikan ke penyedia infrastruktur yang diperlukan untuk menjalankan layanan, atau jika diwajibkan hukum.',
  ),
  _Section(
    'Hakmu',
    'Kamu bisa meminta salinan, koreksi, atau penghapusan data dan akunmu kapan saja.',
  ),
  _Section(
    'Kontak',
    'Pertanyaan privasi bisa dikirim lewat Bantuan dan Dukungan.',
  ),
];

/// Halaman Syarat Layanan.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const _LegalPage(title: 'Syarat Layanan', sections: _terms);
}

/// Halaman Kebijakan Privasi.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const _LegalPage(title: 'Kebijakan Privasi', sections: _privacy);
}

class _LegalPage extends StatelessWidget {
  final String title;
  final List<_Section> sections;
  const _LegalPage({required this.title, required this.sections});

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
                      Expanded(
                        child: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FlowlyCard(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(_intro,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                                height: 1.4)),
                        for (var i = 0; i < sections.length; i++) ...[
                          const SizedBox(height: 16),
                          Text('${i + 1}. ${sections[i].title}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(sections[i].body,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textGrey,
                                  height: 1.45)),
                        ],
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