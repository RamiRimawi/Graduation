import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../supabase_config.dart';     // ← مهم جداً

import 'sidebar.dart';
import 'customer_popup.dart';
import 'sales_rep_popup.dart';
import 'supplier_popup.dart';
import 'one_field_popup.dart';
import 'shared_popup_widgets.dart';

class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key});

  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage>
    with TickerProviderStateMixin {
  static const bg = Color(0xFF202020);
  static const panel = Color(0xFF2D2D2D);
  static const gold = Color(0xFFB7A447);
  static const yellowBtn = Color(0xFFF9D949);

  late TabController _primary;
  late TabController _usersTabs;
  late TabController _productTabs;

  final customers = <Map<String, dynamic>>[];
  final salesReps = <Map<String, dynamic>>[];
  final suppliers = <Map<String, dynamic>>[];
  final brands = <Map<String, dynamic>>[];
  final categories = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _primary = TabController(length: 2, vsync: this);
    _usersTabs = TabController(length: 3, vsync: this);
    _productTabs = TabController(length: 2, vsync: this);

    loadCustomers();
    loadSalesReps();
    loadSuppliers();
    loadBrands();
    loadCategories();
  }

  // =========================================
  // 🔥 LOAD DATA FROM SUPABASE
  // =========================================

  Future<void> loadCustomers() async {
    final res = await supabase
        .from('customer')
        .select('customer_id, name, customer_city(name)')
        .order('customer_id');

    setState(() {
      customers
        ..clear()
        ..addAll(res.map((e) => {
              "id": e['customer_id'],
              "name": e['name'],
              "location": e['customer_city']?['name'] ?? '—',
            }));
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
        ..addAll(res.map((e) => {
              "id": e['sales_rep_id'],
              "name": e['name'],
              "location": e['sales_rep_city']?['name'] ?? '—',
            }));
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
        ..addAll(res.map((e) => {
              "id": e['supplier_id'],
              "name": e['name'],
              "category": e['supplier_category']?['name'] ?? '—',
            }));
    });
  }

  Future<void> loadBrands() async {
    final res = await supabase.from('brand').select().order('brand_id');

    setState(() {
      brands
        ..clear()
        ..addAll(res.map((e) => {
              "id": e['brand_id'],
              "name": e['name'],
            }));
    });
  }

  Future<void> loadCategories() async {
    final res =
        await supabase.from('product_category').select().order('product_category_id');

    setState(() {
      categories
        ..clear()
        ..addAll(res.map((e) => {
              "id": e['product_category_id'],
              "name": e['name'],
            }));
    });
  }

  // =========================================
  // BUILD UI
  // =========================================

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
                  Text(
                    'Management',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // HEADERS
                  Row(
                    children: [
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

                      const SizedBox(width: 20),

                      Expanded(
                        child: _primary.index == 0
                            ? _buildUsersTabs()
                            : _buildProductTabs(),
                      ),

                      const SizedBox(width: 16),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: TabBarView(
                      controller: _primary,
                      children: [
                        TabBarView(
                          controller: _usersTabs,
                          children: [
                            _buildTable("Customer ID #", "Customer Name",
                                "Location", customers, "location"),
                            _buildTable("Sales Rep ID #", "Sales Rep Name",
                                "Location", salesReps, "location"),
                            _buildTable("Supplier ID #", "Supplier Name",
                                "Category", suppliers, "category"),
                          ],
                        ),
                        TabBarView(
                          controller: _productTabs,
                          children: [
                            _simpleList("Brand ID #", "Brand Name", brands),
                            _simpleList(
                                "Category ID #", "Category Name", categories),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tabs
  Widget _buildUsersTabs() {
    return TabBar(
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
    );
  }

  Widget _buildProductTabs() {
    return TabBar(
      controller: _productTabs,
      isScrollable: true,
      labelPadding: const EdgeInsets.only(right: 40),
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey.shade500,
      indicatorColor: gold,
      indicatorWeight: 2.5,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(text: 'Brands'),
        Tab(text: 'Category'),
      ],
    );
  }

  // GENERAL TABLE WIDGET
  Widget _buildTable(String t1, String t2, String t3,
      List<Map<String, dynamic>> data, String key) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(flex: 1, child: _header(t1)),
              Expanded(flex: 3, child: _header(t2)),
              Expanded(flex: 2, child: _header(t3)),
            ],
          ),
          const Divider(color: Colors.white24),

          for (final row in data)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      "${row['id']}",
                      style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold),
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

  // SIMPLE LIST
  Widget _simpleList(
      String t1, String t2, List<Map<String, dynamic>> list) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(flex: 1, child: _header(t1)),
              Expanded(flex: 5, child: _header(t2)),
            ],
          ),
          const Divider(color: Colors.white24),

          for (final it in list)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      "${it['id']}",
                      style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold),
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

  Text _header(String txt) => Text(
        txt,
        style: GoogleFonts.roboto(
          color: Colors.grey[300],
          fontWeight: FontWeight.bold,
        ),
      );
}
