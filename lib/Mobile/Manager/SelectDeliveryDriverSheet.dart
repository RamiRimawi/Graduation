import 'package:flutter/material.dart';
import 'Bar.dart';
import 'package:dolphin/Mobile/Manager/CustomSendButton.dart';

class SelectDeliveryDriverSheet extends StatefulWidget {
  final void Function(String driverName) onSelected;

  const SelectDeliveryDriverSheet({super.key, required this.onSelected});

  @override
  State<SelectDeliveryDriverSheet> createState() =>
      _SelectDeliveryDriverSheetState();
}

class _SelectDeliveryDriverSheetState extends State<SelectDeliveryDriverSheet> {
  String? selectedDriver; // السائق المختار

  @override
  Widget build(BuildContext context) {
    final drivers = [
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
            "Select Delivery Driver",
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
            children: drivers.map((d) {
              final isSelected = selectedDriver == d["name"];

              return GestureDetector(
                onTap: () {
                  setState(() => selectedDriver = d["name"]);
                },
                child: Column(
                  children: [
                    Container(
                      padding: isSelected
                          ? const EdgeInsets.all(3)
                          : EdgeInsets.zero,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: AppColors.gold, width: 3)
                            : null,
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: AssetImage(d["img"]!),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      d["name"]!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 26),

          CustomSendButton(
            text: "D   o   n   e",
            onTap: () {
              if (selectedDriver == null) return;
              Navigator.pop(context);
              widget.onSelected(selectedDriver!);
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
