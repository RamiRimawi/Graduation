import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool isEditMode = false;
  bool isSaving = false;
  int? accountantId;
  String name = '';
  String mobileNumber = '';
  String telephoneNumber = '';
  String address = '';
  String? profileImage;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  late TextEditingController nameController;
  late TextEditingController mobileController;
  late TextEditingController telephoneController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    mobileController = TextEditingController();
    telephoneController = TextEditingController();
    addressController = TextEditingController();
    _loadAccountantData();
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    telephoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountantData() async {
    try {
      // Get accountant ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      accountantId = prefs.getInt('accountant_id');

      if (accountantId == null) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

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
          .eq('accountant_id', accountantId!)
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
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImageToStorage() async {
    if (_selectedImageBytes == null ||
        _selectedImageName == null ||
        accountantId == null) {
      return null;
    }

    try {
      final extension = _selectedImageName!.toLowerCase().split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'accountant_${accountantId}_$timestamp.$extension';

      // Upload to Supabase Storage
      await supabase.storage
          .from('images')
          .uploadBinary(fileName, _selectedImageBytes!);

      // Get public URL
      final publicUrl = supabase.storage.from('images').getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  void _toggleEditMode() {
    if (isEditMode) {
      // Save changes
      _saveChanges();
    } else {
      // Enter edit mode
      setState(() {
        isEditMode = true;
        nameController.text = name;
        mobileController.text = mobileNumber;
        telephoneController.text = telephoneNumber;
        addressController.text = address;
      });
    }
  }

  Future<void> _saveChanges() async {
    // Check if any data has changed
    bool hasChanges =
        nameController.text.trim() != name ||
        mobileController.text.trim() != mobileNumber ||
        telephoneController.text.trim() != telephoneNumber ||
        addressController.text.trim() != address ||
        _selectedImageBytes != null;

    // If no changes, just exit edit mode without saving
    if (!hasChanges) {
      setState(() {
        isEditMode = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() => isSaving = true);

    try {
      if (accountantId == null) {
        throw 'No accountant ID found';
      }

      // Prepare accountant data
      final Map<String, dynamic> accountantData = {
        'name': nameController.text.trim(),
        'mobile_number': mobileController.text.trim(),
        'telephone_number': telephoneController.text.trim(),
        'address': addressController.text.trim(),
      };

      // Update accountant table
      await supabase
          .from('accountant')
          .update(accountantData)
          .eq('accountant_id', accountantId!);

      // Update profile image if changed
      if (_selectedImageBytes != null) {
        final imageUrl = await _uploadImageToStorage();
        if (imageUrl != null) {
          await supabase
              .from('user_account_accountant')
              .update({'profile_image': imageUrl})
              .eq('accountant_id', accountantId!);
          profileImage = imageUrl;

          // Update cached profile image
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_image', imageUrl);
        }
      }

      // Update local state
      if (!mounted) return;
      setState(() {
        name = nameController.text.trim();
        mobileNumber = mobileController.text.trim();
        telephoneNumber = telephoneController.text.trim();
        address = addressController.text.trim();
        isEditMode = false;
        isSaving = false;
        _selectedImageBytes = null;
        _selectedImageName = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
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
                    child: CircularProgressIndicator(color: AppColors.yellow),
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
                                label: isEditMode ? 'Save' : 'Edit Profile',
                                icon: isEditMode ? Icons.check : Icons.edit,
                                background: isEditMode
                                    ? Colors.green
                                    : AppColors.card,
                                textColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 16,
                                ),
                                onTap: isSaving ? () {} : _toggleEditMode,
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
                                onTap: () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.remove('accountant_id');
                                  if (context.mounted) {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/login',
                                    );
                                  }
                                },
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
                              _ProfileAvatar(
                                imageUrl: profileImage,
                                selectedImageBytes: _selectedImageBytes,
                                isEditMode: isEditMode,
                                onEditPressed: _pickImage,
                              ),
                              const SizedBox(width: 40),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    isEditMode
                                        ? IntrinsicHeight(
                                            child: TextFormField(
                                              controller: nameController,
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontSize: 42,
                                                fontWeight: FontWeight.w800,
                                              ),
                                              decoration: InputDecoration(
                                                border: UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: AppColors.yellow
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                                focusedBorder:
                                                    const UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: AppColors.yellow,
                                                        width: 2,
                                                      ),
                                                    ),
                                                enabledBorder:
                                                    UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: AppColors.yellow
                                                            .withOpacity(0.3),
                                                      ),
                                                    ),
                                                contentPadding: EdgeInsets.zero,
                                                isDense: true,
                                              ),
                                            ),
                                          )
                                        : Text(
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
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // أرقام التواصل
                          Row(
                            children: [
                              Expanded(
                                child: _EditableInfoCard(
                                  title: 'Mobile Number',
                                  value: mobileNumber,
                                  controller: mobileController,
                                  isEditMode: isEditMode,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _EditableInfoCard(
                                  title: 'Telephone Number',
                                  value: telephoneNumber,
                                  controller: telephoneController,
                                  isEditMode: isEditMode,
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
                              child: _EditableAddressCard(
                                title: 'Address',
                                value: address,
                                controller: addressController,
                                isEditMode: isEditMode,
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

class _EditableInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final TextEditingController controller;
  final bool isEditMode;

  const _EditableInfoCard({
    required this.title,
    required this.value,
    required this.controller,
    required this.isEditMode,
  });

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
          Expanded(
            child: isEditMode
                ? TextFormField(
                    controller: controller,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    maxLength: 9,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    style: const TextStyle(
                      color: AppColors.yellow,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.yellow.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.yellow,
                          width: 2,
                        ),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.yellow.withOpacity(0.3),
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                      isDense: true,
                    ),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.yellow,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? selectedImageBytes;
  final bool isEditMode;
  final VoidCallback? onEditPressed;

  const _ProfileAvatar({
    this.imageUrl,
    this.selectedImageBytes,
    this.isEditMode = false,
    this.onEditPressed,
  });

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
            child: selectedImageBytes != null
                ? Image.memory(
                    selectedImageBytes!,
                    fit: BoxFit.cover,
                    width: 220,
                    height: 220,
                  )
                : imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    width: 220,
                    height: 220,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      size: 110,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.person, size: 110, color: AppColors.white),
          ),
        ),

        // Badge/Camera button
        Positioned(
          bottom: 12,
          right: 18,
          child: InkWell(
            onTap: isEditMode ? onEditPressed : null,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.yellow, width: 1.4),
              ),
              child: Icon(
                isEditMode ? Icons.camera_alt : Icons.star_rounded,
                size: 20,
                color: AppColors.yellow,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditableAddressCard extends StatelessWidget {
  final String title;
  final String value;
  final TextEditingController controller;
  final bool isEditMode;

  const _EditableAddressCard({
    required this.title,
    required this.value,
    required this.controller,
    required this.isEditMode,
  });

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
          Expanded(
            child: isEditMode
                ? TextFormField(
                    controller: controller,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.yellow,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.yellow.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.yellow,
                          width: 2,
                        ),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.yellow.withOpacity(0.3),
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.yellow,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
