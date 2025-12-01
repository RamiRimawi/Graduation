import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'sidebar.dart';
// import 'customer_popup.dart';
// import 'sales_rep_popup.dart';
// import 'supplier_popup.dart';
// import 'one_field_popup.dart';

// 🔥 مهم
import '../supabase_config.dart';

class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key});

  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage>
    with TickerProviderStateMixin {
  // Theme
  static const bg = Color(0xFF202020);
  static const panel = Color(0xFF2D2D2D);
  static const gold = Color(0xFFB7A447);
  static const yellowBtn = Color(0xFFF9D949);

  late final TabController _primary; // Users | Product
  late TabController _usersTabs; // Customer | Sales Rep | Supplier
  late TabController _productTabs; // Brands | Category

  // =============== DATA LISTS ===============
  final customers = <Map<String, dynamic>>[];
  final salesReps = <Map<String, dynamic>>[];
  final suppliers = <Map<String, dynamic>>[];
  final brands = <Map<String, dynamic>>[];
  final categories = <Map<String, dynamic>>[];

  // =============== FILTERED DATA LISTS ===============
  List<Map<String, dynamic>> filteredCustomers = [];
  List<Map<String, dynamic>> filteredSalesReps = [];
  List<Map<String, dynamic>> filteredSuppliers = [];
  List<Map<String, dynamic>> filteredBrands = [];
  List<Map<String, dynamic>> filteredCategories = [];

  // =============== SEARCH CONTROLLER ===============
  final TextEditingController searchController = TextEditingController();

  // =============== LOAD DATA FROM SUPABASE ===============

  Future<void> loadCustomers() async {
    final res = await supabase
        .from('customer')
        .select('customer_id, name, customer_city(name)')
        .order('customer_id');

    setState(() {
      customers
        ..clear()
        ..addAll(
          res.map(
            (row) => {
              'id': row['customer_id'],
              'name': row['name'],
              'location': row['customer_city']?['name'] ?? '—',
            },
          ),
        );
      filteredCustomers = List.from(customers);
    });
  }

  Future<void> loadSalesReps() async {
    final res = await supabase
        .from('sales_representative')
        .select('sales_rep_id, name, sales_rep_city(name)')
        .order('sales_rep_id');

    setState(() {
      salesReps
        ..clear()
        ..addAll(
          res.map(
            (row) => {
              'id': row['sales_rep_id'],
              'name': row['name'],
              'location': row['sales_rep_city']?['name'] ?? '—',
            },
          ),
        );
      filteredSalesReps = List.from(salesReps);
    });
  }

  Future<void> loadSuppliers() async {
    final res = await supabase
        .from('supplier')
        .select('supplier_id, name, supplier_category(name)')
        .order('supplier_id');

    setState(() {
      suppliers
        ..clear()
        ..addAll(
          res.map(
            (row) => {
              'id': row['supplier_id'],
              'name': row['name'],
              'category': row['supplier_category']?['name'] ?? '—',
            },
          ),
        );
      filteredSuppliers = List.from(suppliers);
    });
  }

  Future<void> loadBrands() async {
    final res = await supabase.from('brand').select().order('brand_id');

    setState(() {
      brands
        ..clear()
        ..addAll(
          res.map((row) => {'id': row['brand_id'], 'name': row['name']}),
        );
      filteredBrands = List.from(brands);
    });
  }

  Future<void> loadCategories() async {
    final res = await supabase
        .from('product_category')
        .select()
        .order('product_category_id');

    setState(() {
      categories
        ..clear()
        ..addAll(
          res.map(
            (row) => {'id': row['product_category_id'], 'name': row['name']},
          ),
        );
      filteredCategories = List.from(categories);
    });
  }

  // =============== SEARCH FILTER ===============
  void _filterData(String query) {
    setState(() {
      if (query.isEmpty) {
        // Show all data when search is empty
        filteredCustomers = List.from(customers);
        filteredSalesReps = List.from(salesReps);
        filteredSuppliers = List.from(suppliers);
        filteredBrands = List.from(brands);
        filteredCategories = List.from(categories);
      } else {
        // Filter based on name starting with the query (case-insensitive)
        final lowerQuery = query.toLowerCase();
        filteredCustomers = customers
            .where(
              (item) =>
                  item['name'].toString().toLowerCase().startsWith(lowerQuery),
            )
            .toList();
        filteredSalesReps = salesReps
            .where(
              (item) =>
                  item['name'].toString().toLowerCase().startsWith(lowerQuery),
            )
            .toList();
        filteredSuppliers = suppliers
            .where(
              (item) =>
                  item['name'].toString().toLowerCase().startsWith(lowerQuery),
            )
            .toList();
        filteredBrands = brands
            .where(
              (item) =>
                  item['name'].toString().toLowerCase().startsWith(lowerQuery),
            )
            .toList();
        filteredCategories = categories
            .where(
              (item) =>
                  item['name'].toString().toLowerCase().startsWith(lowerQuery),
            )
            .toList();
      }
    });
  }

  // =============== INIT ===============
  @override
  void initState() {
    super.initState();

    _primary = TabController(length: 2, vsync: this);
    _usersTabs = TabController(length: 3, vsync: this);
    _productTabs = TabController(length: 2, vsync: this);
    _primary.addListener(() => setState(() {}));
    // Rebuild when inner tab selection changes so button text/icon updates
    _usersTabs.addListener(() => setState(() {}));
    _productTabs.addListener(() => setState(() {}));

    // 🔥 Load data
    loadCustomers();
    loadSalesReps();
    loadSuppliers();
    loadBrands();
    loadCategories();
  }

  @override
  void dispose() {
    _primary.dispose();
    _usersTabs.dispose();
    _productTabs.dispose();
    searchController.dispose();
    super.dispose();
  }

  // ============================
  // BUTTON TEXT / ICON
  // ============================

  String get _addButtonText {
    if (_primary.index == 0) {
      return [
        'add customer',
        'add sales rep',
        'add supplier',
      ][_usersTabs.index];
    }
    return ['add brand', 'add category'][_productTabs.index];
  }

  IconData get _addIcon {
    return Icons.add;
  }

  // ============================
  // BUILD UI (نفس القديم 100%)
  // ============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Row(
        children: [
          const Sidebar(activeIndex: 7),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Management',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // TABS ROW (نفس شكل القديم)
                  Row(
                    children: [
                      // Primary Tabs
                      TabBar(
                        controller: _primary,
                        isScrollable: true,
                        labelPadding: const EdgeInsets.only(right: 30),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey.shade500,
                        indicatorColor: gold,
                        indicatorWeight: 2.5,
                        indicatorSize: TabBarIndicatorSize.label,
                        dividerColor: Colors.transparent,
                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                        labelStyle: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        tabs: const [
                          Tab(text: 'Users'),
                          Tab(text: 'Product'),
                        ],
                      ),

                      Container(
                        width: 1,
                        height: 22,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.white24,
                      ),

                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _primary.index == 0
                              ? TabBar(
                                  key: const ValueKey('usersTabs'),
                                  controller: _usersTabs,
                                  isScrollable: true,
                                  labelPadding: const EdgeInsets.only(
                                    right: 40,
                                  ),
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.grey.shade500,
                                  indicatorColor: gold,
                                  indicatorWeight: 2.5,
                                  indicatorSize: TabBarIndicatorSize.label,
                                  dividerColor: Colors.transparent,
                                  overlayColor: WidgetStateProperty.all(
                                    Colors.transparent,
                                  ),
                                  labelStyle: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  tabs: const [
                                    Tab(text: 'Customer'),
                                    Tab(text: 'Sales Rep'),
                                    Tab(text: 'Supplier'),
                                  ],
                                )
                              : TabBar(
                                  key: const ValueKey('productTabs'),
                                  controller: _productTabs,
                                  isScrollable: true,
                                  labelPadding: const EdgeInsets.only(
                                    right: 40,
                                  ),
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.grey.shade500,
                                  indicatorColor: gold,
                                  indicatorWeight: 2.5,
                                  indicatorSize: TabBarIndicatorSize.label,
                                  dividerColor: Colors.transparent,
                                  overlayColor: WidgetStateProperty.all(
                                    Colors.transparent,
                                  ),
                                  labelStyle: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  tabs: const [
                                    Tab(text: 'Brands'),
                                    Tab(text: 'Category'),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: yellowBtn,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: _openAddPopup,
                        icon: Icon(_addIcon, color: Colors.black),
                        label: Text(
                          _addButtonText,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),
                      _SearchBox(
                        hint: "Enter Name",
                        controller: searchController,
                        onChanged: _filterData,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // MAIN CONTENT (نفس القديم تمامًا)
                  Expanded(
                    child: TabBarView(
                      controller: _primary,
                      children: [
                        // USERS
                        TabBarView(
                          controller: _usersTabs,
                          children: [
                            _buildTable(
                              "Customer ID #",
                              "Customer Name",
                              "Location",
                              filteredCustomers,
                              "location",
                            ),
                            _buildTable(
                              "Sales Rep ID #",
                              "Sales Rep Name",
                              "Location",
                              filteredSalesReps,
                              "location",
                            ),
                            _buildTable(
                              "Supplier ID #",
                              "Supplier Name",
                              "Category",
                              filteredSuppliers,
                              "category",
                            ),
                          ],
                        ),

                        // PRODUCT
                        TabBarView(
                          controller: _productTabs,
                          children: [
                            _simpleList(
                              "Brand ID #",
                              "Brand Name",
                              filteredBrands,
                            ),
                            _simpleList(
                              "Category ID #",
                              "Category Name",
                              filteredCategories,
                            ),
                          ],
                        ),
                      ],
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

  // ============================
  // POPUP HANDLER
  // ============================

  void _openAddPopup() {
    // if (_primary.index == 0) {
    //   if (_usersTabs.index == 0) {
    //     showCustomerPopup(context);
    //   } else if (_usersTabs.index == 1) {
    //     showSalesRepPopup(context);
    //   } else {
    //     showSupplierPopup(context);
    //   }
    // } else {
    //   if (_productTabs.index == 0) {
    //     showOneFieldPopup(context, "Add Brand", "Brand Name");
    //   } else {
    //     showOneFieldPopup(context, "Add Category", "Category Name");
    //   }
    // }
  }

  // ============================
  // TABLE BUILDERS
  // ============================

  Widget _buildTable(
    String t1,
    String t2,
    String t3,
    List<Map<String, dynamic>> data,
    String key,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(flex: 1, child: _h(t1)),
                Expanded(flex: 3, child: _h(t2)),
                Expanded(
                  flex: 2,
                  child: Align(alignment: Alignment.centerRight, child: _h(t3)),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24),

          for (final row in data)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      "${row['id']}",
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      "${row['name']}",
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${row[key]}",
                        style: const TextStyle(
                          color: gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _simpleList(String t1, String t2, List<Map<String, dynamic>> list) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(flex: 1, child: _h(t1)),
                Expanded(flex: 5, child: _h(t2)),
              ],
            ),
          ),
          const Divider(color: Colors.white24),

          for (final it in list)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      "${it['id']}",
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      "${it['name']}",
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Text _h(String txt) => Text(
    txt,
    style: GoogleFonts.roboto(
      color: Colors.grey[300],
      fontWeight: FontWeight.bold,
    ),
  );
}

// ========== Search Box ==========
class _SearchBox extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final Function(String) onChanged;

  const _SearchBox({
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _UsersManagementPageState.panel,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Colors.white60, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
