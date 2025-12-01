import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'shared_popup_widgets.dart';
import '../supabase_config.dart';

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
  final FocusNode _focusNode = FocusNode();
  String? fieldError;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  void _clearError() {
    if (fieldError != null) {
      setState(() {
        fieldError = null;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 400, maxWidth: 600),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            widget.label,
            style: GoogleFonts.roboto(
              color: const Color(0xFFB7A447),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: fieldError != null
                    ? Colors.red
                    : _isFocused
                    ? const Color(0xFFB7A447)
                    : const Color(0xFF3D3D3D),
                width: (fieldError != null || _isFocused) ? 2 : 1,
              ),
            ),
            child: TextField(
              controller: controller,
              focusNode: _focusNode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              onChanged: (_) => _clearError(),
              decoration: InputDecoration(
                hintText: 'Enter ${widget.label}',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ),
          ),
          if (fieldError != null) ...[
            const SizedBox(height: 4),
            Text(
              fieldError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 18),

          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SubmitButton(
                text: 'Submit',
                icon: Icons.north_east_rounded,
                onTap: () async {
                  final v = controller.text.trim();
                  if (v.isEmpty) {
                    setState(() {
                      fieldError = '${widget.label} is required';
                    });
                    return;
                  }

                  try {
                    // decide which table based on title
                    final title = widget.title.toLowerCase();
                    if (title.contains('brand')) {
                      final inserted = await supabase
                          .from('brand')
                          .insert({'name': v})
                          .select()
                          .maybeSingle();
                      if (inserted == null) throw Exception('Insert failed');
                      widget.onSubmit(inserted['name'] ?? v);
                    } else if (title.contains('category')) {
                      final inserted = await supabase
                          .from('product_category')
                          .insert({'name': v})
                          .select()
                          .maybeSingle();
                      if (inserted == null) throw Exception('Insert failed');
                      widget.onSubmit(inserted['name'] ?? v);
                    } else {
                      // default: just pass value
                      widget.onSubmit(v);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add item: $e')),
                    );
                  }
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
          backgroundColor: const Color(0xFF2D2D2D),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 120,
            vertical: 40,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
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
