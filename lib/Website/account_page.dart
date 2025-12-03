import 'package:flutter/material.dart';
import 'sidebar.dart';
import '../supabase_config.dart';

// 🎨 الألوان
class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const card = Color(0xFF2D2D2D);
  static const yellow = Color(0xFFFFE14D);
  static const red = Color(0xFFED4B49);
}

class ProfilePageContent extends StatefulWidget {
  const ProfilePageContent({super.key});

  @override
  State<ProfilePageContent> createState() => _ProfilePageContentState();
}

class _ProfilePageContentState extends State<ProfilePageContent> {
  bool isLoading = true;
  String name = '';
  String mobileNumber = '';
  String telephoneNumber = '';
  String address = '';
  String? profileImage;

  @override
  void initState() {
    super.initState();
    _loadAccountantData();
  }

  Future<void> _loadAccountantData() async {
    try {
      // For now, using accountant_id = 401234567 as example
      // You should replace this with actual logged-in user ID
      const accountantId = 401234567;
      
      final response = await supabase
          .from('user_account_accountant')
          .select('''
            accountant_id,
            profile_image,
            accountant:accountant_id(
              name,
              mobile_number,
              telephone_number,
              address
            )
          ''')
          .eq('accountant_id', accountantId)
          .single();

      if (mounted) {
        final accountantData = response['accountant'] as Map<String, dynamic>;
        setState(() {
          name = accountantData['name'] ?? 'N/A';
          mobileNumber = accountantData['mobile_number'] ?? 'N/A';
          telephoneNumber = accountantData['telephone_number'] ?? 'N/A';
          address = accountantData['address'] ?? 'N/A';
          profileImage = response['profile_image'] as String?;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading accountant data: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Row(
        children: [
          const Sidebar(activeIndex: 0),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.yellow,
                    ),
                  )
                : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width > 900 ? 60 : 28,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // أزرار أعلى الصفحة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _TopButton(
                          label: 'Edit Profile',
                          icon: Icons.edit,
                          background: AppColors.card,
                          textColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 16,
                          ),
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        _TopButton(
                          label: 'Logout',
                          icon: Icons.logout,
                          background: AppColors.red,
                          textColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 14,
                          ),
                          onTap: () {},
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: AppColors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // الصورة + الاسم + الوظيفة
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _ProfileAvatar(imageUrl: profileImage),
                        const SizedBox(width: 40),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Accountant',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // أرقام التواصل
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            title: 'Mobile Number',
                            value: mobileNumber,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _InfoCard(
                            title: 'Telephone Number',
                            value: telephoneNumber,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // العنوان
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: width > 900 ? 520 : double.infinity,
                        child: _AddressCard(
                          title: 'Address',
                          value: address,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================== Widgets صغيرة ==================

class _TopButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color textColor;
  final EdgeInsets padding;
  final VoidCallback onTap;

  const _TopButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.textColor,
    required this.padding,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: Row(
              children: [
                Icon(icon, color: textColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              color: AppColors.yellow,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  
  const _ProfileAvatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // دائرة خارجية فيها Gradient + Shadow
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
              colors: [AppColors.yellow, Color(0xFF555555), AppColors.yellow],
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.45),
              ),
            ],
          ),
        ),

        // الصورة نفسها
        CircleAvatar(
          radius: 110,
          backgroundColor: AppColors.card,
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    width: 220,
                    height: 220,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, size: 110, color: AppColors.white),
                  )
                : const Icon(Icons.person, size: 110, color: AppColors.white),
          ),
        ),

        // Badge صغير يوضح الدور
        Positioned(
          bottom: 12,
          right: 18,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.yellow, width: 1.4),
            ),
            child: const Icon(
              Icons.star_rounded,
              size: 20,
              color: AppColors.yellow,
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String title;
  final String value;

  const _AddressCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              color: AppColors.yellow,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
