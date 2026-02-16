import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/unified_image_service.dart';
import 'admin_user_management_screen.dart';
import 'notification_settings_screen.dart';
import 'system_reports_screen.dart';
import 'help_support_screen.dart';
import '../screens/home_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? currentUser;
  bool _isLoading = true;
  String? profileImagePath;

  // Password visibility states
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // @override
  // void initState() {
  //   super.initState();
  //   _loadUserProfile();

  //   // Listen to auth state changes
  //   AuthService.authStateChanges.listen((user) {
  //     if (mounted) {
  //       setState(() {
  //         currentUser = user;
  //         _isLoading = false;
  //       });
  //     }
  //   });
  // }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    // Listen to auth state changes
    AuthService.authStateChanges.listen((user) async {
      if (mounted && user != null) {
        // Fetch the full Firestore profile whenever auth state changes
        final firestoreUser = await AuthService.getCurrentUserFromFirestore();
        setState(() {
          currentUser = firestoreUser;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          currentUser = null;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current user from AuthService
      final user = await AuthService.getCurrentUserFromFirestore();

      if (mounted) {
        setState(() {
          currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return 'U';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : 'U';
    }
    return '${words[0][0].toUpperCase()}${words[1][0].toUpperCase()}';
  }

  String _getFirstName(String name) {
    if (name.isEmpty) return 'User';
    final nameParts = name.split(' ');
    return nameParts[0];
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[850]
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[600]
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Select Profile Photo',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () async {
                        Navigator.pop(context);
                        await _pickAndUploadImage(ImageSource.camera);
                      },
                    ),
                    _buildImageOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () async {
                        Navigator.pop(context);
                        await _pickAndUploadImage(ImageSource.gallery);
                      },
                    ),
                    if (profileImagePath != null ||
                        currentUser?.profilePhotoPath != null)
                      _buildImageOption(
                        icon: Icons.delete,
                        label: 'Remove',
                        color: Colors.red,
                        onTap: () async {
                          Navigator.pop(context);
                          await _removeProfilePhoto();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      XFile? imageFile;
      if (source == ImageSource.camera) {
        imageFile = await UnifiedImageService.pickImageFromCamera();
      } else {
        imageFile = await UnifiedImageService.pickImageFromGallery();
      }

      if (imageFile != null) {
        // Upload image to Firebase Storage
        final downloadUrl =
            await UnifiedImageService.uploadProfileImage(imageFile);

        if (downloadUrl != null) {
          // Update user profile with new image URL
          await AuthService.updateUserProfile(profilePhotoPath: downloadUrl);

          // Update local state
          setState(() {
            profileImagePath = imageFile!.path;
          });

          // Reload user profile to get updated data
          await _loadUserProfile();

          Navigator.pop(context); // Close loading dialog

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Profile photo updated successfully!')),
          );
        } else {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to upload image. Please try again.')),
          );
        }
      } else {
        Navigator.pop(context); // Close loading dialog
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile photo: $e')),
      );
    }
  }

  Future<void> _removeProfilePhoto() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Delete old photo from storage if it exists
      if (currentUser?.profilePhotoPath != null) {
        await UnifiedImageService.deleteImage(currentUser!.profilePhotoPath!);
      }

      // Update user profile to remove photo
      await AuthService.updateUserProfile(profilePhotoPath: '');

      // Update local state
      setState(() {
        profileImagePath = null;
      });

      // Reload user profile to get updated data
      await _loadUserProfile();

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo removed successfully!')),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing profile photo: $e')),
      );
    }
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor =
        color ?? (isDark ? Colors.white : Theme.of(context).primaryColor);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: effectiveColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: effectiveColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: effectiveColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Profile Photo Section
                  Center(
                    child: GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: _buildUserAvatar(currentUser),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // User Name
                  Center(
                    child: Text(
                      currentUser?.displayName.split(',')[0] ?? 'User',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey[800],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Profile Information Section
                  _buildProfileInfo(),

                  const SizedBox(height: 20),

                  // Settings Section
                  _buildSettingsSection(),

                  const SizedBox(height: 20),

                  // Admin Section (only for admin users)
                  if (currentUser?.isAdmin == true) ...[
                    _buildAdminSection(),
                    const SizedBox(height: 20),
                  ],

                  // Sign Out Section
                  _buildSignOutSection(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  'Profile Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey[800],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _showEditProfileDialog,
                  icon: const Icon(Icons.edit, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
                'Full Name', currentUser?.displayName ?? 'Not provided'),
            _buildInfoRow('Email', currentUser?.email ?? 'Not available'),
            _buildInfoRow(
                'Role', currentUser?.isAdmin == true ? 'Admin' : 'Staff'),
            _buildInfoRow(
                'Member Since',
                currentUser != null
                    ? DateFormat('MMMM d, yyyy').format(currentUser!.createdAt)
                    : 'Not available'),
            _buildInfoRow(
                'Last Login',
                currentUser != null
                    ? DateFormat('MMM d, yyyy • h:mm a')
                        .format(currentUser!.lastLoginAt)
                    : 'Not available'),
            _buildInfoRow('Status',
                currentUser?.isActive == true ? 'Active' : 'Inactive'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white60
                    : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.87)
                    : Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsOption(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Manage notification preferences',
              onTap: () => Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const NotificationSettingsScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              ),
              iconColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.amber[300]
                  : Colors.amber[700], // Theme-aware amber color
            ),
            _buildSettingsOption(
              icon: Icons.security,
              title: 'Security',
              subtitle: 'Change password and security settings',
              onTap: () => _showChangePasswordDialog(),
              iconColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.orange[300]
                  : Colors.orange[700], // Theme-aware orange color
            ),
            _buildSettingsOption(
              icon: Icons.help,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              onTap: () => Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const HelpSupportScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              ),
              iconColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.blue[300]
                  : Colors.blue[700], // Theme-aware blue color
            ),
            _buildSettingsOption(
              icon: Icons.info,
              title: 'About',
              subtitle: 'App version and information',
              onTap: () => _showAboutDialog(),
              iconColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.purple[300]
                  : Colors.purple[700], // Theme-aware purple color
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Theme.of(context).primaryColor)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? Theme.of(context).primaryColor),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white60
              : Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white54
            : Colors.grey[600],
      ),
      onTap: onTap,
    );
  }

  Widget _buildAdminSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  'Admin Tools',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsOption(
              icon: Icons.group,
              title: 'Manage Users',
              subtitle: 'View and manage user accounts',
              onTap: () => _showManageUsersDialog(),
              iconColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.teal[300]
                  : Colors.teal[700], // Theme-aware teal color
            ),
            _buildSettingsOption(
              icon: Icons.bar_chart,
              title: 'System Reports',
              subtitle: 'View system analytics and reports',

              onTap: () {
                final homeState =
                    context.findAncestorStateOfType<HomePageState>();
                homeState?.selectTab(4); // ensure Profile tab is selected

                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const SystemReportsScreen(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              },

              iconColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.indigo[300]
                  : Colors.indigo[700], // Theme-aware indigo color
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout, color: Colors.red),
              ),
              title: Text(
                'Sign Out',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              subtitle: Text(
                'Sign out from your account',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : Colors.grey[600],
                ),
              ),
              onTap: () => _showSignOutConfirmation(),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController =
        TextEditingController(text: currentUser?.displayName ?? '');
    final emailController =
        TextEditingController(text: currentUser?.email ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                enabled: false, // Email should not be editable
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AuthService.updateUserProfile(
                  displayName: nameController.text.trim(),
                );
                await _loadUserProfile();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Profile updated successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating profile: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmNewPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: SizedBox(
              width:
                  MediaQuery.of(context).size.width * 0.8, // responsive width
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: _obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCurrentPassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(() =>
                            _obscureCurrentPassword = !_obscureCurrentPassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _obscureNewPassword = !_obscureNewPassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmNewPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate inputs
                if (currentPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter your current password')),
                  );
                  return;
                }

                if (newPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a new password')),
                  );
                  return;
                }

                if (newPasswordController.text !=
                    confirmNewPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match')),
                  );
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('New password must be at least 6 characters')),
                  );
                  return;
                }

                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  await AuthService.changePassword(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                  );

                  Navigator.pop(context); // Close loading dialog
                  Navigator.pop(context); // Close change password dialog

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context); // Close loading dialog

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Change Password',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showManageUsersDialog() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AdminUserManagementScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _showSignOutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _signOut(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _signOut() async {
    try {
      await AuthService.signOut();
      Navigator.pop(context);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'StockSense',
      applicationVersion: '3.0.0',
      applicationIcon: Icon(
        Icons.inventory_2,
        size: 48,
        color: Theme.of(context).primaryColor,
      ),
      children: [
        const Text(
            'A comprehensive, smart inventory management system with AI-powered stock predictions.'),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• Real-time inventory tracking'),
        const Text('• Stock movement logging'),
        const Text('• AI-powered stock predictions'),
        const Text('• User role management'),
        const Text('• Mobile responsive design'),
      ],
    );
  }

  void _showNotImplementedDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text(
            '$feature functionality will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[200],
      child: Center(
        child: Text(
          _getInitials(currentUser?.displayName ?? 'User'),
          style: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.grey[800],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(dynamic user) {
    if (user?.profilePhotoPath != null && user!.profilePhotoPath!.isNotEmpty) {
      // Handle base64 data URLs
      if (user.profilePhotoPath!.startsWith('data:image')) {
        try {
          final base64String = user.profilePhotoPath!.split(',')[1];
          final bytes = base64Decode(base64String);
          return CircleAvatar(
            backgroundColor: user.isActive
                ? (Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                    : Theme.of(context).primaryColor.withValues(alpha: 0.1))
                : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.1)),
            backgroundImage: MemoryImage(bytes),
            onBackgroundImageError: (exception, stackTrace) {

            },
          );
        } catch (e) {

        }
      } else {
        // Handle network URLs
        return CircleAvatar(
          backgroundColor: user.isActive
              ? (Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                  : Theme.of(context).primaryColor.withValues(alpha: 0.1))
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1)),
          backgroundImage: NetworkImage(user.profilePhotoPath!),
          onBackgroundImageError: (exception, stackTrace) {

          },
        );
      }
    }

    // Fallback to initials
    // Match dashboard: soft white tint and white initials for contrast
    return CircleAvatar(
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      child: Text(
        user?.displayName.isNotEmpty == true
            ? user.displayName[0].toUpperCase()
            : 'U',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
