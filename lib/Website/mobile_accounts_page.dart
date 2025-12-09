import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../supabase_config.dart';

import 'sidebar.dart';
import 'accounts_popups/add_customer_account_popup.dart';
import 'accounts_popups/add_supplier_account_popup.dart';
import 'accounts_popups/add_sales_rep_account_popup.dart';
import 'accounts_popups/add_storage_staff_account_popup.dart';
import 'accounts_popups/add_delivery_driver_account_popup.dart';

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
      await SupabaseConfig.initialize();

      // Fetch names by role from corresponding tables
      final client = supabase;

      // Only include users that have an account (and active if the column exists)
      final storageManagers = await client
          .from('storage_manager')
          .select(
            'storage_manager_id,name,mobile_number,telephone_number,address,user_account_storage_manager!inner(is_active,profile_image,added_by,added_time,password)',
          )
          .eq('user_account_storage_manager.is_active', 'yes');
      final storageStaff = await client
          .from('storage_staff')
          .select(
            'storage_staff_id,name,mobile_number,telephone_number,address,user_account_storage_staff!inner(is_active,profile_image,added_by,added_time,password)',
          )
          .eq('user_account_storage_staff.is_active', 'yes');
      final deliveryDrivers = await client
          .from('delivery_driver')
          .select(
            'delivery_driver_id,name,mobile_number,telephone_number,address,user_account_delivery_driver!inner(is_active,profile_image,added_by,added_time,password)',
          )
          .eq('user_account_delivery_driver.is_active', 'yes');
      final customers = await client
          .from('customer')
          .select(
            'customer_id,name,email,mobile_number,telephone_number,address,user_account_customer!inner(is_active,profile_image,added_by,added_time,password)',
          )
          .eq('user_account_customer.is_active', 'yes');
      final salesReps = await client
          .from('sales_representative')
          .select(
            'sales_rep_id,name,email,mobile_number,telephone_number,user_account_sales_rep!inner(is_active,profile_image,added_by,added_time,password)',
          )
          .eq('user_account_sales_rep.is_active', 'yes');
      final suppliers = await client
          .from('supplier')
          .select(
            'supplier_id,name,email,mobile_number,telephone_number,address,user_account_supplier!inner(is_active,profile_image,added_by,added_time,password)',
          )
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
                if (img != null && img.isNotEmpty) break;
              }
            }
            return _AccountItem(name: name ?? '', imageUrl: img, rawData: r);
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
                                          onTap: () => _showAccountDetails(
                                            context,
                                            item,
                                            entry.key,
                                          ),
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
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: const Color(0xFF3D3D3D),
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
        form = const SizedBox.shrink();
        break;
      case _RoleFormType.supplier:
        title = 'Supplier';
        form = const SizedBox.shrink();
        break;
      case _RoleFormType.salesRep:
        title = 'Sales Rep';
        form = const SizedBox.shrink();
        break;
      case _RoleFormType.deliveryDriver:
        title = 'Delivery Driver';
        form = const SizedBox.shrink();
        break;
      case _RoleFormType.storageStaff:
        title = 'Storage Staff';
        form = const SizedBox.shrink();
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
              child: Builder(
                builder: (_) {
                  switch (type) {
                    case _RoleFormType.customer:
                      return AddCustomerAccountPopup(
                        onAccountCreated: () {
                          setState(() {
                            _loadAccounts();
                          });
                        },
                      );
                    case _RoleFormType.supplier:
                      return AddSupplierAccountPopup(
                        onAccountCreated: () {
                          setState(() {
                            _loadAccounts();
                          });
                        },
                      );
                    case _RoleFormType.salesRep:
                      return AddSalesRepAccountPopup(
                        onAccountCreated: () {
                          setState(() {
                            _loadAccounts();
                          });
                        },
                      );
                    case _RoleFormType.storageStaff:
                      return AddStorageStaffAccountPopup(
                        onAccountCreated: () {
                          setState(() {
                            _loadAccounts();
                          });
                        },
                      );
                    case _RoleFormType.deliveryDriver:
                      return AddDeliveryDriverAccountPopup(
                        onAccountCreated: () {
                          setState(() {
                            _loadAccounts();
                          });
                        },
                      );
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /* ----------------------- ACCOUNT DETAILS POPUP ----------------------- */

  void _showAccountDetails(
    BuildContext context,
    _AccountItem item,
    String role,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
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
              child: _AccountDetailsPopup(
                item: item,
                role: role,
                onEdit: () {
                  Navigator.of(ctx).pop();
                  _openEditPopup(ctx, role, item);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _openEditPopup(BuildContext context, String role, _AccountItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
              child: _EditAccountPopup(item: item, role: role),
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

/* ----------------------- EDIT ACCOUNT POPUP ----------------------- */

class _EditAccountPopup extends StatefulWidget {
  final _AccountItem item;
  final String role;

  const _EditAccountPopup({required this.item, required this.role});

  @override
  State<_EditAccountPopup> createState() => _EditAccountPopupState();
}

class _EditAccountPopupState extends State<_EditAccountPopup> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;

  // Controllers for all possible fields
  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _telephoneController;
  late TextEditingController _addressController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final data = widget.item.rawData;

    _nameController = TextEditingController(
      text: data['name']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: data['email']?.toString() ?? '',
    );
    _mobileController = TextEditingController(
      text: data['mobile_number']?.toString() ?? '',
    );
    _telephoneController = TextEditingController(
      text: data['telephone_number']?.toString() ?? '',
    );
    _addressController = TextEditingController(
      text: data['address']?.toString() ?? '',
    );

    // Get password from account data
    final accountKeys = {
      'Storage Manager': 'user_account_storage_manager',
      'Storage Staff': 'user_account_storage_staff',
      'Delivery Driver': 'user_account_delivery_driver',
      'Customer': 'user_account_customer',
      'Sales Rep': 'user_account_sales_rep',
      'Supplier': 'user_account_supplier',
    };
    final accountKey = accountKeys[widget.role];
    String? password;
    if (accountKey != null && data[accountKey] is Map<String, dynamic>) {
      final accountData = data[accountKey] as Map<String, dynamic>;
      password = accountData['password']?.toString();
    }
    _passwordController = TextEditingController(text: password ?? '');

    // Get ID based on role
    final idKeys = {
      'Storage Manager': 'storage_manager_id',
      'Storage Staff': 'storage_staff_id',
      'Delivery Driver': 'delivery_driver_id',
      'Customer': 'customer_id',
      'Sales Rep': 'sales_rep_id',
      'Supplier': 'supplier_id',
    };
    final idKey = idKeys[widget.role];
    _idController = TextEditingController(text: data[idKey]?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _telephoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _canEditAllInfo() {
    return widget.role == 'Storage Manager' ||
        widget.role == 'Storage Staff' ||
        widget.role == 'Delivery Driver';
  }

  bool _canEditPasswordOnly() {
    return widget.role == 'Customer' ||
        widget.role == 'Sales Rep' ||
        widget.role == 'Supplier';
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final data = widget.item.rawData;

      if (_canEditAllInfo()) {
        // Update main entity table
        final tableNames = {
          'Storage Manager': 'storage_manager',
          'Storage Staff': 'storage_staff',
          'Delivery Driver': 'delivery_driver',
        };
        final idKeys = {
          'Storage Manager': 'storage_manager_id',
          'Storage Staff': 'storage_staff_id',
          'Delivery Driver': 'delivery_driver_id',
        };

        final tableName = tableNames[widget.role]!;
        final idKey = idKeys[widget.role]!;
        final id = data[idKey];

        await supabase
            .from(tableName)
            .update({
              'name': _nameController.text.trim(),
              'mobile_number': _mobileController.text.trim(),
              'telephone_number': _telephoneController.text.trim(),
              'address': _addressController.text.trim(),
              'last_action_by': 'current_user', // Replace with actual user
              'last_action_time': DateTime.now().toIso8601String(),
            })
            .eq(idKey, id);

        // Update password
        final accountTables = {
          'Storage Manager': 'user_account_storage_manager',
          'Storage Staff': 'user_account_storage_staff',
          'Delivery Driver': 'user_account_delivery_driver',
        };
        await supabase
            .from(accountTables[widget.role]!)
            .update({'password': _passwordController.text.trim()})
            .eq(idKey, id);
      } else if (_canEditPasswordOnly()) {
        // Only update password
        final accountTables = {
          'Customer': 'user_account_customer',
          'Sales Rep': 'user_account_sales_rep',
          'Supplier': 'user_account_supplier',
        };
        final idKeys = {
          'Customer': 'customer_id',
          'Sales Rep': 'sales_rep_id',
          'Supplier': 'supplier_id',
        };

        final accountTable = accountTables[widget.role]!;
        final idKey = idKeys[widget.role]!;
        final id = data[idKey];

        await supabase
            .from(accountTable)
            .update({'password': _passwordController.text.trim()})
            .eq(idKey, id);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload accounts
        (context.findAncestorStateOfType<_MobileAccountsPageState>())
            ?._loadAccounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(0, 10),
              blurRadius: 24,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit ${widget.role}',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFF3D3D3D)),
                const SizedBox(height: 20),

                // ID (read-only)
                _FormLabel('ID'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF232427),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                  child: TextFormField(
                    controller: _idController,
                    enabled: false,
                    style: const TextStyle(color: Colors.white70),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Name (editable for all info roles)
                if (_canEditAllInfo()) ...[
                  _FormLabel('Name'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF232427),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: MobileAccountsPage.borderGold,
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Mobile Number (editable for all info roles)
                if (_canEditAllInfo()) ...[
                  _FormLabel('Mobile Number'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF232427),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: MobileAccountsPage.borderGold,
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      controller: _mobileController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length != 10) return 'Must be 10 digits';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Telephone Number (editable for all info roles)
                if (_canEditAllInfo()) ...[
                  _FormLabel('Telephone Number'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF232427),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: MobileAccountsPage.borderGold,
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      controller: _telephoneController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Address (editable for all info roles)
                if (_canEditAllInfo()) ...[
                  _FormLabel('Address'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF232427),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: MobileAccountsPage.borderGold,
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      controller: _addressController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Password (editable for all)
                _FormLabel('Password'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF232427),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: MobileAccountsPage.borderGold,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9D949),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: GoogleFonts.roboto(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// الكرت في القائمة الرئيسية
class _AccountCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback onTap;

  const _AccountCard({required this.name, this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 3),
              blurRadius: 6,
            ),
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
      ),
    );
  }
}

class _AccountItem {
  final String name;
  final String? imageUrl;
  final Map<String, dynamic> rawData;
  _AccountItem({required this.name, this.imageUrl, required this.rawData});
}

/* ----------------------- ACCOUNT DETAILS POPUP ----------------------- */

class _AccountDetailsPopup extends StatelessWidget {
  final _AccountItem item;
  final String role;
  final VoidCallback onEdit;

  const _AccountDetailsPopup({
    required this.item,
    required this.role,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final data = item.rawData;

    // Extract account data from the appropriate joined table
    Map<String, dynamic>? accountData;
    String? accountIdKey;

    final accountKeys = {
      'Storage Manager': 'user_account_storage_manager',
      'Storage Staff': 'user_account_storage_staff',
      'Delivery Driver': 'user_account_delivery_driver',
      'Customer': 'user_account_customer',
      'Sales Rep': 'user_account_sales_rep',
      'Supplier': 'user_account_supplier',
    };

    final idKeys = {
      'Storage Manager': 'storage_manager_id',
      'Storage Staff': 'storage_staff_id',
      'Delivery Driver': 'delivery_driver_id',
      'Customer': 'customer_id',
      'Sales Rep': 'sales_rep_id',
      'Supplier': 'supplier_id',
    };

    final accountKey = accountKeys[role];
    accountIdKey = idKeys[role];

    if (accountKey != null && data[accountKey] is Map<String, dynamic>) {
      accountData = data[accountKey] as Map<String, dynamic>;
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(0, 10),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with edit and close buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Account Details',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFFF9D949)),
                      onPressed: onEdit,
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF3D3D3D)),
            const SizedBox(height: 20),

            // Profile Image
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade800,
                backgroundImage:
                    item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? NetworkImage(item.imageUrl!)
                    : null,
                child: (item.imageUrl == null || item.imageUrl!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            // Role Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9D949).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFF9D949),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  role,
                  style: GoogleFonts.roboto(
                    color: const Color(0xFFF9D949),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Information Fields
            _InfoRow(label: 'Name', value: data['name']?.toString() ?? 'N/A'),
            if (accountIdKey != null && data[accountIdKey] != null)
              _InfoRow(
                label: 'ID',
                value: data[accountIdKey]?.toString() ?? 'N/A',
              ),
            if (data['email'] != null && data['email'].toString().isNotEmpty)
              _InfoRow(
                label: 'Email',
                value: data['email']?.toString() ?? 'N/A',
              ),
            if (data['mobile_number'] != null)
              _InfoRow(
                label: 'Mobile Number',
                value: data['mobile_number']?.toString() ?? 'N/A',
              ),
            if (data['telephone_number'] != null)
              _InfoRow(
                label: 'Telephone Number',
                value: data['telephone_number']?.toString() ?? 'N/A',
              ),
            if (data['address'] != null &&
                data['address'].toString().isNotEmpty)
              _InfoRow(
                label: 'Address',
                value: data['address']?.toString() ?? 'N/A',
              ),

            // Account Information Section
            if (accountData != null) ...[
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF3D3D3D)),
              const SizedBox(height: 16),
              Text(
                'Account Information',
                style: GoogleFonts.roboto(
                  color: const Color(0xFFB7A447),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Status',
                value: accountData['is_active'] == 'yes'
                    ? 'Active'
                    : 'Inactive',
                valueColor: accountData['is_active'] == 'yes'
                    ? Colors.greenAccent
                    : Colors.redAccent,
              ),
              if (accountData['added_by'] != null)
                _InfoRow(
                  label: 'Added By',
                  value: accountData['added_by']?.toString() ?? 'N/A',
                ),
              if (accountData['added_time'] != null)
                _InfoRow(
                  label: 'Added Time',
                  value: _formatDateTime(accountData['added_time']?.toString()),
                ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: GoogleFonts.roboto(
                color: const Color(0xFFB7A447),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.roboto(
                color: valueColor ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
          color: const Color(0xFF2D2D2D),
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
