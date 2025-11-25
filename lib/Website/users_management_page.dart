import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sidebar.dart';

class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key});

  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage>
    with TickerProviderStateMixin {
  // Theme
  static const bg = Color(0xFF202020);
  static const panel = Color(0xFF2D2D2D); // رمادي غامق للحقول والصناديق
  static const field = Color(0xFF2B2B2B); // رمادي أخف للحقول نفسها
  static const gold = Color(0xFFB7A447);
  static const yellowBtn = Color(0xFFF9D949);

  late final TabController _primary; // Users | Product
  late TabController _usersTabs; // Customer | Sales Rep | Supplier
  late TabController _productTabs; // Brands | Category

  // Demo data
  final customers = <Map<String, dynamic>>[
    {'id': 1, 'name': 'Ahmad Nizar', 'location': 'Ramallah'},
    {'id': 2, 'name': 'Saed Rimawi', 'location': 'Nablus'},
    {'id': 3, 'name': 'Akef Al Asmar', 'location': 'Nablus'},
    {'id': 4, 'name': 'Nizar Fares', 'location': 'Ramallah'},
    {'id': 5, 'name': 'Sameer Haj', 'location': 'Hebron'},
    {'id': 6, 'name': 'Eyas Barghouthi', 'location': 'Ramallah'},
    {'id': 7, 'name': 'Sami Jaber', 'location': 'Hebron'},
  ];
  final salesReps = <Map<String, dynamic>>[
    {'id': 1, 'name': 'Abdullah Odwan', 'location': 'Ramallah'},
    {'id': 2, 'name': 'Kareem Manasra', 'location': 'Nablus'},
    {'id': 3, 'name': 'Ayman Rimawi', 'location': 'Hebron'},
    {'id': 4, 'name': 'Rami Rimawi', 'location': 'Jerusalem'},
  ];
  final suppliers = <Map<String, dynamic>>[
    {'id': 1, 'name': 'Ahmad Nizar', 'category': 'Toilets'},
    {'id': 2, 'name': 'Saed Rimawi', 'category': 'Extensions'},
    {'id': 3, 'name': 'Akef Al Asmar', 'category': 'Extensions'},
    {'id': 4, 'name': 'Nizar Fares', 'category': 'Toilets'},
    {'id': 5, 'name': 'Sameer Haj', 'category': 'Toilets'},
    {'id': 6, 'name': 'Eyas Barghouthi', 'category': 'Extensions'},
    {'id': 7, 'name': 'Sami Jaber', 'category': 'Shower'},
  ];
  final brands = <Map<String, dynamic>>[
    {'id': 1, 'name': 'GROHE'},
    {'id': 2, 'name': 'Royal'},
    {'id': 3, 'name': 'Delta'},
  ];
  final categories = <Map<String, dynamic>>[
    {'id': 1, 'name': 'Toilets'},
    {'id': 2, 'name': 'Shower'},
    {'id': 3, 'name': 'Extensions'},
  ];

  final cities = const [
    'Ramallah',
    'Nablus',
    'Hebron',
    'Jerusalem',
    'Bethlehem',
  ];

  @override
  void initState() {
    super.initState();
    _primary = TabController(length: 2, vsync: this);
    _usersTabs = TabController(length: 3, vsync: this);
    _productTabs = TabController(length: 2, vsync: this);
    _primary.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _primary.dispose();
    _usersTabs.dispose();
    _productTabs.dispose();
    super.dispose();
  }

  String get _addButtonText {
    if (_primary.index == 0) {
      return [
        'Add Customer',
        'Add Sales Rep',
        'Add Supplier',
      ][_usersTabs.index];
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

                  // Tabs row
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
                        height: 22,
                        width: 1,
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
                      const _SearchBox(hint: 'Enter Name'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Content
                  Expanded(
                    child: TabBarView(
                      controller: _primary,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // USERS
                        TabBarView(
                          controller: _usersTabs,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildTable(
                              'Customer ID #',
                              'Customer Name',
                              'Location',
                              customers,
                              'location',
                            ),
                            _buildTable(
                              'Sales Rep ID #',
                              'Sales Rep Name',
                              'Location',
                              salesReps,
                              'location',
                            ),
                            _buildTable(
                              'Supplier ID #',
                              'Supplier Name',
                              'Categories',
                              suppliers,
                              'category',
                            ),
                          ],
                        ),

                        // PRODUCT
                        TabBarView(
                          controller: _productTabs,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildSimpleList(
                              'Brand ID #',
                              'Brand Name',
                              brands,
                            ),
                            _buildSimpleList(
                              'Category ID #',
                              'Category Name',
                              categories,
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

  // ---------------- POPUPS ----------------

  void _openAddPopup() {
    // choose the form based on current tabs
    late Widget form;
    if (_primary.index == 0) {
      if (_usersTabs.index == 0) {
        form = _CustomerForm(cities: cities, onSubmit: _addCustomer);
      } else if (_usersTabs.index == 1) {
        form = _SalesRepForm(cities: cities, onSubmit: _addSalesRep);
      } else {
        form = _SupplierForm(cities: cities, onSubmit: _addSupplier);
      }
    } else {
      if (_productTabs.index == 0) {
        form = _OneFieldForm(
          title: 'Add Product Brand',
          label: 'Brand Name',
          onSubmit: _addBrand,
        );
      } else {
        form = _OneFieldForm(
          title: 'Add Product Category',
          label: 'Category Name',
          onSubmit: _addCategory,
        );
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent, // خليه شفاف عشان الغباش يبين
      builder: (ctx) {
        final w = MediaQuery.of(ctx).size.width;
        final h = MediaQuery.of(ctx).size.height;
        final horizontal = w < 1100 ? 24.0 : 60.0;
        final vertical = h < 800 ? 24.0 : 70.0;

        return Stack(
          children: [
            // ⬅️ الغباش + التعتيم + إغلاق عند الضغط خارج الصندوق
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(color: Colors.black.withOpacity(0.55)),
                ),
              ),
            ),

            // ⬅️ صندوق الـ popup
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontal,
                  vertical: vertical,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 26,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      borderRadius: BorderRadius.circular(22),
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
                          child: form,
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
            ),
          ],
        );
      },
    );
  }

  // Add handlers
  void _addCustomer(Map<String, dynamic> data) {
    setState(() {
      customers.add({
        'id': customers.length + 1,
        'name': data['name'],
        'location': data['city'],
      });
    });
    Navigator.pop(context);
  }

  void _addSalesRep(Map<String, dynamic> data) {
    setState(() {
      salesReps.add({
        'id': salesReps.length + 1,
        'name': data['name'],
        'location': data['city'],
      });
    });
    Navigator.pop(context);
  }

  void _addSupplier(Map<String, dynamic> data) {
    setState(() {
      suppliers.add({
        'id': suppliers.length + 1,
        'name': data['company'],
        'category': '—',
      });
    });
    Navigator.pop(context);
  }

  void _addBrand(String name) {
    setState(() => brands.add({'id': brands.length + 1, 'name': name}));
    Navigator.pop(context);
  }

  void _addCategory(String name) {
    setState(() => categories.add({'id': categories.length + 1, 'name': name}));
    Navigator.pop(context);
  }

  // ---------------- Tables ----------------

  Widget _buildTable(
    String t1,
    String t2,
    String t3,
    List<Map<String, dynamic>> data,
    String valueKey,
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
                    offset: Offset(0, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${row['id']}',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${row['name']}',
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${row[valueKey]}',
                        style: const TextStyle(
                          color: _UsersManagementPageState.gold,
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
    String t1,
    String t2,
    List<Map<String, dynamic>> items,
  ) {
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
          for (final it in items)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(12),
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
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${it['id']}',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      '${it['name']}',
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

  Text _h(String s) => Text(
    s,
    style: GoogleFonts.roboto(
      color: Colors.grey[300],
      fontWeight: FontWeight.bold,
    ),
  );
}

// ========== أدوات مساعدة عامة ==========

/// صف ثنائي الأعمدة يضمن أن الحقول تبقى بنفس العروض.
/// إذا مرّرت right=null سيحجز عمودًا فارغًا بنفس العرض.
class _TwoColRow extends StatelessWidget {
  final Widget left;
  final Widget? right;
  const _TwoColRow({required this.left, this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 26),
        Expanded(child: right ?? const SizedBox()),
      ],
    );
  }
}

// ========== POPUP FORMS ==========

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final TextInputType? type;
  final Widget? suffix;
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.type,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label كبير و Bold
        Text(
          label,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _UsersManagementPageState.field, // خلفية رمادية للحقول
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            keyboardType: type,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: suffix == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: suffix,
                      ),
                    ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CityDropdown extends StatelessWidget {
  final List<String> items;
  final String value;
  final ValueChanged<String> onChanged;
  const _CityDropdown({
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _UsersManagementPageState.field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _UsersManagementPageState.gold, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            Icons.expand_more_rounded,
            color: _UsersManagementPageState.gold,
          ),
          dropdownColor: _UsersManagementPageState.field,
          style: const TextStyle(color: Colors.white),
          items: items
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => v == null ? null : onChanged(v),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  const _SubmitButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight, // أسفل يمين الـ popup
      child: SizedBox(
        height: 64, // أكبر
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _UsersManagementPageState.yellowBtn,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 34),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              fontSize: 18,
            ),
          ),
          onPressed: onTap,
          icon: Icon(icon, size: 26),
          label: Text(text),
        ),
      ),
    );
  }
}

// ------- Customer Form -------
class _CustomerForm extends StatefulWidget {
  final List<String> cities;
  final void Function(Map<String, dynamic>) onSubmit;
  const _CustomerForm({required this.cities, required this.onSubmit});

  @override
  State<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<_CustomerForm> {
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    mobile.dispose();
    tel.dispose();
    address.dispose();
    debit.dispose();
    super.dispose();
  }

  final name = TextEditingController();
  final email = TextEditingController();
  final mobile = TextEditingController();
  final tel = TextEditingController();
  final address = TextEditingController();
  final debit = TextEditingController(text: '0');
  late String city;

  @override
  void initState() {
    super.initState();
    city = widget.cities.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Customer',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 22),

        _TwoColRow(
          left: _Field(
            controller: name,
            label: 'Customer Name',
            hint: 'Entre full Name',
          ),
          right: _Field(
            controller: email,
            label: 'Email',
            hint: 'Entre Email',
            type: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 18),

        _TwoColRow(
          left: _Field(
            controller: mobile,
            label: 'Mobile Number',
            hint: 'Entre Mobile Number',
            type: TextInputType.phone,
          ),
          right: _Field(
            controller: tel,
            label: 'Telephone Number',
            hint: 'Entre Telephone Number',
            type: TextInputType.phone,
          ),
        ),
        const SizedBox(height: 18),

        _TwoColRow(
          left: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'City',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              _CityDropdown(
                items: widget.cities,
                value: city,
                onChanged: (v) => setState(() => city = v),
              ),
            ],
          ),
          right: _Field(
            controller: address,
            label: 'Address',
            hint: 'Entre Address',
          ),
        ),
        const SizedBox(height: 18),

        // يبقى على عرض العمود اليسار فقط
        _TwoColRow(
          left: _Field(
            controller: debit,
            label: 'Debit balance',
            hint: '0',
            type: TextInputType.number,
            suffix: const Text(
              '\$',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          right: null,
        ),

        const SizedBox(height: 25),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SubmitButton(
              text: 'Submit',
              icon: Icons.person_add_alt_1,
              onTap: () {
                if (name.text.trim().isEmpty) return;
                widget.onSubmit({'name': name.text.trim(), 'city': city});
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ------- Sales Rep Form -------
class _SalesRepForm extends StatefulWidget {
  final List<String> cities;
  final void Function(Map<String, dynamic>) onSubmit;
  const _SalesRepForm({required this.cities, required this.onSubmit});

  @override
  State<_SalesRepForm> createState() => _SalesRepFormState();
}

class _SalesRepFormState extends State<_SalesRepForm> {
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    mobile.dispose();
    tel.dispose();
    super.dispose();
  }

  final name = TextEditingController();
  final email = TextEditingController();
  final mobile = TextEditingController();
  final tel = TextEditingController();
  late String city;

  @override
  void initState() {
    super.initState();
    city = widget.cities.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Sales Rep',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 22),

        _TwoColRow(
          left: _Field(
            controller: name,
            label: 'Full Name',
            hint: 'Entre Full Name',
          ),
          right: _Field(
            controller: email,
            label: 'Email',
            hint: 'Entre Email',
            type: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 18),

        _TwoColRow(
          left: _Field(
            controller: mobile,
            label: 'Mobile Number',
            hint: 'Entre Mobile Number',
            type: TextInputType.phone,
          ),
          right: _Field(
            controller: tel,
            label: 'Telephone Number',
            hint: 'Entre Telephone Number',
            type: TextInputType.phone,
          ),
        ),
        const SizedBox(height: 18),

        _TwoColRow(
          left: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'City',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              _CityDropdown(
                items: widget.cities,
                value: city,
                onChanged: (v) => setState(() => city = v),
              ),
            ],
          ),
          right: null, // يحافظ على العرض
        ),

        const SizedBox(height: 25),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SubmitButton(
              text: 'Submit',
              icon: Icons.person_add_alt_1,
              onTap: () {
                if (name.text.trim().isEmpty) return;
                widget.onSubmit({'name': name.text.trim(), 'city': city});
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ------- Supplier Form -------
class _SupplierForm extends StatefulWidget {
  final List<String> cities;
  final void Function(Map<String, dynamic>) onSubmit;
  const _SupplierForm({required this.cities, required this.onSubmit});

  @override
  State<_SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends State<_SupplierForm> {
  @override
  void dispose() {
    company.dispose();
    email.dispose();
    mobile.dispose();
    tel.dispose();
    address.dispose();
    creditor.dispose();
    super.dispose();
  }

  final company = TextEditingController();
  final email = TextEditingController();
  final mobile = TextEditingController();
  final tel = TextEditingController();
  final address = TextEditingController();
  final creditor = TextEditingController(text: '0');
  late String city;

  @override
  void initState() {
    super.initState();
    city = widget.cities.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Supplier',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 22),

        _TwoColRow(
          left: _Field(
            controller: company,
            label: 'Company Name',
            hint: 'Entre Company Name',
          ),
          right: _Field(
            controller: email,
            label: 'Email',
            hint: 'Entre Email',
            type: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 18),

        _TwoColRow(
          left: _Field(
            controller: mobile,
            label: 'Mobile Number',
            hint: 'Entre Mobile Number',
            type: TextInputType.phone,
          ),
          right: _Field(
            controller: tel,
            label: 'Telephone Number',
            hint: 'Entre Telephone Number',
            type: TextInputType.phone,
          ),
        ),
        const SizedBox(height: 18),

        _TwoColRow(
          left: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'City',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              _CityDropdown(
                items: widget.cities,
                value: city,
                onChanged: (v) => setState(() => city = v),
              ),
            ],
          ),
          right: _Field(
            controller: address,
            label: 'Address',
            hint: 'Entre Address',
          ),
        ),
        const SizedBox(height: 18),

        _TwoColRow(
          left: _Field(
            controller: creditor,
            label: 'Creditor balance',
            hint: '0',
            type: TextInputType.number,
            suffix: const Text(
              '\$',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          right: null,
        ),

        const SizedBox(height: 25),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SubmitButton(
              text: 'Submit',
              icon: Icons.person_add_alt_1,
              onTap: () {
                if (company.text.trim().isEmpty) return;
                widget.onSubmit({'company': company.text.trim(), 'city': city});
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ------- Single field (Brand / Category) -------
class _OneFieldForm extends StatefulWidget {
  final String title;
  final String label;
  final void Function(String) onSubmit;
  const _OneFieldForm({
    required this.title,
    required this.label,
    required this.onSubmit,
  });

  @override
  State<_OneFieldForm> createState() => _OneFieldFormState();
}

class _OneFieldFormState extends State<_OneFieldForm> {
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 560,
        maxWidth: 820, // عرض أصغر: الـ popup يلتف حول المحتوى
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            widget.label,
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: _UsersManagementPageState.field,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Entre ${widget.label}',
                hintStyle: const TextStyle(color: Colors.white54),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SubmitButton(
                text: 'Submit',
                icon: Icons.north_east_rounded,
                onTap: () {
                  final v = controller.text.trim();
                  if (v.isEmpty) return;
                  widget.onSubmit(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------ Helpers ------------

class SpacerIfPossible extends StatelessWidget {
  const SpacerIfPossible({super.key});
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return h > 650 ? const SizedBox(height: 10) : const SizedBox.shrink();
  }
}

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
            const Icon(Icons.search_rounded, color: Colors.white60, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
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
