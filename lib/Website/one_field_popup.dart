import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'shared_popup_widgets.dart';

class OneFieldFormPopup extends StatefulWidget {
  final String title;
  final String label;
  final void Function(String) onSubmit;

  const OneFieldFormPopup({
    super.key,
    required this.title,
    required this.label,
    required this.onSubmit,
  });

  @override
  State<OneFieldFormPopup> createState() => _OneFieldFormPopupState();
}

class _OneFieldFormPopupState extends State<OneFieldFormPopup> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 560,
        maxWidth: 820,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            widget.label,
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2B2B2B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter ${widget.label}',
                hintStyle: const TextStyle(color: Colors.white54),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SubmitButton(
                text: 'Submit',
                icon: Icons.north_east_rounded,
                onTap: () {
                  final v = controller.text.trim();
                  if (v.isEmpty) return;
                  widget.onSubmit(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============ Show Popup Function ============

void showOneFieldPopup(
  BuildContext context,
  String title,
  String label,
  Function(String) onSubmit,
) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Dialog(
          backgroundColor: Colors.black87,
          insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: OneFieldFormPopup(
              title: title,
              label: label,
              onSubmit: onSubmit,
            ),
          ),
        ),
      );
    },
  );
}
