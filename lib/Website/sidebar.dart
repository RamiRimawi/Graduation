import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../supabase_config.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key, required this.activeIndex});

  final int activeIndex;

  static const double barWidth = 26;
  static const double itemGap = 32;

  List<String> get topIcons =>
      List.generate(6, (i) => 'assets/icons/${i + 1}.png');

  List<String> get bottomIcons =>
      List.generate(3, (i) => 'assets/icons/${i + 7}.png');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // اللوجو
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 8,
                  ),
                  child: Image.asset(
                    'assets/images/Logo.png',
                    width: 134,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 10),

                // الأيقونات العلوية
                SizedBox(
                  width: barWidth,
                  child: Column(
                    children: [
                      for (int i = 0; i < topIcons.length; i++) ...[
                        _HoverIcon(
                          path: topIcons[i],
                          isActive: activeIndex == i,
                          onTap: () => _onItemTap(context, i),
                        ),
                        if (i != topIcons.length - 1)
                          const SizedBox(height: itemGap),
                      ],
                    ],
                  ),
                ),

                const Spacer(),

                // الأيقونات السفلية
                SizedBox(
                  width: barWidth,
                  child: Column(
                    children: [
                      for (int i = 0; i < bottomIcons.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _HoverIcon(
                            path: bottomIcons[i],
                            isActive: activeIndex == 6 + i,
                            onTap: () => _onItemTap(context, 6 + i),
                          ),
                        ),
                        if (i != bottomIcons.length - 1)
                          const SizedBox(height: itemGap),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // الصورة السفلية (Account)
                const _HoverProfileImage(),

                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // التنقل بين الصفحات
  void _onItemTap(BuildContext context, int index) {
    if (index == activeIndex && index != 5) return; // نفس الصفحة

    // Handle report icon with popup menu
    if (index == 5) {
      _showReportMenu(context);
      return;
    }

    String? routeName;

    switch (index) {
      case 0:
        routeName = '/dashboard';
        break;
      case 1:
        routeName = '/stockOut';
        break;
      case 2:
        routeName = '/inventory';
        break;
      case 3:
        routeName = '/delivery';
        break;
      case 4:
        routeName = '/payment';
        break;
      case 6:
        routeName = '/damagedProducts';
        break;
      case 7:
        routeName = '/mobileAccounts';
        break;
      case 8:
        routeName = '/usersManagement';
        break;
      case 9:
        routeName = '/account';
        break;
      // باقي الأزرار ما عليهم صفحات لسه
      default:
        return;
    }

    // Use pushReplacementNamed with a callback to ensure smooth navigation
    Navigator.pushReplacementNamed(context, routeName).catchError((error) {
      // Silently handle navigation errors
      return null;
    });
  }

  // Show report menu popup
  void _showReportMenu(BuildContext context) {
    // Get current route before showing dialog
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    // Calculate position for report icon (index 5)
    // Logo area: ~194px (16 top padding + 10 spacing + 158 logo + 10 gap)
    // Each icon with gap: 29px icon + 32px gap = 61px
    // Icon at index 5: 194 + (5 * 61) = 499px
    // Adjust by -50px to align better with the icon
    const double logoArea = 194.0;
    const double iconHeight = 29.0;
    const double iconGap = 32.0;
    const int reportIconIndex = 5;
    const double verticalAdjustment = 90.0;

    final topPosition =
        logoArea +
        (reportIconIndex * (iconHeight + iconGap)) -
        verticalAdjustment;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              left: 160,
              top: topPosition,
              child: _ReportMenuPopup(currentRoute: currentRoute),
            ),
          ],
        );
      },
    );
  }
}

// 🎨 أيقونة مع Hover + لون أزرق للـ active
class _HoverIcon extends StatefulWidget {
  final String path;
  final bool isActive;
  final VoidCallback onTap;

  const _HoverIcon({
    required this.path,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_HoverIcon> createState() => _HoverIconState();
}

class _HoverIconState extends State<_HoverIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF50B2E7);
    const hoverColor = Color(0xFFB7A447);
    const defaultColor = Colors.white;

    final color = widget.isActive
        ? activeColor
        : _isHovered
        ? hoverColor
        : defaultColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            child: Image.asset(
              widget.path,
              width: 29,
              height: 29,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// 🌟 الصورة السفلية (صورتك) مع Glow + Zoom عند الـ Hover
class _HoverProfileImage extends StatefulWidget {
  const _HoverProfileImage();

  @override
  State<_HoverProfileImage> createState() => _HoverProfileImageState();
}

// 🎨 Report Menu Popup
class _ReportMenuPopup extends StatelessWidget {
  final String currentRoute;

  const _ReportMenuPopup({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ReportMenuItem(
              icon: Icons.inventory_2_outlined,
              label: 'Product',
              route: '/report',
              isActive: currentRoute == '/report',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/report').catchError((
                  error,
                ) {
                  return null;
                });
              },
            ),
            _buildDivider(),
            _ReportMenuItem(
              icon: Icons.people_outline,
              label: 'Customer',
              route: '/reportCustomer',
              isActive: currentRoute == '/reportCustomer',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(
                  context,
                  '/reportCustomer',
                ).catchError((error) {
                  return null;
                });
              },
            ),
            _buildDivider(),
            _ReportMenuItem(
              icon: Icons.local_shipping_outlined,
              label: 'Supplier',
              route: '/reportSupplier',
              isActive: currentRoute == '/reportSupplier',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(
                  context,
                  '/reportSupplier',
                ).catchError((error) {
                  return null;
                });
              },
            ),
            _buildDivider(),
            _ReportMenuItem(
              icon: Icons.delete_outline,
              label: 'Destroyed Product',
              route: '/reportDestroyedProduct',
              isActive: currentRoute == '/reportDestroyedProduct',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(
                  context,
                  '/reportDestroyedProduct',
                ).catchError((error) {
                  return null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withOpacity(0.1),
    );
  }
}

// 🎨 Report Menu Item
class _ReportMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? route;
  final bool isActive;
  final bool comingSoon;
  final VoidCallback? onTap;

  const _ReportMenuItem({
    required this.icon,
    required this.label,
    this.route,
    this.isActive = false,
    this.comingSoon = false,
    this.onTap,
  });

  @override
  State<_ReportMenuItem> createState() => _ReportMenuItemState();
}

class _ReportMenuItemState extends State<_ReportMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF50B2E7);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.comingSoon ? null : widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: widget.isActive
              ? activeColor.withOpacity(0.15)
              : _isHovered && !widget.comingSoon
              ? activeColor.withOpacity(0.1)
              : Colors.transparent,
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: widget.comingSoon
                    ? Colors.white.withOpacity(0.3)
                    : widget.isActive
                    ? activeColor
                    : _isHovered
                    ? activeColor
                    : Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.comingSoon
                        ? Colors.white.withOpacity(0.3)
                        : widget.isActive
                        ? activeColor
                        : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.comingSoon)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Soon',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverProfileImageState extends State<_HoverProfileImage> {
  bool _isHovered = false;
  String? _profileImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if image is already cached
      final cachedImage = prefs.getString('profile_image');
      if (cachedImage != null && cachedImage.isNotEmpty) {
        if (mounted) {
          setState(() {
            _profileImage = cachedImage;
            _isLoading = false;
          });
        }
        return;
      }

      // If not cached, fetch from database
      final accountantId = prefs.getInt('accountant_id');
      if (accountantId != null) {
        final response = await supabase
            .from('accounts')
            .select('profile_image')
            .eq('user_id', accountantId)
            .single();

        final imageUrl = response['profile_image'] as String?;

        // Cache the image URL
        if (imageUrl != null && imageUrl.isNotEmpty) {
          await prefs.setString('profile_image', imageUrl);
        }

        if (mounted) {
          setState(() {
            _profileImage = imageUrl;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacementNamed(context, '/account').catchError((
            error,
          ) {
            return null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: _isHovered ? 67 : 52,
          height: _isHovered ? 67 : 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2D2D2D),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF50B2E7,
                ).withOpacity(_isHovered ? 0.35 : 0.1),
                blurRadius: _isHovered ? 22 : 10,
                spreadRadius: _isHovered ? 3 : 1,
              ),
            ],
          ),
          child: ClipOval(
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF50B2E7),
                      ),
                    ),
                  )
                : _profileImage != null && _profileImage!.isNotEmpty
                ? Image.network(
                    _profileImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, color: Colors.white, size: 28),
                  )
                : const Icon(Icons.person, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
