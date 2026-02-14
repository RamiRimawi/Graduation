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
  Set<int> _pendingOrderIds = {};
  bool _lastOnlineState = true;
  bool _lastSyncingState = false;

  @override
  void initState() {
    super.initState();
    _initializeSyncManager();
    _fetchCustomers();
    _startConnectivityMonitoring();
  }

  Future<void> _initializeSyncManager() async {
    await StaffSyncManager.instance.initialize();
  }

  void _startConnectivityMonitoring() {
    // Check connectivity and sync status periodically
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final isOnline = StaffSyncManager.instance.isOnline;
        final isSyncing = StaffSyncManager.instance.isSyncing;

        // If we just came back online, refresh the list
        if (!_lastOnlineState && isOnline) {
          _fetchCustomers();
        }

        // If sync just finished, refresh to update UI
        if (_lastSyncingState && !isSyncing) {
          _fetchCustomers();
        }

        _lastOnlineState = isOnline;
        _lastSyncingState = isSyncing;
        _startConnectivityMonitoring();
      }
    });
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

      // Get pending order IDs (check even when offline)
      _pendingOrderIds = await StaffSyncManager.instance.getPendingOrderIds();
      if (mounted) setState(() {});

      // Preemptively cache all order details when online (in background)
      if (StaffSyncManager.instance.isOnline && mapped.isNotEmpty) {
        _preCacheOrderDetails(staffId, mapped);
      }
    } catch (e) {
      debugPrint('Error fetching customers: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _preCacheOrderDetails(
    int staffId,
    List<Map<String, dynamic>> orders,
  ) async {
    for (final order in orders) {
      final orderId = order['id'] as int?;
      if (orderId != null) {
        try {
          // Cache each order's details
          await StaffSyncManager.instance.fetchProductsWithCache(
            orderId,
            staffId,
          );
        } catch (e) {
          debugPrint('Background cache error for order $orderId: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = StaffSyncManager.instance.isOnline;
    final isSyncing = StaffSyncManager.instance.isSyncing;

    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: SafeArea(
        child: Column(
          children: [
            // Status banner
            if (!isOnline || isSyncing || _pendingOrderIds.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: !isOnline
                    ? Colors.red.withOpacity(0.2)
                    : const Color(0xFFFFE14D).withOpacity(0.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      !isOnline
                          ? Icons.cloud_off
                          : isSyncing
                          ? Icons.sync
                          : Icons.cloud_queue,
                      size: 18,
                      color: !isOnline ? Colors.red : const Color(0xFFFFE14D),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      !isOnline
                          ? 'Offline Mode'
                          : isSyncing
                          ? 'Syncing changes...'
                          : '${_pendingOrderIds.length} order(s) pending sync',
                      style: TextStyle(
                        color: !isOnline ? Colors.red : const Color(0xFFFFE14D),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFE14D),
                      ),
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
                        final customerId = customer['id'] as int;
                        final hasPendingSync = _pendingOrderIds.contains(
                          customerId,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            onTap: hasPendingSync
                                ? () {
                                    // Prevent opening order with pending sync
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isOnline
                                              ? 'This order is currently syncing. Please wait...'
                                              : 'This order has pending changes. Please connect to the internet to sync first.',
                                        ),
                                        backgroundColor: const Color(
                                          0xFFFFE14D,
                                        ),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                : () async {
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
                            child: Stack(
                              children: [
                                Opacity(
                                  opacity: hasPendingSync ? 0.7 : 1.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D2D2D),
                                      borderRadius: BorderRadius.circular(18),
                                      border: hasPendingSync
                                          ? Border.all(
                                              color: const Color(0xFFFFE14D),
                                              width: 2,
                                            )
                                          : null,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // TITLE ROW
                                          Row(
                                            children: [
                                              Text(
                                                'ID #',
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFFB7A447,
                                                  ),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 34),
                                              Text(
                                                'Customer Name',
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFFB7A447,
                                                  ),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 2),

                                          // MAIN CONTENT
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
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
                                                  color: const Color(
                                                    0xFF262626,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      '${customer['products']}',
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFFFFEFFF,
                                                        ),
                                                        fontSize: 25,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      'Product',
                                                      style: TextStyle(
                                                        color: const Color(
                                                          0xFFB7A447,
                                                        ),
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
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
                                // Lock icon for pending orders
                                if (hasPendingSync)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.lock,
                                          size: 40,
                                          color: Color(0xFFFFE14D),
                                        ),
                                      ),
                                    ),
                                  ),
                                // Pending sync indicator badge
                                if (hasPendingSync)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFE14D),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFFFE14D,
                                            ).withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isOnline
                                                ? Icons.cloud_upload
                                                : Icons.cloud_off,
                                            size: 14,
                                            color: const Color(0xFF202020),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isOnline ? 'Syncing...' : 'Pending',
                                            style: const TextStyle(
                                              color: Color(0xFF202020),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
