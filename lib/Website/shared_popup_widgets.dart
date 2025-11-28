import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TwoColRow extends StatelessWidget {
  final Widget left;
  final Widget? right;

  const TwoColRow({required this.left, this.right, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 26),
        Expanded(child: right ?? const SizedBox()),
      ],
    );
  }
}

class FieldInput extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final TextInputType? type;
  final Widget? suffix;

  const FieldInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.type,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
            keyboardType: type,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(color: Colors.white54, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: suffix == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: suffix,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class CityDropdown extends StatelessWidget {
  final List<String> items;
  final String value;
  final ValueChanged<String> onChanged;

  const CityDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB7A447), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            Icons.expand_more_rounded,
            color: Color(0xFFB7A447),
          ),
          dropdownColor: const Color(0xFF2B2B2B),
          style: const TextStyle(color: Colors.white),
          items: items
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c),
                  ))
              .toList(),
          onChanged: (v) => v == null ? null : onChanged(v),
        ),
      ),
    );
  }
}

class SubmitButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const SubmitButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF9D949),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 34),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 18,
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 26),
        label: Text(text),
      ),
    );
  }
}
