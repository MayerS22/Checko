import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme/dark_modern_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Dark & Modern Settings Screen
///
/// Features:
/// - Glassmorphism list items
/// - Clean sections
/// - Firebase integration
class DarkSettingsScreen extends StatefulWidget {
  const DarkSettingsScreen({super.key});

  @override
  State<DarkSettingsScreen> createState() => _DarkSettingsScreenState();
}

class _DarkSettingsScreenState extends State<DarkSettingsScreen> {
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DarkModernTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium)),
        title: Text(
          'Edit Username',
          style: DarkModernTheme.titleLarge,
        ),
        content: TextField(
          controller: _usernameController,
          style: DarkModernTheme.bodyLarge,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: DarkModernTheme.textSecondary),
            filled: true,
            fillColor: DarkModernTheme.surface.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DarkModernTheme.radiusSmall),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DarkModernTheme.radiusSmall),
              borderSide: const BorderSide(color: DarkModernTheme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: DarkModernTheme.textSecondary),
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
    final userProvider = context.watch<UserProvider>();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: DarkModernTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Compact header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: GlassContainer(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: DarkModernTheme.accentPink.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: DarkModernTheme.accentPink,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Settings',
                      style: DarkModernTheme.titleLarge,
                    ),
                    const Spacer(),
                    // Menu button
                    GestureDetector(
                      onTap: () => Scaffold.of(context).openEndDrawer(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.menu,
                          color: DarkModernTheme.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Settings list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Profile section
                  _buildSectionHeader('Profile'),
                  _buildGlassListTile(
                    icon: Icons.person_outline,
                    iconColor: DarkModernTheme.primary,
                    title: userProvider.username,
                    subtitle: 'Tap to edit',
                    trailing: Icons.chevron_right,
                    onTap: _showEditUsernameDialog,
                  ),

                  const SizedBox(height: 16),

                  // Account section
                  _buildSectionHeader('Account'),
                  _buildGlassListTile(
                    icon: Icons.email_outlined,
                    iconColor: DarkModernTheme.accentBlue,
                    title: 'Email',
                    subtitle: user?.email ?? 'Not signed in',
                    onTap: null,
                  ),
                  const SizedBox(height: 8),
                  _buildGlassListTile(
                    icon: Icons.cloud_done_outlined,
                    iconColor: DarkModernTheme.accentGreen,
                    title: 'Backup',
                    subtitle: 'Synced with Firebase',
                    onTap: null,
                  ),
                  const SizedBox(height: 8),
                  if (user != null)
                    _buildGlassListTile(
                      icon: Icons.logout_rounded,
                      iconColor: DarkModernTheme.accentRed,
                      title: 'Sign Out',
                      subtitle: null,
                      trailing: null,
                      onTap: () => _signOut(context),
                      isDestructive: true,
                    ),

                  const SizedBox(height: 16),

                  // About section
                  _buildSectionHeader('About'),
                  _buildGlassListTile(
                    icon: Icons.info_outline,
                    iconColor: DarkModernTheme.textSecondary,
                    title: 'Checko',
                    subtitle: 'Version 1.0.0',
                    onTap: null,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: DarkModernTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGlassListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    IconData? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DarkModernTheme.surface.withOpacity(0.6),
            DarkModernTheme.surface.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium),
        border: Border.all(
          color: isDestructive
              ? DarkModernTheme.accentRed.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: DarkModernTheme.bodyLarge.copyWith(
            color: isDestructive ? DarkModernTheme.accentRed : null,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: DarkModernTheme.bodySmall,
              )
            : null,
        trailing: trailing != null
            ? Icon(
                trailing,
                color: DarkModernTheme.textTertiary,
                size: 20,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DarkModernTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium)),
        title: Text(
          'Sign Out',
          style: DarkModernTheme.titleLarge,
        ),
        content: Text(
          'Your data will remain saved in Firebase. You can sign in anytime to access it.',
          style: DarkModernTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: DarkModernTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: DarkModernTheme.accentRed,
            ),
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
              backgroundColor: DarkModernTheme.accentRed,
            ),
          );
        }
      }
    }
  }
}
