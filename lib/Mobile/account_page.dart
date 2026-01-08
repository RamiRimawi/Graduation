import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import 'bottom_navbar.dart';
import 'Supplier/supplier_home_page.dart';
import 'DeliveryDriver/deleviry_home.dart';
import 'StroageStaff/staff_home.dart';
import 'Customer/customer_home_page.dart';
import 'Customer/customer_cart_page.dart';
import 'Customer/customer_archive_page.dart';
import 'Manager/ManagerShell.dart';
import 'LoginMobile.dart';

class AccountPage extends StatefulWidget {
  final bool showNavBar;

  const AccountPage({super.key, this.showNavBar = true});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _photo;

  bool _isPressed = false;
  bool _loading = true;
  bool _imageReady = false;
  String? _name;
  String? _role;
  String? _address;
  String? _mobile;
  String? _telephone;
  String? _idLabel;
  String? _profileImageUrl;
  String? _userRole;
  bool _profileCached = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (mounted) {
        setState(() {
          _photo = image;
          _loading = true;
        });
      }

      // Upload image to Supabase and update database
      await _uploadProfileImage(image);
    }
  }

  Future<void> _uploadProfileImage(XFile imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userIdStr = prefs.getString('current_user_id');
      String? userRole = prefs.getString('current_user_role');
      final int? userId = userIdStr != null ? int.tryParse(userIdStr) : null;

      if (userId == null || userRole == null) {
        if (mounted) {
          setState(() => _loading = false);
        }
        return;
      }

      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${userRole}_${userId}_$timestamp.png';

      // Read file bytes
      final bytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage
      await supabase.storage
          .from('images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );

      // Get public URL
      final String imageUrl = supabase.storage
          .from('images')
          .getPublicUrl(fileName);

      // Update unified accounts table
      await supabase
          .from('accounts')
          .update({'profile_image': imageUrl})
          .eq('user_id', userId);

      // Cache locally so we don't refetch next time
      await prefs.setString('profile_image_url', imageUrl);
      if (mounted) {
        setState(() {
          _profileImageUrl = imageUrl;
          _loading = false;
          _profileCached = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCachedProfileData();
    _loadProfile();
  }

  Future<void> _loadCachedProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedName = prefs.getString('cached_user_name');
      final String? cachedRole = prefs.getString('cached_user_role');
      final String? cachedAddress = prefs.getString('cached_user_address');
      final String? cachedMobile = prefs.getString('cached_user_mobile');
      final String? cachedTelephone = prefs.getString('cached_user_telephone');
      final String? cachedImage = prefs.getString('cached_user_image');

      if (cachedName != null) {
        if (mounted) {
          setState(() {
            _name = cachedName;
            _role = cachedRole;
            _address = cachedAddress;
            _mobile = cachedMobile;
            _telephone = cachedTelephone;
            _profileImageUrl = cachedImage;
            _profileCached = true;
            _loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading cached profile: $e');
    }
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _loading = true);
      final prefs = await SharedPreferences.getInstance();
      final String? userIdStr = prefs.getString('current_user_id');
      final String? userRole = prefs.getString('current_user_role');
      final String? cachedImage = prefs.getString('profile_image_url');

      // Parse userId to int
      final int? userId = userIdStr != null ? int.tryParse(userIdStr) : null;

      // Store role for conditional nav bar rendering
      if (mounted) {
        setState(() {
          _userRole = userRole;
          if (cachedImage != null && cachedImage.isNotEmpty) {
            _profileImageUrl = cachedImage;
            _profileCached = true;
          }
        });
      }

      // Attempt based on stored role; fallback to delivery_driver
      if (userId != null) {
        if (userRole == 'delivery_driver') {
          await _loadDeliveryDriver(userId);
        } else if (userRole == 'supplier') {
          await _loadSupplier(userId);
        } else if (userRole == 'storage_staff') {
          await _loadStorageStaff(userId);
        } else if (userRole == 'sales_rep') {
          await _loadSalesRep(userId);
        } else if (userRole == 'storage_manager' || userRole == 'manager') {
          await _loadStorageManager(userId);
        } else if (userRole == 'customer') {
          await _loadCustomer(userId);
        } else {
          // Default to delivery driver
          await _loadDeliveryDriver(userId);
        }
      }
    } catch (e) {
      debugPrint('Failed loading profile: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDeliveryDriver(int id) async {
    final profile = await supabase
        .from('delivery_driver')
        .select(
          'delivery_driver_id,name,mobile_number,telephone_number,address,accounts!delivery_driver_delivery_driver_id_fkey(profile_image)',
        )
        .eq('delivery_driver_id', id)
        .maybeSingle();

    if (profile != null) {
      // Extract profile image from accounts
      String? profileImage;
      if (!_profileCached) {
        final account = profile['accounts'];
        if (account is List && account.isNotEmpty) {
          profileImage = account.first['profile_image'] as String?;
        } else if (account is Map<String, dynamic>) {
          profileImage = account['profile_image'] as String?;
        }
      }

      if (mounted) {
        setState(() {
          _name = profile['name'] as String?;
          _role = 'Delivery Driver';
          _address = profile['address'] as String?;
          _mobile = profile['mobile_number']?.toString();
          _telephone = profile['telephone_number']?.toString();
          _idLabel = profile['delivery_driver_id']?.toString();
          _profileImageUrl = _profileCached ? _profileImageUrl : profileImage;
          _imageReady = false;
        });
      }
      await _precacheProfileImage();
    }
  }

  Future<void> _loadSupplier(int id) async {
    final profile = await supabase
        .from('supplier')
        .select(
          'supplier_id,name,mobile_number,telephone_number,address,accounts!supplier_supplier_id_fkey(profile_image)',
        )
        .eq('supplier_id', id)
        .maybeSingle();

    if (profile != null) {
      // Extract profile image from accounts
      String? profileImage;
      if (!_profileCached) {
        final account = profile['accounts'];
        if (account is List && account.isNotEmpty) {
          profileImage = account.first['profile_image'] as String?;
        } else if (account is Map<String, dynamic>) {
          profileImage = account['profile_image'] as String?;
        }
      }

      if (mounted) {
        setState(() {
          _name = profile['name'] as String?;
          _role = 'Supplier';
          _address = profile['address'] as String?;
          _mobile = profile['mobile_number']?.toString();
          _telephone = profile['telephone_number']?.toString();
          _idLabel = profile['supplier_id']?.toString();
          _profileImageUrl = _profileCached ? _profileImageUrl : profileImage;
          _imageReady = false;
        });
      }
      await _precacheProfileImage();
    }
  }

  Future<void> _loadStorageStaff(int id) async {
    final profile = await supabase
        .from('storage_staff')
        .select(
          'storage_staff_id,name,mobile_number,telephone_number,address,accounts!storage_staff_storage_staff_id_fkey(profile_image)',
        )
        .eq('storage_staff_id', id)
        .maybeSingle();

    if (profile != null) {
      // Extract profile image from accounts
      String? profileImage;
      if (!_profileCached) {
        final account = profile['accounts'];
        if (account is List && account.isNotEmpty) {
          profileImage = account.first['profile_image'] as String?;
        } else if (account is Map<String, dynamic>) {
          profileImage = account['profile_image'] as String?;
        }
      }

      if (mounted) {
        setState(() {
          _name = profile['name'] as String?;
          _role = 'Storage Staff';
          _address = profile['address'] as String?;
          _mobile = profile['mobile_number']?.toString();
          _telephone = profile['telephone_number']?.toString();
          _idLabel = profile['storage_staff_id']?.toString();
          _profileImageUrl = _profileCached ? _profileImageUrl : profileImage;
          _imageReady = false;
        });
      }
      await _precacheProfileImage();
    }
  }

  Future<void> _loadSalesRep(int id) async {
    final profile = await supabase
        .from('sales_representative')
        .select(
          'sales_rep_id,name,mobile_number,telephone_number,email,accounts!sales_representative_sales_rep_id_fkey(profile_image)',
        )
        .eq('sales_rep_id', id)
        .maybeSingle();

    if (profile != null) {
      // Extract profile image from accounts
      String? profileImage;
      if (!_profileCached) {
        final account = profile['accounts'];
        if (account is List && account.isNotEmpty) {
          profileImage = account.first['profile_image'] as String?;
        } else if (account is Map<String, dynamic>) {
          profileImage = account['profile_image'] as String?;
        }
      }

      if (mounted) {
        setState(() {
          _name = profile['name'] as String?;
          _role = 'Sales Representative';
          _address = profile['email'] as String?; // show email in address field
          _mobile = profile['mobile_number']?.toString();
          _telephone = profile['telephone_number']?.toString();
          _idLabel = profile['sales_rep_id']?.toString();
          _profileImageUrl = _profileCached ? _profileImageUrl : profileImage;
          _imageReady = false;
        });
      }
      await _precacheProfileImage();
    }
  }

  Future<void> _loadStorageManager(int id) async {
    final profile = await supabase
        .from('storage_manager')
        .select(
          'storage_manager_id,name,mobile_number,telephone_number,address,accounts!storage_manager_storage_manager_id_fkey(profile_image)',
        )
        .eq('storage_manager_id', id)
        .maybeSingle();

    if (profile != null) {
      // Extract profile image from accounts
      String? profileImage;
      if (!_profileCached) {
        final account = profile['accounts'];
        if (account is List && account.isNotEmpty) {
          profileImage = account.first['profile_image'] as String?;
        } else if (account is Map<String, dynamic>) {
          profileImage = account['profile_image'] as String?;
        }
      }

      if (mounted) {
        setState(() {
          _name = profile['name'] as String?;
          _role = 'Storage Manager';
          _address = profile['address'] as String?;
          _mobile = profile['mobile_number']?.toString();
          _telephone = profile['telephone_number']?.toString();
          _idLabel = profile['storage_manager_id']?.toString();
          _profileImageUrl = _profileCached ? _profileImageUrl : profileImage;
          _imageReady = false;
        });
      }
      await _precacheProfileImage();
    }
  }

  Future<void> _loadCustomer(int id) async {
    final profile = await supabase
        .from('customer')
        .select(
          'customer_id,name,mobile_number,telephone_number,address,accounts!customer_customer_id_fkey(profile_image)',
        )
        .eq('customer_id', id)
        .maybeSingle();

    if (profile != null) {
      // Extract profile image from accounts
      String? profileImage;
      if (!_profileCached) {
        final account = profile['accounts'];
        if (account is List && account.isNotEmpty) {
          profileImage = account.first['profile_image'] as String?;
        } else if (account is Map<String, dynamic>) {
          profileImage = account['profile_image'] as String?;
        }
      }

      if (mounted) {
        setState(() {
          _name = profile['name'] as String?;
          _role = 'Customer';
          _address = profile['address'] as String?;
          _mobile = profile['mobile_number']?.toString();
          _telephone = profile['telephone_number']?.toString();
          _idLabel = profile['customer_id']?.toString();
          _profileImageUrl = _profileCached ? _profileImageUrl : profileImage;
          _imageReady = false;
        });
      }
      await _precacheProfileImage();
    }
  }

  Future<void> _precacheProfileImage() async {
    try {
      if (!mounted) return;
      if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
        final provider = NetworkImage(_profileImageUrl!);
        await precacheImage(provider, context);
        if (mounted) setState(() => _imageReady = true);
      } else {
        if (mounted) setState(() => _imageReady = false);
      }
    } catch (_) {
      if (mounted) setState(() => _imageReady = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202020),

      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 90, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isPressed = true),
                      onTapUp: (_) => setState(() => _isPressed = false),
                      onTapCancel: () => setState(() => _isPressed = false),
                      child: AnimatedScale(
                        scale: _isPressed ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isPressed
                                  ? const [Color(0xFF50B2E7), Color(0xFF3A8FC9)]
                                  : const [
                                      Color(0xFFFFE14D),
                                      Color(0xFFB7A447),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Builder(
                            builder: (context) {
                              final hasLocalPhoto = _photo != null;
                              final hasRemotePhoto =
                                  _profileImageUrl != null &&
                                  _profileImageUrl!.isNotEmpty;
                              if (hasLocalPhoto) {
                                final ImageProvider provider = hasLocalPhoto
                                    ? FileImage(File(_photo!.path))
                                    : const AssetImage(''); // won't be used
                                return CircleAvatar(
                                  radius: 95,
                                  backgroundImage: provider,
                                );
                              }
                              if (hasRemotePhoto && _imageReady) {
                                return CircleAvatar(
                                  radius: 95,
                                  backgroundImage: NetworkImage(
                                    _profileImageUrl!,
                                  ),
                                );
                              }
                              if (hasRemotePhoto && !_imageReady) {
                                return CircleAvatar(
                                  radius: 95,
                                  backgroundColor: Colors.black12,
                                  child: const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Color(0xFFFFE14D),
                                    ),
                                  ),
                                );
                              }
                              // Fallback: show icon when no image available
                              return CircleAvatar(
                                radius: 95,
                                backgroundColor: Colors.black12,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 64,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB7A447),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Color(0xFF202020),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                _loading
                    ? const SizedBox(
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFE14D),
                        ),
                      )
                    : Text(
                        _name ?? 'Account',
                        style: const TextStyle(
                          color: Color(0xFFFFE14D),
                          fontWeight: FontWeight.w700,
                          fontSize: 25,
                        ),
                      ),
                const SizedBox(height: 20),
                _buildLabelAndBox('ID #', _idLabel ?? '--'),
                _buildLabelAndBox('Role', _role ?? '--'),
                _buildLabelAndBox('Address', _address ?? '--'),
                _buildLabelAndBox('Mobile Number', _mobile ?? '--'),
                _buildLabelAndBox('Telephone Number', _telephone ?? '--'),
              ],
            ),
          ),

          Positioned(
            top: 40,
            right: 12,
            child: GestureDetector(
              onTap: () async {
                // Show confirmation dialog
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF2D2D2D),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Are you sure you want to logout? This will clear saved credentials.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Color(0xFFE74C3C)),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  // Clear all saved data including Remember Me
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  // Navigate to login page and remove all previous routes
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.logout, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar:
          // Only show nav bar if showNavBar is true (not inside ManagerShell)
          !widget.showNavBar
          ? null
          :
            // Customer layout: 4 tabs (Home, Cart, Archive, Account)
            (_userRole == 'customer')
          ? BottomNavBar(
              currentIndex: 3,
              onTap: (i) {
                if (i == 0) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomerHomePage()),
                  );
                } else if (i == 1) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomerCartPage()),
                  );
                } else if (i == 2) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerArchivePage(),
                    ),
                  );
                } else if (i == 3) {
                  // already on AccountPage
                }
              },
            )
          :
            // Manager layout: 5 tabs (Home, Stock-out, Stock-in, Notification, Account)
            (_userRole == 'manager' || _userRole == 'storage_manager')
          ? Builder(
              builder: (context) {
                return BottomNavBar(
                  currentIndex: 4,
                  onTap: (i) {
                    if (i == 0) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ManagerShell()),
                      );
                    }
                  },
                );
              },
            )
          :
            // Supplier / staff / delivery layout (2 tabs: Home, Account)
            (_userRole == 'supplier' ||
                _userRole == 'storage_staff' ||
                _userRole == 'delivery_driver' ||
                _userRole == 'delivery')
          ? Builder(
              builder: (context) {
                return BottomNavBar(
                  currentIndex: 1,
                  onTap: (i) async {
                    if (i == 0) {
                      final prefs = await SharedPreferences.getInstance();
                      final String? userIdStr = prefs.getString(
                        'current_user_id',
                      );
                      final int? userId = userIdStr != null
                          ? int.tryParse(userIdStr)
                          : null;

                      Widget homePage;
                      if ((_userRole == 'delivery_driver' ||
                              _userRole == 'delivery') &&
                          userId != null) {
                        homePage = HomeDeleviry(deliveryDriverId: userId);
                      } else if (_userRole == 'storage_staff') {
                        homePage = const HomeStaff();
                      } else {
                        homePage = const SupplierHomePage();
                      }
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => homePage),
                        );
                      }
                    }
                  },
                );
              },
            )
          : null,
    );
  }

  Widget _buildLabelAndBox(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFFB7A447),
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
