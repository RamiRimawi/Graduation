import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// Sidebar
import 'sidebar.dart';

// Popups
import 'customer_popup.dart';
import 'sales_rep_popup.dart';
import 'supplier_popup.dart';
import 'one_field_popup.dart';

// Shared widgets
import 'shared_popup_widgets.dart';

class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key});

  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage>
    with TickerProviderStateMixin {
  // THEME
  static const bg = Color(0xFF202020);
  static const panel = Color(0xFF2D2D2D);
  static const gold = Color(0xFFB7A447);
  static const yellowBtn = Color(0xFFF9D949);

  late final TabController _primary;
  late TabController _usersTabs;
  late TabController _productTabs;

  // DATA ARRAYS
  final customers = <Map<String, dynamic>>[];
  final salesReps = <Map<String, dynamic>>[];
  final suppliers = <Map<String, dynamic>>[];
  final brands = <Map<String, dynamic>>[];
  final categories = <Map<String, dynamic>>[];

  // Cities
  final cities = const [
    'Ramallah',
    'Nablus',
    'Hebron',
    'Jerusalem',
    'Bethlehem',
  ];

  // ======================
  // LOAD FROM DATABASE
  // ======================

  Future<void> loadCustomers() async {
    final url = "http://localhost/graduation_backend/api/get_customers.php";
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    if (data["status"] == "success") {
      setState(() {
        customers.clear();
        customers.addAll(List<Map<String, dynamic>>.from(data["data"]));
      });
    }
  }

  Future<void> loadSalesReps() async {
    final url = "http://localhost/graduation_backend/api/get_sales_reps.php";
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    if (data["status"] == "success") {
      setState(() {
        salesReps.clear();
        salesReps.addAll(List<Map<String, dynamic>>.from(data["data"]));
      });
    }
  }

  Future<void> loadSuppliers() async {
    final url = "http://localhost/graduation_backend/api/get_suppliers.php";
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    if (data["status"] == "success") {
      setState(() {
        suppliers.clear();
        suppliers.addAll(List<Map<String, dynamic>>.from(data["data"]));
      });
    }
  }

  Future<void> loadBrands() async {
    final url = "http://localhost/graduation_backend/api/get_brands.php";
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    if (data["status"] == "success") {
      setState(() {
        brands.clear();
        brands.addAll(List<Map<String, dynamic>>.from(data["data"]));
      });
    }
  }

  Future<void> loadCategories() async {
    final url = "http://localhost/graduation_backend/api/get_categories.php";
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    if (data["status"] == "success") {
      setState(() {
        categories.clear();
        categories.addAll(List<Map<String, dynamic>>.from(data["data"]));
      });
    }
  }

  // ======================
  // INIT
  // ======================

  @override
  void initState() {
    super.initState();
    _primary = TabController(length: 2, vsync: this);
    _usersTabs = TabController(length: 3, vsync: this);
    _productTabs = TabController(length: 2, vsync: this);

    _primary.addListener(() => setState(() {}));

    // LOAD DATA
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
    super.dispose();
  }

  // BUTTON TEXT
  String get _addButtonText {
    if (_primary.index == 0) {
      return ['Add Customer', 'Add Sales Rep', 'Add Supplier'][_usersTabs.index];
    } else {
      return ['Add Brand', 'Add Category'][_productTabs.index];
    }
  }

  IconData get _addIcon {
    if (_primary.index == 0) {
      return [
        Icons.person_add_alt_1,
        Icons.edit_note_rounded,
        Icons.local_shipping_outlined,
      ][_usersTabs.index];
    } else {
      return Icons.north_east_rounded;
    }
  }

  // ======================
  // BUILD UI
  // ======================

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

                  // TABS HEADER
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
                                  onTap: (_) => setState(() {}),
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
                                  onTap: (_) => setState(() {}),
                                ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // ADD BUTTON
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: yellowBtn,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
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

                      const _SearchBox(hint: "Enter Name"),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // MAIN CONTENT OF TABS
                  Expanded(
                    child: TabBarView(
                      controller: _primary,
                      children: [
                        // USERS
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

                        // PRODUCT
                        TabBarView(
                          controller: _productTabs,
                          children: [
                            _buildSimpleList(
                                "Brand ID #", "Brand Name", brands),
                            _buildSimpleList("Category ID #", "Category Name",
                                categories),
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

  // ======================
  // POPUP HANDLER
  // ======================

  void _openAddPopup() {
    if (_primary.index == 0) {
      if (_usersTabs.index == 0) {
        showCustomerPopup(context, cities, (d) {
          setState(() => customers.add({
                "id": customers.length + 1,
                "name": d["name"],
                "location": d["city"],
              }));
        });
      } else if (_usersTabs.index == 1) {
        showSalesRepPopup(context, cities, (d) {
          setState(() => salesReps.add({
                "id": salesReps.length + 1,
                "name": d["name"],
                "location": d["city"],
              }));
        });
      } else {
        showSupplierPopup(context, cities, (d) {
          setState(() => suppliers.add({
                "id": suppliers.length + 1,
                "name": d["company"],
                "category": "—",
              }));
        });
      }
    } else {
      if (_productTabs.index == 0) {
        showOneFieldPopup(context, "Add Brand", "Brand Name", (name) {
          setState(() => brands.add({"id": brands.length + 1, "name": name}));
        });
      } else {
        showOneFieldPopup(context, "Add Category", "Category Name", (name) {
          setState(() =>
              categories.add({"id": categories.length + 1, "name": name}));
        });
      }
    }
  }

  // ======================
  // TABLE MAKERS
  // ======================

  Widget _buildTable(String t1, String t2, String t3,
      List<Map<String, dynamic>> data, String key) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(children: [
              Expanded(flex: 1, child: _h(t1)),
              Expanded(flex: 3, child: _h(t2)),
              Expanded(
                flex: 2,
                child:
                    Align(alignment: Alignment.centerRight, child: _h(t3)),
              ),
            ]),
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
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  )
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
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

  Widget _buildSimpleList(
      String t1, String t2, List<Map<String, dynamic>> list) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(children: [
              Expanded(flex: 1, child: _h(t1)),
              Expanded(flex: 5, child: _h(t2)),
            ]),
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
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  )
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
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

  Text _h(String txt) => Text(
        txt,
        style: GoogleFonts.roboto(
          color: Colors.grey[300],
          fontWeight: FontWeight.bold,
        ),
      );
}

// SEARCH BOX
class _SearchBox extends StatelessWidget {
  final String hint;
  const _SearchBox({required this.hint});

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
            const Icon(Icons.search_rounded,
                color: Colors.white60, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle:
                      const TextStyle(color: Colors.white54, fontSize: 14),
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
