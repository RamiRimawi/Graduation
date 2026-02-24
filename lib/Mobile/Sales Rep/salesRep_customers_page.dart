import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../supabase_config.dart';

class SalesRepCustomersPage extends StatefulWidget {
  const SalesRepCustomersPage({super.key});

  @override
  State<SalesRepCustomersPage> createState() => _SalesRepCustomersPageState();
}

class _SalesRepCustomersPageState extends State<SalesRepCustomersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearch);
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _customers = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('current_user_id');
      final salesRepId = userIdStr != null ? int.tryParse(userIdStr) : null;

      if (salesRepId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Query accounts table first using type column for quick access
      final response = await supabase
          .from('customer')
          .select(
            'customer_id, name, latitude_location, longitude_location, address, mobile_number, telephone_number, accounts!customer_customer_id_fkey(profile_image)',
          )
          .eq('sales_rep_id', salesRepId)
          .order('name');

      final customers = (response as List<dynamic>).map<Map<String, dynamic>>((
        e,
      ) {
        // Extract profile image from accounts
        String? profileImage;
        final account = e['accounts'];
        if (account is List && account.isNotEmpty) {
          profileImage = account.first['profile_image'] as String?;
        } else if (account is Map<String, dynamic>) {
          profileImage = account['profile_image'] as String?;
        }

        return {
          'id': e['customer_id'] as int?,
          'name': (e['name'] as String?) ?? 'Unknown',
          'latitude': e['latitude_location'],
          'longitude': e['longitude_location'],
          'address': e['address'],
          'mobile': e['mobile_number'],
          'telephone': e['telephone_number'],
          'image': profileImage,
        };
      }).toList();

      setState(() {
        _customers = customers;
        _filteredCustomers = _applySearch(_searchController.text, customers);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading customers: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSearch() {
    setState(() {
      _filteredCustomers = _applySearch(_searchController.text, _customers);
    });
  }

  List<Map<String, dynamic>> _applySearch(
    String query,
    List<Map<String, dynamic>> source,
  ) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return List<Map<String, dynamic>>.from(source);

    return source.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      return name.contains(trimmed);
    }).toList();
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFFB7A447), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search by customer name',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFB7A447)),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _buildSearchField(),
                  ),
                  Expanded(
                    child: _filteredCustomers.isEmpty
                        ? const Center(
                            child: Text(
                              'No customers found',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.85,
                                ),
                            itemCount: _filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = _filteredCustomers[index];
                              return _buildCustomerCard(customer);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final name = customer['name'] as String? ?? 'Unknown';
    final imageUrl = (customer['image'] as String?)?.trim();

    return GestureDetector(
      onTap: () => _showCustomerSheet(customer),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 1,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(child: _buildProfileWidget(name, imageUrl)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerSheet(Map<String, dynamic> customer) {
    final name = (customer['name'] as String?) ?? 'Unknown';
    final imageUrl = (customer['image'] as String?)?.trim();
    final address = (customer['address'] as String?) ?? '—';
    final mobile = (customer['mobile'] as String?) ?? '—';
    final telephone = (customer['telephone'] as String?) ?? '—';

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: const Color(0xFF2D2D2D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 200,
                      child: Center(child: _buildProfileWidget(name, imageUrl, size: 80)),
                    ),
                    const SizedBox(height: 16),
                    _infoRow('Name', name),
                    const SizedBox(height: 8),
                    _infoRow('Address', address),
                    const SizedBox(height: 8),
                    _infoRow('Mobile Number', mobile),
                    const SizedBox(height: 8),
                    _infoRow('Telephone Number', telephone),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileWidget(String name, String? imageUrl, {double size = 48}) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    if (hasImage) {
      return CircleAvatar(
        radius: size,
        backgroundColor: const Color(0xFF3A3A3A),
        backgroundImage: NetworkImage(imageUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }
    // No image — show initials
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0].toUpperCase() : '';
    final initials = '$first$second'.isEmpty ? '?' : '$first$second';
    return CircleAvatar(
      radius: size,
      backgroundColor: const Color(0xFF3A3A3A),
      child: Text(
        initials,
        style: TextStyle(
          color: const Color(0xFFB7A447),
          fontSize: size * 0.75,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
