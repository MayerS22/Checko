import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../theme/ms_todo_colors.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      _usernameController.text = userProvider.username;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _showEditUsernameDialog() {
    final userProvider = context.read<UserProvider>();
    _usernameController.text = userProvider.username;
    final isDark = context.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text(
          'Edit Username',
          style: TextStyle(
            color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
          ),
        ),
        content: TextField(
          controller: _usernameController,
          style: TextStyle(
            color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
          ),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: MSToDoColors.msTextSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: MSToDoColors.msTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              if (_usernameController.text.trim().isNotEmpty) {
                userProvider.updateUsername(_usernameController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: isDark ? MSToDoColors.msBackgroundDark : MSToDoColors.msBackground,
      body: Column(
        children: [
          // Clean header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 65, 16, 8),
            decoration: BoxDecoration(
              color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.settings,
                  color: MSToDoColors.msBlue,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Settings',
                  style: TextStyle(
                    color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Settings list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                // Profile section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      color: MSToDoColors.msTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
                    border: Border.all(
                      color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: MSToDoColors.msBlue,
                      child: Text(
                        userProvider.username.isNotEmpty ? userProvider.username[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      userProvider.username,
                      style: TextStyle(
                        color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      'Tap to edit',
                      style: TextStyle(
                        color: MSToDoColors.msTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: MSToDoColors.msTextSecondary,
                      size: 20,
                    ),
                    onTap: _showEditUsernameDialog,
                  ),
                ),

                const SizedBox(height: 16),

                // Appearance section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Appearance',
                    style: TextStyle(
                      color: MSToDoColors.msTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
                    border: Border.all(
                      color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      'Dark Mode',
                      style: TextStyle(
                        color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      themeProvider.isDarkMode ? 'On' : 'Off',
                      style: TextStyle(
                        color: MSToDoColors.msTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggleTheme(),
                    activeColor: MSToDoColors.msBlue,
                  ),
                ),

                const SizedBox(height: 16),

                // Account section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Account',
                    style: TextStyle(
                      color: MSToDoColors.msTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
                    border: Border.all(
                      color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(
                      Icons.email,
                      color: MSToDoColors.msTextSecondary,
                      size: 20,
                    ),
                    title: Text(
                      'Signed in as',
                      style: TextStyle(
                        color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      FirebaseAuth.instance.currentUser?.email ?? 'Guest',
                      style: TextStyle(
                        color: MSToDoColors.msTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
                    border: Border.all(
                      color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(
                      Icons.logout,
                      color: MSToDoColors.error,
                      size: 20,
                    ),
                    title: Text(
                      'Sign Out',
                      style: TextStyle(
                        color: MSToDoColors.error,
                        fontSize: 15,
                      ),
                    ),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          title: Text(
                            'Sign Out',
                            style: TextStyle(
                              color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to sign out?',
                            style: TextStyle(
                              color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: MSToDoColors.msTextSecondary),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        try {
                          await AuthService().signOut();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to sign out: $e'),
                                backgroundColor: MSToDoColors.error,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // About section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'About',
                    style: TextStyle(
                      color: MSToDoColors.msTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
                    border: Border.all(
                      color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(
                      Icons.info_outline,
                      color: MSToDoColors.msTextSecondary,
                      size: 20,
                    ),
                    title: Text(
                      'Checko',
                      style: TextStyle(
                        color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: MSToDoColors.msTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
