import 'package:flutter/material.dart';
import '../manager_theme.dart';
import 'package:Dolphin/Mobile/Manager/CustomSendButton.dart';
import '../../supabase_config.dart';

class SelectDeliveryDriverSheet extends StatefulWidget {
  final void Function(int driverId, String driverName) onSelected;

  const SelectDeliveryDriverSheet({super.key, required this.onSelected});

  @override
  State<SelectDeliveryDriverSheet> createState() =>
      _SelectDeliveryDriverSheetState();
}

class _SelectDeliveryDriverSheetState extends State<SelectDeliveryDriverSheet> {
  List<Map<String, dynamic>> _drivers = [];
  bool _loading = true;
  Map<String, dynamic>?
  _selectedDriver; // {delivery_driver_id, name, profile_image}

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    try {
      // Fetch active driver accounts using type column for quick access
      final rows = await supabase
          .from('accounts')
          .select(
            'user_id, profile_image, delivery_driver!delivery_driver_delivery_driver_id_fkey(name)',
          )
          .eq('type', 'Delivery Driver')
          .eq('is_active', true)
          .order('user_id');

      setState(() {
        // Normalize result to {delivery_driver_id, name, profile_image}
        _drivers = List<Map<String, dynamic>>.from(
          rows.map((r) {
            final dd = (r['delivery_driver'] ?? {}) as Map<String, dynamic>;
            return {
              'delivery_driver_id': r['user_id'],
              'name': dd['name'],
              'profile_image': r['profile_image'],
            };
          }),
        );
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _drivers = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final drivers = _drivers;

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

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          else if (drivers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No drivers found',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 20,
              children: drivers.map((d) {
                final name = d['name'] as String? ?? 'Unknown';
                final id = d['delivery_driver_id'] as int? ?? 0;
                final imageUrl = d['profile_image'] as String?;
                final isSelected =
                    _selectedDriver != null &&
                    _selectedDriver!['delivery_driver_id'] == id;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDriver = d);
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
                          backgroundColor: AppColors.card,
                          backgroundImage:
                              imageUrl != null && imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl == null || imageUrl.isEmpty
                              ? Text(
                                  name.isNotEmpty
                                      ? name.substring(0, 1).toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
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
            text: "D  o  n  e",
            onTap: () {
              if (_selectedDriver == null) return;
              final id = _selectedDriver!['delivery_driver_id'] as int? ?? 0;
              final name = _selectedDriver!['name'] as String? ?? 'Unknown';
              Navigator.pop(context);
              widget.onSelected(id, name);
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
