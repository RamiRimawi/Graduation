import 'package:dolphin/Website/delivery_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'Website/sidebar.dart';
import 'Website/order_detail_popup.dart';
import 'Website/mobile_accounts_page.dart';
import 'Website/users_management_page.dart';
import 'Website/login_page.dart';
import 'Website/payment_page.dart';
import 'Website/report_page.dart';
import 'Website/inventory_page.dart';
import 'Website/stock_out_page.dart';

void main() {
  runApp(const DolphinApp());
}

class DolphinApp extends StatelessWidget {
  const DolphinApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF202020);
    const panel = Color(0xFF2D2D2D);
    const gold = Color(0xFFB7A447);
    const blue = Color(0xFF50B2E7);
    const white = Colors.white;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dolphin Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        textTheme: GoogleFonts.robotoTextTheme().apply(
          bodyColor: white,
          displayColor: white,
        ),
        colorScheme: ColorScheme.dark(
          surface: panel,
          primary: gold,
          secondary: blue,
        ),
      ),

      // 🔹 البداية من صفحة الـ Dashboard
      initialRoute: '/dashboard',

      // 🔹 الراوتس عشان الـ Sidebar يقدر يتنقل بينهم
      routes: {
        '/login': (_) => const LoginPage(),
        '/dashboard': (_) => const DashboardPage(),
        '/delivery': (_) => const DeliveryPage(),
        '/mobileAccounts': (_) => const MobileAccountsPage(),
        '/usersManagement': (_) => const UsersManagementPage(),
        '/payment': (_) => const PaymentPage(),
        '/report': (_) => const ReportPage(),
        '/inventory': (_) => const InventoryPage(),
        '/stockOut': (_) => const OrdersPage(),
      },
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 🔵 الزر الأول (الـ Home) هو الفعّال في هاي الصفحة
          const Sidebar(activeIndex: 0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  _TopStepsRow(),
                  SizedBox(height: 16),
                  Expanded(child: _MainContent()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                          TOP STEPS ROW (الكروت الأربعة)                   */
/* -------------------------------------------------------------------------- */
class _TopStepsRow extends StatelessWidget {
  const _TopStepsRow();

  static const double totalW = 820;
  static const double cardW = 170;
  static const double cardH = 150;
  static const double arrowW = 30;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: totalW,
      height: cardH,
      child: Row(
        children: const [
          _StepCard(title: 'Pending', icon: FontAwesomeIcons.clipboardList),
          _ArrowSpacer(width: arrowW),
          _StepCard(title: 'Preparing', icon: FontAwesomeIcons.boxOpen),
          _ArrowSpacer(width: arrowW),
          _StepCard(title: 'Delivering', icon: FontAwesomeIcons.truck),
          _ArrowSpacer(width: arrowW),
          _StepCard(title: 'Delivered', icon: FontAwesomeIcons.box),
        ],
      ),
    );
  }
}

class _ArrowSpacer extends StatelessWidget {
  final double width;
  const _ArrowSpacer({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _TopStepsRow.cardH,
      child: const Center(
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          color: Color(0xFF50B2E7),
          size: 20,
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String title;
  final IconData icon;
  const _StepCard({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _TopStepsRow.cardW,
      height: _TopStepsRow.cardH,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              offset: Offset(0, 6),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: Colors.amberAccent),
            const SizedBox(height: 6),
            const Text(
              '15',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Text('Order', style: TextStyle(color: Colors.grey)),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFB7A447),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                             MAIN CONTENT AREA                              */
/* -------------------------------------------------------------------------- */
class _MainContent extends StatelessWidget {
  const _MainContent();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SizedBox(width: 16),
        SizedBox(width: 289, height: 640, child: _ActiveWorkersCard()),
        SizedBox(width: 16),
        SizedBox(width: 894, height: 640, child: _OrdersCard()),
        Expanded(child: SizedBox()),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            ACTIVE WORKERS TABLE                            */
/* -------------------------------------------------------------------------- */
class _ActiveWorkersCard extends StatelessWidget {
  const _ActiveWorkersCard();

  @override
  Widget build(BuildContext context) {
    final workers = <(String, int, String)>[
      ('Ayman', 1, 'assets/images/ayman.jpg'),
      ('Ramadan', 2, 'assets/images/ramadan.jpg'),
      ('Rami', 1, 'assets/images/rami.jpg'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, 6),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Active',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              color: const Color(0xFFB7A447),
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'worker account',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              color: const Color(0xFFB7A447),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: workers.length,
              separatorBuilder: (_, __) => const Divider(
                color: Colors.white24,
                thickness: 1,
                height: 16,
              ),
              itemBuilder: (_, i) {
                final w = workers[i];
                return Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundImage: AssetImage(w.$3),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        w.$1,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '${w.$2}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               ORDERS TABLE                                 */
/* -------------------------------------------------------------------------- */
class _OrdersCard extends StatelessWidget {
  const _OrdersCard();

  static const double _leadIconSpace = 30;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['Saed Rimawi', 'out (NEW)', 'Sender', '12:30 AM', '14/8'],
      ['Ahmad Nizar', 'out (UPDATE)', 'Sender', '10:43 AM', '14/8'],
      ['Akef Al Asmar', 'out (NEW)', 'Sender', '9:30 AM', '14/8'],
      ['Nizar Fares', 'in (NEW)', 'Ayman Rimawi', '8:43 AM', '14/8'],
      ['Eyass Barghouthi', 'out (UPDATE)', 'Sender', '2:30 PM', '13/8'],
      ['Sami Jaber', 'out (UPDATE)', 'Ayman Rimawi', '8:43 AM', '13/8'],
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, 6),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Receives Order',
            style: GoogleFonts.roboto(
              color: const Color(0xFFB7A447),
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 14),
          _tableHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _orderRow(context, rows[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    final hStyle = GoogleFonts.roboto(
      color: Colors.grey.shade300,
      fontWeight: FontWeight.w600,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            children: [
              const SizedBox(width: _leadIconSpace),
              Expanded(flex: 3, child: Text('Sender', style: hStyle)),
              Expanded(flex: 2, child: Text('Type', style: hStyle)),
              Expanded(flex: 2, child: Text('Created by', style: hStyle)),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Time', style: hStyle),
                ),
              ),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Date', style: hStyle),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white24, thickness: 1, height: 0),
      ],
    );
  }

  Widget _orderRow(BuildContext context, List<String> r) {
    final typeColor = r[1].startsWith('in') ? Colors.greenAccent : Colors.white;

    return InkWell(
      onTap: () {
        OrderDetailPopup.show(
          context,
          orderType: r[1].startsWith('in') ? 'in' : 'out',
          status: r[1].contains('UPDATE') ? 'UPDATE' : 'NEW',
          products: [
            {
              "id": 1,
              "name": "Hand Shower",
              "brand": "GROHE",
              "price": "26\$",
              "quantity": 26,
              "total": "26\$",
            },
            {
              "id": 2,
              "name": "Wall-Hung Toilet",
              "brand": "Royal",
              "price": "150\$",
              "quantity": 30,
              "total": "150\$",
            },
            {
              "id": 3,
              "name": "Kitchen Sink",
              "brand": "GROHE",
              "price": "200\$",
              "quantity": 30,
              "total": "200\$",
            },
          ],
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Row(
          children: [
            const Icon(Icons.person, color: Colors.white54, size: 22),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                r[0],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                r[1],
                style: TextStyle(fontWeight: FontWeight.bold, color: typeColor),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                r[2],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  r[3],
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  r[4],
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
