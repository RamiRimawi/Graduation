import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../widgets/sidebar.dart'; // ← نفس الشريط الجانبي

class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key});

  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> customers = [
    {'id': 1, 'name': 'Ahmad Nizar', 'location': 'Ramallah'},
    {'id': 2, 'name': 'Saed Rimawi', 'location': 'Nablus'},
    {'id': 3, 'name': 'Akef Al Asmar', 'location': 'Nablus'},
    {'id': 4, 'name': 'Nizar Fares', 'location': 'Ramallah'},
    {'id': 5, 'name': 'Sameer Haj', 'location': 'Hebron'},
    {'id': 6, 'name': 'Eyas Barghouthi', 'location': 'Ramallah'},
    {'id': 7, 'name': 'Sami Jaber', 'location': 'Hebron'},
  ];

  final List<Map<String, dynamic>> salesReps = [
    {'id': 1, 'name': 'Abdullah Odwan', 'location': 'Ramallah'},
    {'id': 2, 'name': 'Kareem Manasra', 'location': 'Nablus'},
    {'id': 3, 'name': 'Ayman Rimawi', 'location': 'Hebron'},
    {'id': 4, 'name': 'Rami Rimawi', 'location': 'Jerusalem'},
  ];

  final List<Map<String, dynamic>> suppliers = [
    {'id': 1, 'name': 'Ahmad Nizar', 'category': 'Toilets'},
    {'id': 2, 'name': 'Saed Rimawi', 'category': 'Extensions'},
    {'id': 3, 'name': 'Akef Al Asmar', 'category': 'Extensions'},
    {'id': 4, 'name': 'Nizar Fares', 'category': 'Toilets'},
    {'id': 5, 'name': 'Sameer Haj', 'category': 'Toilets'},
    {'id': 6, 'name': 'Eyas Barghouthi', 'category': 'Extensions'},
    {'id': 7, 'name': 'Sami Jaber', 'category': 'Shower'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- العنوان + الزر ----------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Users Management",
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF9D949),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible:
                                true, // السماح بالإغلاق عند الضغط خارج البوب أب
                            builder: (BuildContext context) {
                              return Stack(
                                children: [
                                  // الخلفية + الغباش + الإغلاق عند الضغط عليها
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        color: Colors.black.withOpacity(0.45),
                                      ),
                                    ),
                                  ),

                                  // محتوى الـ popup
                                  Center(
                                    child: Material(
                                      color: Colors
                                          .transparent, // خلي الظلال تشتغل تمام
                                      child: Container(
                                        width: 500,
                                        padding: const EdgeInsets.fromLTRB(
                                          25,
                                          28,
                                          25,
                                          30,
                                        ), // العنوان أعلى شوي
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2D2D2D),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black54,
                                              blurRadius: 15,
                                              offset: Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // العنوان (بدون underline)
                                            Text(
                                              "Choose User Role",
                                              style: GoogleFonts.roboto(
                                                color: const Color(0xFFB7A447),
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                                decoration:
                                                    TextDecoration.none, // مهم
                                              ),
                                            ),
                                            const SizedBox(height: 22),

                                            // الخيارات
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                _RoleOption(
                                                  icon: Icons.person,
                                                  label: "Customer",
                                                  onTap: () =>
                                                      Navigator.pop(context),
                                                ),
                                                Container(
                                                  width: 1,
                                                  height: 80,
                                                  color: Colors.white24,
                                                ),
                                                _RoleOption(
                                                  icon: Icons.edit_note_rounded,
                                                  label: "Sales Rep",
                                                  onTap: () =>
                                                      Navigator.pop(context),
                                                ),
                                                Container(
                                                  width: 1,
                                                  height: 80,
                                                  color: Colors.white24,
                                                ),
                                                _RoleOption(
                                                  icon: Icons
                                                      .local_shipping_outlined,
                                                  label: "Supplier",
                                                  onTap: () =>
                                                      Navigator.pop(context),
                                                ),
                                              ],
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
                        },
                        icon: const Icon(
                          Icons.person_add_alt_1,
                          color: Colors.black,
                        ),
                        label: const Text(
                          "Add User",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ---------------- Tabs ----------------
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 0.0,
                    ), // 🔹 يبدأ من نفس خط Users
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelPadding: const EdgeInsets.only(
                          right: 50,
                        ), // 🔹 مسافة أكبر بين التابات
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey.shade500,
                        indicatorColor: const Color(0xFFB7A447),
                        indicatorWeight: 2.5,
                        indicatorSize: TabBarIndicatorSize.label,
                        dividerColor: Colors.transparent, // 🔹 يشيل الخط
                        overlayColor: MaterialStateProperty.all(
                          Colors.transparent,
                        ), // 🔹 يشيل hover
                        labelStyle: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: "Customer"),
                          Tab(text: "Sales Rep"),
                          Tab(text: "Supplier"),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ---------------- البحث ----------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 230,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.person_search_rounded,
                              color: Colors.white60,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Enter Name",
                                  hintStyle: TextStyle(
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
                    ],
                  ),
                  const SizedBox(height: 25),

                  // ---------------- محتوى التبويبات ----------------
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCustomerTable(),
                        _buildSalesRepTable(),
                        _buildSupplierTable(),
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

  // ---------------- جداول الأقسام ----------------

  Widget _buildCustomerTable() {
    return _buildTable(
      title1: "Customer ID #",
      title2: "Customer Name",
      title3: "Location",
      data: customers,
      valueKey: "location",
    );
  }

  Widget _buildSalesRepTable() {
    return _buildTable(
      title1: "Sales Rep ID #",
      title2: "Sales Rep Name",
      title3: "Location",
      data: salesReps,
      valueKey: "location",
    );
  }

  Widget _buildSupplierTable() {
    return _buildTable(
      title1: "Supplier ID #",
      title2: "Supplier Name",
      title3: "Categories",
      data: suppliers,
      valueKey: "category",
    );
  }

  // ---------------- مكوّن الجدول العام ----------------

  Widget _buildTable({
    required String title1,
    required String title2,
    required String title3,
    required List<Map<String, dynamic>> data,
    required String valueKey,
  }) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // العناوين
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    title1,
                    style: GoogleFonts.roboto(
                      color: Colors.grey[300],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    title2,
                    style: GoogleFonts.roboto(
                      color: Colors.grey[300],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      title3,
                      style: GoogleFonts.roboto(
                        color: Colors.grey[300],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),

          // الصفوف
          for (var c in data)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
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
                      c['id'].toString(),
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      c['name'].toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        c[valueKey].toString(),
                        style: const TextStyle(
                          color: Color(0xFFB7A447),
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
}

// ------------------- كرت اختيار نوع المستخدم -------------------
class _RoleOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoleOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 50),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
