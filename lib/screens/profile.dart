import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_limiter/core/constants/app_colors.dart';
import 'package:app_limiter/core/common/navigation_helper.dart';
import 'package:app_limiter/core/common/fetcher.dart';
import 'package:app_limiter/core/common/multipart_fetcher.dart';
import 'package:app_limiter/components/edit_profile_modal.dart';
import 'package:app_limiter/core/common/token_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 2;
  bool _notificationsEnabled = true;
  String _currentTheme = 'Dark';
  bool _isLoading = true;
  
  String _userName = 'Loading...';
  String _userEmail = '';
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await Fetcher.get('/auth/profile');
      
      if (response['success'] == true && response['user'] != null) {
        setState(() {
          _userName = response['user']['name'] ?? 'User';
          _userEmail = response['user']['email'] ?? '';
          _profileImageUrl = response['user']['profileImage'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _userName = 'Error loading profile';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUpdateProfile(String name, String email, File? imageFile) async {
    try {
      final response = await MultipartFetcher.updateProfileWithImage(
        name: name,
        email: email,
        profileImage: imageFile,
      );

      if (response['success'] == true) {
        setState(() {
          _userName = response['user']['name'] ?? name;
          _userEmail = response['user']['email'] ?? email;
          _profileImageUrl = response['user']['profileImage'];
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      rethrow; 
    }
  }

  void _showEditProfileModal() {
    EditProfileModal.show(
      context: context,
      currentName: _userName,
      currentEmail: _userEmail,
      currentProfileImage: _profileImageUrl,
      onSave: _handleUpdateProfile,
    );
  }

  void _onTabTapped(int index) {
    if (index == 0) {
      context.navigateToNamed('/dashboard');
    } else if (index == 1) {
      context.navigateToNamed('/limits');
    } else if (index == 2) {
      if (_currentIndex != 2) {
        setState(() {
          _currentIndex = 2;
        });
      }
    }
  }

  void _onNotificationToggle(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    print('Notifications enabled: $value');
  }

  void _onThemeToggle() {
    setState(() {
      _currentTheme = _currentTheme == 'Dark' ? 'Light' : 'Dark';
    });
    print('Theme changed to: $_currentTheme');
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1D3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to sign out of your account?',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await TokenManager.instance.clearTokens();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E25),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0E25),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: _showEditProfileModal,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            children: [
              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                            ? Image.network(
                                'https://uas-mobile.achmichael.my.id$_profileImageUrl',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFF1A1D3A),
                                    child: const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppColors.primary,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: const Color(0xFF1A1D3A),
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showEditProfileModal,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0B0E25),
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // User Name
              Text(
                _userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // User Email
              Text(
                _userEmail,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              // Settings Section Header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SETTINGS',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Notifications Setting
              // _buildSettingCard(
              //   icon: Icons.notifications_outlined,
              //   title: 'Notifications',
              //   subtitle: 'Manage your app alerts',
              //   trailing: Switch(
              //     value: _notificationsEnabled,
              //     onChanged: _onNotificationToggle,
              //     activeThumbColor: AppColors.primary,
              //     activeTrackColor: AppColors.primary.withOpacity(0.5),
              //   ),
              // ),
              const SizedBox(height: 12),
              // Theme Setting
              // _buildSettingCard(
              //   icon: Icons.palette_outlined,
              //   title: 'Theme',
              //   subtitle: 'Dark or Light mode',
              //   trailing: TextButton(
              //     onPressed: _onThemeToggle,
              //     style: TextButton.styleFrom(
              //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              //       backgroundColor: AppColors.primary.withOpacity(0.2),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //     ),
              //     child: Text(
              //       _currentTheme,
              //       style: const TextStyle(
              //         color: AppColors.primary,
              //         fontWeight: FontWeight.w600,
              //       ),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 12),
              // Privacy Setting
              _buildSettingCard(
                icon: Icons.lock_outline,
                title: 'Privacy',
                subtitle: 'Manage your privacy settings',
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 18,
                ),
                onTap: () => print('Navigate to Privacy settings'),
              ),
              const SizedBox(height: 12),
              // Help & Support Setting
              _buildSettingCard(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help and contact us',
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 18,
                ),
                onTap: () => print('Navigate to Help & Support'),
              ),
              const SizedBox(height: 12),
              // Logout Setting
              _buildSettingCard(
                icon: Icons.logout,
                iconColor: Colors.red,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                trailing: const Icon(
                  Icons.exit_to_app,
                  color: Colors.red,
                  size: 24,
                ),
                onTap: _showLogoutDialog,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.navyTone,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.muted,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.home_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.home),
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.timer_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.timer),
                  ),
                  label: 'Limits',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.person_outline),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.person),
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    Color iconColor = AppColors.primary,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141833),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
            ),
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}