import 'package:flutter/material.dart';

import '../models/setup_data.dart';
import '../services/setup_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/app_text_field.dart';
import '../widgets/mascot_bubble.dart';
import '../widgets/mascot_view.dart';
import '../widgets/option_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/setup_header.dart';
import '../widgets/time_chip.dart';
import 'home_screen.dart';

/// Alur setup awal (Setup 1-5) dalam satu PageView.
///
/// 0: tujuan | 1: nama panggilan | 2: gaya budget | 3: pengingat | 4: selesai
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  static const int _lastIndex = 4; // layar "Siap berlayar!"

  final _controller = PageController();
  final _nameCtrl = TextEditingController();

  final Set<SetupGoal> _goals = {};
  BudgetStyle _budget = BudgetStyle.seimbang;
  bool _reminderOn = true;
  ReminderTime _time = ReminderTime.night;

  int _index = 0;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _go(int page) {
    FocusScope.of(context).unfocus();
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _back() {
    if (_index > 0 && _index < _lastIndex) _go(_index - 1);
  }

  String get _buttonLabel {
    switch (_index) {
      case 3:
        return 'Selesai';
      case _lastIndex:
        return 'Mulai';
      default:
        return 'Lanjut';
    }
  }

  Future<void> _next() async {
    switch (_index) {
      case 0:
        // Tujuan opsional, boleh tidak memilih apa-apa.
        _go(1);
        break;
      case 1:
        // Hanya nama panggilan yang wajib diisi.
        final name = _nameCtrl.text.trim();
        if (name.isEmpty) {
          Helpers.showSnack(context, 'Isi nama panggilan dulu ya.',
              isError: true);
          return;
        }
        if (name.length > 20) {
          Helpers.showSnack(context, 'Nama panggilan maksimal 20 karakter.',
              isError: true);
          return;
        }
        _go(2);
        break;
      case 2:
        _go(3);
        break;
      case 3:
        await _finish();
        break;
      case _lastIndex:
        _start();
        break;
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final result = await SetupService.instance.save(
      SetupData(
        goals: _goals,
        nickname: _nameCtrl.text,
        budgetStyle: _budget,
        reminderEnabled: _reminderOn,
        reminderTime: _time,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (!result.success) {
      Helpers.showSnack(context, result.message ?? 'Gagal menyimpan.',
          isError: true);
      return;
    }
    _go(_lastIndex);
  }

  void _start() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _lastIndex;

    return PopScope(
      // Tombol back sistem: mundur satu langkah, bukan keluar aplikasi.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              children: [
                SetupHeader(
                  step: _index,
                  showBack: _index > 0 && !isLast,
                  showCounter: !isLast,
                  onBack: _back,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _index = i),
                    children: [
                      _goalsPage(),
                      _namePage(),
                      _budgetPage(),
                      _reminderPage(),
                      _donePage(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: _buttonLabel,
                  loading: _saving,
                  onPressed: _next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Setup 1: tujuan ----------
  Widget _goalsPage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const MascotBubble(
            title: 'Apa tujuanmu?',
            subtitle: 'Boleh pilih lebih dari satu, atau lewati dulu. Aku sesuaikan tampilannya.',
            expression: MascotExpression.normal,
          ),
          const SizedBox(height: 20),
          for (final goal in SetupGoal.values) ...[
            OptionCard(
              title: goal.label,
              selected: _goals.contains(goal),
              onTap: () => setState(() {
                _goals.contains(goal) ? _goals.remove(goal) : _goals.add(goal);
              }),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  // ---------- Setup 2: nama panggilan ----------
  Widget _namePage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MascotBubble(
            title: 'Atur dasar dulu',
            subtitle:
                'Siapa nama panggilanmu? Dompet bisa kamu tambahkan sendiri nanti di tab Dompet.',
            expression: MascotExpression.normal,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Nama panggilan',
            hint: 'Misal: Floy',
            controller: _nameCtrl,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  // ---------- Setup 3: gaya budget ----------
  Widget _budgetPage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const MascotBubble(
            title: 'Gaya budget-mu?',
            subtitle: 'Pilih yang paling cocok, nanti bisa diganti.',
            expression: MascotExpression.normal,
          ),
          const SizedBox(height: 20),
          for (final style in BudgetStyle.values) ...[
            OptionCard(
              title: style.title,
              subtitle: style.description,
              selected: _budget == style,
              onTap: () => setState(() => _budget = style),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  // ---------- Setup 4: pengingat ----------
  Widget _reminderPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MascotBubble(
            title: 'Mau kuingatkan?',
            subtitle: 'Aku sapa sekali sehari supaya tidak lupa mencatat.',
            expression: MascotExpression.wink,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengingat catat harian',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Setiap hari pada jam pilihanmu',
                      style:
                          TextStyle(fontSize: 10.5, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _reminderOn,
                onChanged: (v) => setState(() => _reminderOn = v),
                thumbColor: const WidgetStatePropertyAll(Colors.white),
                activeTrackColor: AppColors.link,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _reminderOn ? 1 : 0.4,
            child: IgnorePointer(
              ignoring: !_reminderOn,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final t in ReminderTime.values)
                    TimeChip(
                      label: t.label,
                      selected: _time == t,
                      onTap: () => setState(() => _time = t),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Setup 5: selesai ----------
  Widget _donePage() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MascotView(size: 180, expression: MascotExpression.happy),
          SizedBox(height: 20),
          Text(
            'Siap berlayar!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Semua sudah diatur. Yuk catat transaksi pertamamu dengan tombol +.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}