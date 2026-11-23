import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Teks pesan error form: merah bata, kecil, tebal sedang.
/// Dipakai di bawah kolom, dan di tempat lain yang perlu pesan serupa
/// (mis. "Centang persetujuan untuk melanjutkan.").
class FieldError extends StatelessWidget {
  final String text;
  const FieldError(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.error,
      ),
    );
  }
}

/// Field putih membulat dengan label di atas dan pesan error di bawah.
/// Kalau [isPassword] true, ada tombol "Lihat"/"Sembunyi" di kanan.
///
/// Pesan error digambar sendiri (bukan errorText bawaan) supaya posisi,
/// warna, dan jaraknya persis. Kalau [showError] false, pesan tidak
/// ditampilkan di bawah kolom; pemanggil menerimanya lewat
/// [onErrorChanged] dan menaruhnya di tempat lain (dipakai di Daftar,
/// untuk kolom kata sandi).
class AppTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final bool showError;
  final ValueChanged<String?>? onErrorChanged;

  /// Error dari luar (mis. "Isi email dulu untuk reset kata sandi.").
  /// Kalau diisi, menggantikan hasil validator: garis tepi jadi merah dan
  /// pesannya tampil di bawah kolom. Isi null untuk menghapusnya.
  final String? errorText;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.showError = true,
    this.onErrorChanged,
    this.errorText,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _hidden = true;
  String? _reportedError;

  OutlineInputBorder _border(Color? color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: color == null
            ? BorderSide.none
            : BorderSide(color: color, width: 1.2),
      );

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller.text,
      // Selalu validasi isi controller yang terbaru.
      validator: (_) => widget.validator?.call(widget.controller.text),
      builder: (state) {
        final error = widget.errorText ?? state.errorText;

        if (error != _reportedError) {
          _reportedError = error;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onErrorChanged?.call(error);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                widget.label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: widget.controller,
              obscureText: widget.isPassword && _hidden,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: (v) {
                state.didChange(v);
                widget.onChanged?.call(v);
              },
              autocorrect: false,
              enableSuggestions: !widget.isPassword,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle:
                    const TextStyle(color: Color(0xFF757575), fontSize: 14),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: widget.isPassword
                    ? Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: () => setState(() => _hidden = !_hidden),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              _hidden ? 'Lihat' : 'Sembunyi',
                              style: const TextStyle(
                                color: AppColors.link,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
                border: _border(null),
                enabledBorder: _border(error != null ? AppColors.error : null),
                focusedBorder:
                    _border(error != null ? AppColors.error : AppColors.link),
              ),
            ),
            if (error != null && widget.showError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 2),
                child: FieldError(error),
              ),
          ],
        );
      },
    );
  }
}