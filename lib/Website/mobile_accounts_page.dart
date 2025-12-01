import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

import 'sidebar.dart';

class MobileAccountsPage extends StatefulWidget {
  const MobileAccountsPage({super.key});

  // Shared colors used by helper widgets
  static const Color gold = Color(0xFFF9D949);
  static const Color borderGold = Color(0xFFB7A447);

  @override
  State<MobileAccountsPage> createState() => _MobileAccountsPageState();
}

class _MobileAccountsPageState extends State<MobileAccountsPage> {
  // ألوان عامة
  static const Color bg = Color(0xFF202020);
  static const Color panel = Color(0xFF2D2D2D);
  static const Color gold = Color(0xFFF9D949);
  static const Color borderGold = Color(0xFFB7A447);

  final Map<String, List<_AccountItem>> accountGroups = {
    "Storage Manager": [],
    "Storage Staff": [],
    "Delivery Driver": [],
    "Customer": [],
    "Sales Rep": [],
    "Supplier": [],
  };

  bool _loading = true;
  String? _error;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Filter state
  Set<String> _selectedRoles = {};
  final GlobalKey _filterButtonKey = GlobalKey();
  OverlayEntry? _filterOverlay;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _filterOverlay?.remove();
    _filterOverlay = null;
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      // Ensure Supabase is initialized (safe if already initialized)
      if (Supabase.instance.client == null) {
        await SupabaseConfig.initialize();
      }

      // Fetch names by role from corresponding tables
      final client = supabase;

      // Only include users that have an account (and active if the column exists)
      final storageManagers = await client
          .from('storage_manager')
          .select(
            'name,user_account_storage_manager!inner(is_active,profile_image)',
          )
          .eq('user_account_storage_manager.is_active', 'yes');
      final storageStaff = await client
          .from('storage_staff')
          .select(
            'name,user_account_storage_staff!inner(is_active,profile_image)',
          )
          .eq('user_account_storage_staff.is_active', 'yes');
      final deliveryDrivers = await client
          .from('delivery_driver')
          .select(
            'name,user_account_delivery_driver!inner(is_active,profile_image)',
          )
          .eq('user_account_delivery_driver.is_active', 'yes');
      final customers = await client
          .from('customer')
          .select('name,user_account_customer!inner(is_active,profile_image)')
          .eq('user_account_customer.is_active', 'yes');
      final salesReps = await client
          .from('sales_representative')
          .select('name,user_account_sales_rep!inner(is_active,profile_image)')
          .eq('user_account_sales_rep.is_active', 'yes');
      final suppliers = await client
          .from('supplier')
          .select('name,user_account_supplier!inner(is_active,profile_image)')
          .eq('user_account_supplier.is_active', 'yes');

      setState(() {
        accountGroups["Storage Manager"] = _extractItems(storageManagers);
        accountGroups["Storage Staff"] = _extractItems(storageStaff);
        accountGroups["Delivery Driver"] = _extractItems(deliveryDrivers);
        accountGroups["Customer"] = _extractItems(customers);
        accountGroups["Sales Rep"] = _extractItems(salesReps);
        accountGroups["Supplier"] = _extractItems(suppliers);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<_AccountItem> _extractItems(dynamic rows) {
    if (rows is List) {
      final items = rows
          .map((raw) {
            final r = raw as Map<String, dynamic>;
            final name = (r["name"] as String?)?.trim();
            // Retrieve profile_image from the joined user_account_* relation
            String? img;
            for (final key in [
              'user_account_storage_manager',
              'user_account_storage_staff',
              'user_account_delivery_driver',
              'user_account_customer',
              'user_account_sales_rep',
              'user_account_supplier',
            ]) {
              final rel = r[key];
              if (rel is Map<String, dynamic>) {
                img = rel['profile_image'] as String?;
                if (img != null && img!.isNotEmpty) break;
              }
            }
            return _AccountItem(name: name ?? '', imageUrl: img);
          })
          .where((i) => i.name.isNotEmpty)
          .toList();
      items.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return items;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Row(
        children: [
          const Sidebar(activeIndex: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان + الزر
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Mobile Account",
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () => _openRoleChooser(context),
                        icon: const Icon(
                          Icons.person_add_alt_1,
                          color: Colors.black,
                        ),
                        label: const Text(
                          "Add Account",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // حقل البحث مع زر الفلتر بجانبه
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 250,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: panel,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_search_rounded,
                              color: Colors.white60,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: "Search account name",
                                  hintStyle: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value.trim();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 5),
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                splashRadius: 18,
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white60,
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // زر الفلتر بجانب حقل البحث (نفس ستايل inventory_page)
                      _RoundIconButton(
                        key: _filterButtonKey,
                        icon: Icons.filter_alt_rounded,
                        onTap: _toggleFilterPopup,
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // القوائم + الكروت
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(color: gold),
                          )
                        : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final entry
                                    in _filteredGroups().entries) ...[
                                  Text(
                                    entry.key,
                                    style: GoogleFonts.roboto(
                                      color: const Color(0xFFB7A447),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      for (final item in entry.value)
                                        _AccountCard(
                                          name: item.name,
                                          imageUrl: item.imageUrl,
                                        ),
                                      if (entry.value.isEmpty)
                                        const Text(
                                          'No accounts found',
                                          style: TextStyle(
                                            color: Colors.white54,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 35),
                                ],
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<_AccountItem>> _filteredGroups() {
    Map<String, List<_AccountItem>> filtered = {};

    // First apply role filter
    if (_selectedRoles.isEmpty) {
      filtered = Map.from(accountGroups);
    } else {
      accountGroups.forEach((role, items) {
        if (_selectedRoles.contains(role)) {
          filtered[role] = items;
        }
      });
    }

    // Then apply search filter
    if (_searchQuery.isEmpty) return filtered;

    final q = _searchQuery.toLowerCase();
    final Map<String, List<_AccountItem>> searchFiltered = {};
    filtered.forEach((role, items) {
      searchFiltered[role] = items
          .where((i) => i.name.toLowerCase().startsWith(q))
          .toList();
    });
    return searchFiltered;
  }

  /* ----------------------- FILTER POPUP ----------------------- */

  void _toggleFilterPopup() {
    if (_filterOverlay != null) {
      _closeFilterPopup();
    } else {
      _showFilterPopup();
    }
  }

  void _showFilterPopup() {
    final RenderBox? renderBox =
        _filterButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _filterOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible background to detect clicks outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeFilterPopup,
              child: Container(color: Colors.transparent),
            ),
          ),
          // The actual filter popup
          Positioned(
            left:
                offset.dx -
                200 +
                size.width, // Align right edge of popup with button
            top: offset.dy + size.height + 8,
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setOverlayState) => GestureDetector(
                  onTap: () {}, // Prevent clicks from closing
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderGold, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          offset: Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Filter by Role',
                            style: GoogleFonts.roboto(
                              color: gold,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(color: Color(0xFF3D3D3D), height: 1),
                        const SizedBox(height: 8),
                        ..._buildRoleCheckboxes(setOverlayState),
                        const SizedBox(height: 8),
                        const Divider(color: Color(0xFF3D3D3D), height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedRoles.clear();
                                });
                                setOverlayState(() {});
                              },
                              child: const Text(
                                'Clear All',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_filterOverlay!);
  }

  List<Widget> _buildRoleCheckboxes(StateSetter setOverlayState) {
    final roles = accountGroups.keys.toList();
    return roles.map((role) {
      final isSelected = _selectedRoles.contains(role);
      return InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedRoles.remove(role);
            } else {
              _selectedRoles.add(role);
            }
          });
          setOverlayState(() {}); // Update the overlay UI
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isSelected ? gold : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? gold : Colors.white54,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(Icons.check, size: 14, color: Colors.black),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  role,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _closeFilterPopup() {
    _filterOverlay?.remove();
    _filterOverlay = null;
  }

  /* ----------------------- POPUP: CHOOSE ROLE ----------------------- */

  void _openRoleChooser(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        return Stack(
          children: [
            // Blur الخلفية
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(color: Colors.black.withOpacity(0.55)),
                ),
              ),
            ),

            // صندوق اختيار الدور
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 880),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        offset: Offset(0, 10),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 6,
                          right: 8,
                          left: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Choose Account Role",
                              style: GoogleFonts.roboto(
                                color: gold,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 26),
                            Wrap(
                              spacing: 22,
                              runSpacing: 22,
                              alignment: WrapAlignment.center,
                              children: [
                                _RoleCard(
                                  title: 'Customer',
                                  icon: Icons.groups_rounded,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _openRoleForm(
                                      context,
                                      _RoleFormType.customer,
                                    );
                                  },
                                ),
                                _RoleCard(
                                  title: 'Supplier',
                                  icon: Icons.inventory_2_rounded,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _openRoleForm(
                                      context,
                                      _RoleFormType.supplier,
                                    );
                                  },
                                ),
                                _RoleCard(
                                  title: 'Sales Rep',
                                  icon: Icons.badge_rounded,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _openRoleForm(
                                      context,
                                      _RoleFormType.salesRep,
                                    );
                                  },
                                ),
                                _RoleCard(
                                  title: 'Storage Staff',
                                  icon: Icons.warehouse_rounded,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _openRoleForm(
                                      context,
                                      _RoleFormType.storageStaff,
                                    );
                                  },
                                ),
                                _RoleCard(
                                  title: 'Delivery',
                                  icon: Icons.local_shipping_rounded,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _openRoleForm(
                                      context,
                                      _RoleFormType.deliveryDriver,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          splashRadius: 20,
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /* ------------------- POPUPS: FORMS لكل نوع حساب ------------------- */

  void _openRoleForm(BuildContext context, _RoleFormType type) {
    late final String title;
    late final Widget form;

    switch (type) {
      case _RoleFormType.customer:
        title = 'Customer';
        form = const _SimpleThreeFieldForm(
          firstLabel: 'Customer Name',
          firstHint: 'Select Customer Name',
        );
        break;
      case _RoleFormType.supplier:
        title = 'Supplier';
        form = const _SimpleThreeFieldForm(
          firstLabel: 'Supplier Name',
          firstHint: 'Select Supplier Name',
        );
        break;
      case _RoleFormType.salesRep:
        title = 'Sales Rep';
        form = const _SimpleThreeFieldForm(
          firstLabel: 'Sales Rep Name',
          firstHint: 'Select Sales Rep Name',
        );
        break;
      case _RoleFormType.deliveryDriver:
        title = 'Delivery Driver';
        form = const _ExtendedStaffForm(
          title: 'Delivery Driver',
          nameLabel: 'Delivery Driver Name',
        );
        break;
      case _RoleFormType.storageStaff:
        title = 'Storage Staff';
        form = const _ExtendedStaffForm(
          title: 'Storage Staff',
          nameLabel: 'Storage Staff Name',
        );
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(color: Colors.black.withOpacity(0.55)),
                ),
              ),
            ),
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 880,
                    minWidth: 620,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        offset: Offset(0, 10),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 6,
                          right: 8,
                          left: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.roboto(
                                color: gold,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 26),
                            form,
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          splashRadius: 20,
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// أنواع النماذج
enum _RoleFormType {
  customer,
  supplier,
  salesRep,
  storageStaff,
  deliveryDriver,
}

// الكرت في القائمة الرئيسية
class _AccountCard extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _AccountCard({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(0, 3), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.grey.shade800,
            backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                ? NetworkImage(imageUrl!)
                : null,
            child: (imageUrl == null || imageUrl!.isEmpty)
                ? const Icon(Icons.person, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountItem {
  final String name;
  final String? imageUrl;
  _AccountItem({required this.name, this.imageUrl});
}

/* -------------------- Role Card داخل Popup -------------------- */

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 210,
        height: 170,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              offset: Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Colors.black.withOpacity(0.85)),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.roboto(
                color: const Color(0xFFF9D949),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------- النماذج البسيطة (Customer/Supplier/SalesRep) ----------------- */

class _SimpleThreeFieldForm extends StatelessWidget {
  final String firstLabel;
  final String firstHint;

  const _SimpleThreeFieldForm({
    required this.firstLabel,
    required this.firstHint,
  });

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormLabel(firstLabel),
        const SizedBox(height: 6),
        _FormFieldBox(controller: nameCtrl, hint: firstHint, isDropdown: true),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FormLabel('User Name'),
                  const SizedBox(height: 6),
                  _FormFieldBox(controller: userCtrl, hint: 'Entre User Name'),
                ],
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FormLabel('Password'),
                  const SizedBox(height: 6),
                  _FormFieldBox(
                    controller: passCtrl,
                    hint: 'Entre Password',
                    obscure: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const _SubmitButton(),
      ],
    );
  }
}

/* ----------------- النماذج الممتدة (Storage Staff / Delivery Driver) ----------------- */

class _ExtendedStaffForm extends StatelessWidget {
  final String title;
  final String nameLabel;

  const _ExtendedStaffForm({required this.title, required this.nameLabel});

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormLabel(nameLabel),
                    const SizedBox(height: 6),
                    _FormFieldBox(
                      controller: nameCtrl,
                      hint: 'Entre Full Name',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Mobile / Telephone
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormLabel('Mobile Number'),
                    const SizedBox(height: 6),
                    _FormFieldBox(
                      controller: mobileCtrl,
                      hint: 'Entre Mobile Number',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormLabel('Telephone Number'),
                    const SizedBox(height: 6),
                    _FormFieldBox(
                      controller: telCtrl,
                      hint: 'Entre Telephone Number',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Address
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormLabel('Address'),
                    const SizedBox(height: 6),
                    _FormFieldBox(
                      controller: addressCtrl,
                      hint: 'Entre Address',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // User / Pass
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormLabel('User Name'),
                    const SizedBox(height: 6),
                    _FormFieldBox(
                      controller: userCtrl,
                      hint: 'Entre Account User Name',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormLabel('Password'),
                    const SizedBox(height: 6),
                    _FormFieldBox(
                      controller: passCtrl,
                      hint: 'Entre Account Password',
                      obscure: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const _SubmitButton(),
        ],
      ),
    );
  }
}

/* --------------------------- Helpers للحقول --------------------------- */

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _FormFieldBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool isDropdown;
  final TextInputType? keyboardType;

  const _FormFieldBox({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.isDropdown = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232427),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MobileAccountsPage.borderGold, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: isDropdown
              ? const Icon(
                  Icons.expand_more_rounded,
                  color: MobileAccountsPage.borderGold,
                )
              : null,
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: 58,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: MobileAccountsPage.gold,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              fontSize: 18,
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop(); // مؤقتاً بس يسكر الـ popup
          },
          icon: const Icon(Icons.person_add_alt_1, size: 26),
          label: const Text("Submit"),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
      ),
      child: Material(
        color: const Color(0xFF2D2D2D),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: const Color(0xFFB7A447)),
          ),
        ),
      ),
    );
  }
}
