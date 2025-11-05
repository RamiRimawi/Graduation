import 'package:flutter/material.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  int selectedTop = 0;
  int? selectedBottom;

  final List<String> topIcons =
      List.generate(6, (i) => 'assets/icons/${i + 1}.png');
  final List<String> bottomIcons =
      List.generate(2, (i) => 'assets/icons/${i + 8}.png');

  static const double barWidth = 26;
  static const double itemGap = 32;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 158,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ---------------- اللوجو ----------------
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Image.asset(
              'assets/images/Logo.png',
              width: 158,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 10),

          // ---------------- الأيقونات العلوية ----------------
          SizedBox(
            width: barWidth,
            child: Column(
              children: [
                for (int i = 0; i < topIcons.length; i++) ...[
                  _HoverIcon(
                    path: topIcons[i],
                    isActive: selectedTop == i,
                    onTap: () => setState(() => selectedTop = i),
                  ),
                  if (i != topIcons.length - 1)
                    const SizedBox(height: itemGap),
                ]
              ],
            ),
          ),

          const Spacer(),

          // ---------------- الأيقونات السفلية ----------------
          SizedBox(
            width: barWidth,
            child: Column(
              children: [
                for (int i = 0; i < bottomIcons.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _HoverIcon(
                      path: bottomIcons[i],
                      isActive: selectedBottom == i,
                      onTap: () => setState(() => selectedBottom = i),
                    ),
                  ),
                  if (i != bottomIcons.length - 1)
                    const SizedBox(height: itemGap),
                ],
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ---------------- الصورة السفلية (صورتك) ----------------
          const _HoverProfileImage(),

          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

// 🎨 Widget للأيقونات مع Hover أنيق
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
              width: 26,
              height: 26,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// 🌟 الصورة السفلية (صورتك) مع Glow + Zoom عند المرور بالماوس
class _HoverProfileImage extends StatefulWidget {
  const _HoverProfileImage({super.key});

  @override
  State<_HoverProfileImage> createState() => _HoverProfileImageState();
}

class _HoverProfileImageState extends State<_HoverProfileImage> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: _isHovered ? 56 : 52,
        height: _isHovered ? 56 : 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: const DecorationImage(
            image: AssetImage('assets/images/rami.jpg'), // 🔹 حط صورتك هون
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF50B2E7)
                  .withOpacity(_isHovered ? 0.35 : 0.1),
              blurRadius: _isHovered ? 22 : 10,
              spreadRadius: _isHovered ? 3 : 1,
            ),
          ],
        ),
      ),
    );
  }
}
