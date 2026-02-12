import 'package:flutter/material.dart';
import 'staff_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'staff_sync_manager.dart';

class HomeStaff extends StatefulWidget {
  const HomeStaff({super.key});

  @override
  State<HomeStaff> createState() => _HomeStaffState();
}

class _HomeStaffState extends State<HomeStaff> {
  bool _loading = true;
  List<Map<String, dynamic>> customers = const [];

  @override
  void initState() {
    super.initState();
    _initializeSyncManager();
    _fetchCustomers();
  }

  Future<void> _initializeSyncManager() async {
    await StaffSyncManager.instance.initialize();
  }

  @override
  void dispose() {
    StaffSyncManager.instance.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    try {
      if (mounted) setState(() => _loading = true);
      final prefs = await SharedPreferences.getInstance();
      final String? userIdStr = prefs.getString('current_user_id');
      final int? staffId = userIdStr != null ? int.tryParse(userIdStr) : null;
      if (staffId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      // Use sync manager's cache-first strategy
      final mapped = await StaffSyncManager.instance.fetchOrdersWithCache(
        staffId,
      );

      if (mounted) {
        setState(() {
          customers = mapped;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching customers: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFE14D)),
              )
            : customers.isEmpty
            ? const Center(
                child: Text(
                  'No orders Preparing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerDetail(
                              customerName: customer['name'],
                              customerId: customer['id'],
                            ),
                          ),
                        );
                        // Refresh the list when returning from detail page
                        if (result == true && mounted) {
                          _fetchCustomers();
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 1,
                              spreadRadius: 1,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // TITLE ROW
                              Row(
                                children: [
                                  Text(
                                    'ID #',
                                    style: TextStyle(
                                      color: const Color(0xFFB7A447),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 34),
                                  Text(
                                    'Customer Name',
                                    style: TextStyle(
                                      color: const Color(0xFFB7A447),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 2),

                              // MAIN CONTENT
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${customer['id']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 23,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 28),

                                  // NAME
                                  Expanded(
                                    child: Text(
                                      customer['name'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // PRODUCT BOX — bigger
                                  Container(
                                    width: 85,
                                    height: 89,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF262626),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${customer['products']}',
                                          style: const TextStyle(
                                            color: Color(0xFFFFEFFF),
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Product',
                                          style: TextStyle(
                                            color: const Color(0xFFB7A447),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
