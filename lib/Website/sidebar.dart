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
      List.generate(2, (i) => 'assets/icons/${i + 8}.png');

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
      child: Column(
        children: [
          const SizedBox(height: 16),

          // اللوجو
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Image.asset(
              'assets/images/Logo.png',
              width: 158,
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
                  if (i != topIcons.length - 1) const SizedBox(height: itemGap),
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
    );
  }

  // التنقل بين الصفحات
  void _onItemTap(BuildContext context, int index) {
    if (index == activeIndex) return; // نفس الصفحة

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
      case 5:
        routeName = '/report';
        break;
      case 6:
        routeName = '/mobileAccounts';
        break;
      case 7:
        routeName = '/usersManagement';
        break;
      // باقي الأزرار ما عليهم صفحات لسه
      default:
        return;
    }

    Navigator.pushReplacementNamed(context, routeName);
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
            .from('user_account_accountant')
            .select('profile_image')
            .eq('accountant_id', accountantId)
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
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacementNamed(context, '/account');
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
                color: const Color(0xFF50B2E7).withOpacity(_isHovered ? 0.35 : 0.1),
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
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 28,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
          ),
        ),
      ),
    );
  }
}
