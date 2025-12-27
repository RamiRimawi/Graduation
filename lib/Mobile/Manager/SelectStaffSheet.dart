import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'manager_theme.dart';

class SelectStaffSheet extends StatefulWidget {
  final void Function(int staffId, int inventoryId, String displayName)
  onSelected;
  final bool isModal;
  final String? preSelectedStaffName;

  const SelectStaffSheet({
    super.key,
    required this.onSelected,
    this.isModal = true,
    this.preSelectedStaffName,
  });

  @override
  State<SelectStaffSheet> createState() => _SelectStaffSheetState();
}

class _SelectStaffSheetState extends State<SelectStaffSheet> {
  String? selectedStaff;
  late Future<Map<String, List<Map<String, dynamic>>>> staffByInventory;

  @override
  void initState() {
    super.initState();
    staffByInventory = _fetchStaffGroupedByInventory();
    if (widget.preSelectedStaffName != null) {
      selectedStaff = widget.preSelectedStaffName;
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>>
  _fetchStaffGroupedByInventory() async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch all storage staff with their inventory_id
      // Pull profile images from the linked user_account_storage_staff table
      final staffResponse = await supabase
          .from('storage_staff')
          .select(
            'storage_staff_id, name, inventory_id, user_account_storage_staff(profile_image)',
          );

      if (staffResponse.isEmpty) {
        return {};
      }

      // Get unique inventory IDs
      final inventoryIds = <int?>{};
      for (final staff in staffResponse) {
        inventoryIds.add(staff['inventory_id'] as int?);
      }
      inventoryIds.remove(null); // Remove null values

      // Fetch inventory names for those IDs
      Map<int, String> inventoryNames = {};
      if (inventoryIds.isNotEmpty) {
        final inventoryResponse = await supabase
            .from('inventory')
            .select('inventory_id, inventory_name')
            .inFilter('inventory_id', inventoryIds.toList());

        for (final inv in inventoryResponse) {
          inventoryNames[inv['inventory_id'] as int] =
              inv['inventory_name'] as String;
        }
      }

      // Group staff by inventory name
      final grouped = <String, List<Map<String, dynamic>>>{};

      for (final staff in staffResponse) {
        final inventoryId = staff['inventory_id'] as int?;
        if (inventoryId != null && inventoryNames.containsKey(inventoryId)) {
          final inventoryName = inventoryNames[inventoryId]!;
          if (!grouped.containsKey(inventoryName)) {
            grouped[inventoryName] = [];
          }
          grouped[inventoryName]!.add(staff);
        }
      }

      return grouped;
    } catch (e) {
      print('Error fetching staff: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                  future: staffByInventory,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      );
                    }

                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No storage staff available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    final staffByInv = snapshot.data!;
                    final inventoryNames = staffByInv.keys.toList()..sort();

                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: inventoryNames.map((inventoryName) {
                            final staffList = staffByInv[inventoryName]!;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Center(
                                      child: Text(
                                        inventoryName,
                                        style: const TextStyle(
                                          color: AppColors.gold,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 28,
                                    runSpacing: 20,
                                    children: staffList.map((staff) {
                                      final staffName =
                                          staff['name'] as String? ?? 'Unknown';
                                      String? profileImage;
                                      final account =
                                          staff['user_account_storage_staff'];
                                      if (account is List &&
                                          account.isNotEmpty) {
                                        profileImage =
                                            account.first['profile_image']
                                                as String?;
                                      } else if (account
                                          is Map<String, dynamic>) {
                                        profileImage =
                                            account['profile_image'] as String?;
                                      }
                                      final isSelected =
                                          selectedStaff == staffName;

                                      return GestureDetector(
                                        onTap: () {
                                          final staffId =
                                              staff['storage_staff_id'] as int;
                                          final inventoryId =
                                              staff['inventory_id'] as int;
                                          setState(() {
                                            selectedStaff = staffName;
                                          });
                                          widget.onSelected(
                                            staffId,
                                            inventoryId,
                                            '$staffName - $inventoryName',
                                          );
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
                                                    ? Border.all(
                                                        color: AppColors.gold,
                                                        width: 3,
                                                      )
                                                    : null,
                                              ),
                                              child: CircleAvatar(
                                                radius: 32,
                                                backgroundImage:
                                                    profileImage != null &&
                                                        profileImage.isNotEmpty
                                                    ? NetworkImage(profileImage)
                                                    : const AssetImage(
                                                            'assets/images/placeholder.png',
                                                          )
                                                          as ImageProvider,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              staffName,
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
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
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
