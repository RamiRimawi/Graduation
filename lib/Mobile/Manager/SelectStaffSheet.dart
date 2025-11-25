import 'package:flutter/material.dart';
import 'Bar.dart';
import 'package:dolphin/Mobile/CustomSendButton.dart';


class SelectStaffSheet extends StatefulWidget {
  final void Function(String staffName) onSelected;

  const SelectStaffSheet({
    super.key,
    required this.onSelected,
  });

  @override
  State<SelectStaffSheet> createState() => _SelectStaffSheetState();
}

class _SelectStaffSheetState extends State<SelectStaffSheet> {
  String? selectedStaff; // الموظف المختار

  @override
  Widget build(BuildContext context) {
    final staff = [
      {"name": "Rami Rimawi", "img": "assets/images/rami.jpg"},
      {"name": "Mohammad Assi", "img": "assets/images/assi.jpg"},
      {"name": "Ameer Yasin", "img": "assets/images/ameer.jpg"},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Select Storage Staff",
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 20,
            children: staff.map((s) {
              final isSelected = selectedStaff == s["name"];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedStaff = s["name"];
                  });
                },
                child: Column(
                  children: [
                    Container(
                      padding: isSelected ? const EdgeInsets.all(3) : EdgeInsets.zero,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: AppColors.gold, width: 3)
                            : null,
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: AssetImage(s["img"]!),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s["name"]!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 26),

          // زر Done بدون تغيير (نفس CustomSendButton)
          CustomSendButton(
            text: "D   o   n   e",
            onTap: () {
              if (selectedStaff == null) return; // لم يتم الاختيار
              Navigator.pop(context);
              widget.onSelected(selectedStaff!);
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
