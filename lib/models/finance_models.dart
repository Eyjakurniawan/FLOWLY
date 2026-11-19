import 'package:flutter/material.dart';

import '../services/category_store.dart';

enum TxType { income, expense }

/// Rentang waktu untuk Cash flow & Pengeluaran per kategori.
enum Period {
  weekly('Mingguan'),
  monthly('Bulanan'),
  yearly('Tahunan');

  final String label;
  const Period(this.label);
}

class TxCategory {
  final String name;
  final Color color;
  final TxType type;
  const TxCategory(this.name, this.color, this.type);

  // Pengeluaran: warna tegas masing-masing (tanpa nuansa biru yang mirip)
  static const makanan =
      TxCategory('Makanan', Color(0xFF1E3A8A), TxType.expense); // Biru tua
  static const transportasi =
      TxCategory('Transportasi', Color(0xFFD97706), TxType.expense); // Kuning
  static const belanja =
      TxCategory('Belanja', Color(0xFFDC2626), TxType.expense); // Merah
  static const hiburan =
      TxCategory('Hiburan', Color(0xFF16A34A), TxType.expense); // Hijau
  static const tagihan =
      TxCategory('Tagihan', Color(0xFF78350F), TxType.expense); // Coklat
  static const kesehatan =
      TxCategory('Kesehatan', Color(0xFF0284C7), TxType.expense); // Biru muda

  static const pendidikan =
      TxCategory('Pendidikan', Color(0xFF7C3AED), TxType.expense); // Ungu

  // Pemasukan
  static const gaji = TxCategory('Gaji', Color(0xFF15803D), TxType.income);
  static const bonus = TxCategory('Bonus', Color(0xFF0284C7), TxType.income);
  static const bisnis = TxCategory('Bisnis', Color(0xFFD97706), TxType.income);
  static const freelance =
      TxCategory('Freelance', Color(0xFF7C3AED), TxType.income);
  static const tabungan =
      TxCategory('Tabungan', Color(0xFF0D9488), TxType.income);
  static const hadiah = TxCategory('Hadiah', Color(0xFFBE185D), TxType.income);

  /// Kategori bawaan (isi awal CategoryStore).
  static const defaults = [
    makanan,
    transportasi,
    belanja,
    hiburan,
    tagihan,
    kesehatan,
    pendidikan,
    gaji,
    bonus,
    bisnis,
    freelance,
    tabungan,
    hadiah,
  ];

  /// Daftar yang dipakai aplikasi (bisa ditambah/ubah/hapus pengguna).
  static List<TxCategory> get all => CategoryStore.instance.all;

  static List<TxCategory> byType(TxType t) =>
      all.where((c) => c.type == t).toList();

  static Color colorFor(String name) {
    for (final c in all) {
      if (c.name.toLowerCase() == name.toLowerCase()) return c.color;
    }
    return const Color(0xFF64748B);
  }
}

enum WalletType {
  bank('Bank'),
  ewallet('Dompet digital'),
  tunai('Tunai');

  final String label;
  const WalletType(this.label);
}

class Wallet {
  final String name;
  final WalletType type;
  final int initialBalance;
  const Wallet(this.name, this.type, this.initialBalance);
}

class FlowTransaction {
  final int id;
  final String title;
  final TxCategory category;
  final String wallet;
  final int amount; // selalu positif, arah ditentukan [type]
  final TxType type;
  final DateTime date;

  const FlowTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.wallet,
    required this.amount,
    required this.type,
    required this.date,
  });

  int get signedAmount => type == TxType.expense ? -amount : amount;

  FlowTransaction copyWith({String? title, TxCategory? category, String? wallet}) =>
      FlowTransaction(
        id: id,
        title: title ?? this.title,
        category: category ?? this.category,
        wallet: wallet ?? this.wallet,
        amount: amount,
        type: type,
        date: date,
      );
}

/// Satu titik di grafik Cash flow.
class CashPoint {
  final String label; // label sumbu x (pendek)
  final String fullLabel; // label saat dipilih
  final int income;
  final int expense;
  const CashPoint(this.label, this.fullLabel, this.income, this.expense);
}

class CategorySlice {
  final String name;
  final int total;
  final double share; // 0..1

  /// Nama kategori asli di dalam kotak ini. Hanya terisi untuk kotak
  /// gabungan "Lain-lain"; kosong berarti kotaknya cuma [name].
  final List<String> members;
  const CategorySlice(this.name, this.total, this.share,
      {this.members = const []});

  Set<String> get categoryNames => members.isEmpty ? {name} : members.toSet();
}