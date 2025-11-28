import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../models/user_settings.dart';
import '../theme/app_colors.dart';
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.isDarkMode ? AppColors.panel : AppColors.lightPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Edit Username',
          style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _usernameController,
          style: TextStyle(color: context.textPrimaryColor),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: context.textMutedColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: context.textMutedColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (_usernameController.text.trim().isNotEmpty) {
                userProvider.updateUsername(_usernameController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPomodoroSettingsDialog() {
    final userProvider = context.read<UserProvider>();
    final settings = userProvider.settings;
    
    int workDuration = settings?.pomodoroWorkDuration ?? 25;
    int breakDuration = settings?.pomodoroBreakDuration ?? 5;
    int longBreakDuration = settings?.pomodoroLongBreakDuration ?? 15;
    int sessionsBeforeLongBreak = settings?.pomodoroSessionsBeforeLongBreak ?? 4;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.isDarkMode ? AppColors.panel : AppColors.lightPanel,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Pomodoro Settings',
            style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSliderSetting(
                  'Work Duration',
                  '$workDuration min',
                  workDuration.toDouble(),
                  15,
                  60,
                  (value) => setDialogState(() => workDuration = value.round()),
                ),
                const SizedBox(height: 16),
                _buildSliderSetting(
                  'Break Duration',
                  '$breakDuration min',
                  breakDuration.toDouble(),
                  1,
                  15,
                  (value) => setDialogState(() => breakDuration = value.round()),
                ),
                const SizedBox(height: 16),
                _buildSliderSetting(
                  'Long Break Duration',
                  '$longBreakDuration min',
                  longBreakDuration.toDouble(),
                  10,
                  30,
                  (value) => setDialogState(() => longBreakDuration = value.round()),
                ),
                const SizedBox(height: 16),
                _buildSliderSetting(
                  'Sessions Before Long Break',
                  '$sessionsBeforeLongBreak',
                  sessionsBeforeLongBreak.toDouble(),
                  2,
                  8,
                  (value) => setDialogState(() => sessionsBeforeLongBreak = value.round()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: context.textMutedColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                userProvider.updatePomodoroSettings(
                  workDuration: workDuration,
                  breakDuration: breakDuration,
                  longBreakDuration: longBreakDuration,
                  sessionsBeforeLongBreak: sessionsBeforeLongBreak,
                );
                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSetting(
    String label,
    String value,
    double current,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: context.textPrimaryColor)),
            Text(value, style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: current,
          min: min,
          max: max,
          divisions: (max - min).round(),
          activeColor: AppColors.accent,
          inactiveColor: context.outlineColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.backgroundColor,
                  AppColors.accent.withValues(alpha: 0.14),
                  AppColors.accentAlt.withValues(alpha: 0.14),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: context.surfaceElevatedColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.outlineColor),
                              ),
                              child: Icon(Icons.arrow_back, color: context.textPrimaryColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.surfaceElevatedColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.outlineColor),
                            ),
                            child: const Icon(Icons.settings, color: AppColors.accent, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Checko',
                                style: TextStyle(color: context.textMutedColor, fontSize: 14),
                              ),
                              Text(
                                'Settings',
                                style: TextStyle(
                                  color: context.textPrimaryColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: context.panelColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          // Profile Section
                          _buildSectionTitle('Profile'),
                          const SizedBox(height: 12),
                          _buildProfileCard(userProvider),
                          
                          const SizedBox(height: 24),
                          // Appearance Section
                          _buildSectionTitle('Appearance'),
                          const SizedBox(height: 12),
                          _buildSettingTile(
                            icon: Icons.dark_mode,
                            title: 'Dark Mode',
                            subtitle: themeProvider.isDarkMode ? 'On' : 'Off',
                            trailing: Switch(
                              value: themeProvider.isDarkMode,
                              onChanged: (_) => themeProvider.toggleTheme(),
                              activeThumbColor: AppColors.accent,
                            ),
                          ),

                          const SizedBox(height: 24),
                          // Pomodoro Section
                          _buildSectionTitle('Pomodoro Timer'),
                          const SizedBox(height: 12),
                          _buildSettingTile(
                            icon: Icons.timer,
                            title: 'Timer Settings',
                            subtitle: '${userProvider.settings?.pomodoroWorkDuration ?? 25} min work, ${userProvider.settings?.pomodoroBreakDuration ?? 5} min break',
                            onTap: _showPomodoroSettingsDialog,
                          ),
                          _buildSettingTile(
                            icon: Icons.volume_up,
                            title: 'Sound',
                            subtitle: userProvider.settings?.soundEnabled ?? true ? 'On' : 'Off',
                            trailing: Switch(
                              value: userProvider.settings?.soundEnabled ?? true,
                              onChanged: (value) => userProvider.updateSoundSettings(soundEnabled: value),
                              activeThumbColor: AppColors.accent,
                            ),
                          ),
                          _buildSettingTile(
                            icon: Icons.vibration,
                            title: 'Vibration',
                            subtitle: userProvider.settings?.vibrationEnabled ?? true ? 'On' : 'Off',
                            trailing: Switch(
                              value: userProvider.settings?.vibrationEnabled ?? true,
                              onChanged: (value) => userProvider.updateSoundSettings(vibrationEnabled: value),
                              activeThumbColor: AppColors.accent,
                            ),
                          ),

                          const SizedBox(height: 24),
                          // Achievements Section
                          _buildSectionTitle('Achievements'),
                          const SizedBox(height: 12),
                          _buildAchievementsGrid(userProvider),

                          const SizedBox(height: 24),
                          // Stats Section
                          _buildSectionTitle('Statistics'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  '🔥',
                                  'Current Streak',
                                  '${userProvider.currentStreak} days',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  '🏆',
                                  'Longest Streak',
                                  '${userProvider.longestStreak} days',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildStatCard(
                            '✅',
                            'Total Tasks Completed',
                            '${userProvider.totalTasksCompleted}',
                          ),

                          const SizedBox(height: 24),
                          // Account Section
                          _buildSectionTitle('Account'),
                          const SizedBox(height: 12),
                          _buildSettingTile(
                            icon: Icons.account_circle,
                            title: 'Signed in as',
                            subtitle: FirebaseAuth.instance.currentUser?.email ?? 'Guest',
                          ),
                          _buildSignOutButton(),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: context.textPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildProfileCard(UserProvider userProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.3),
            AppColors.accentAlt.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.outlineColor),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.accentAlt],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                userProvider.username.isNotEmpty ? userProvider.username[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProvider.username,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${userProvider.achievements.length} achievements unlocked',
                  style: TextStyle(color: context.textMutedColor, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showEditUsernameDialog,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.surfaceColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit, color: context.textPrimaryColor, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.outlineColor),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.accent, size: 24),
        ),
        title: Text(title, style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: context.textMutedColor, fontSize: 12)),
        trailing: trailing ?? Icon(Icons.chevron_right, color: context.textMutedColor),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAchievementsGrid(UserProvider userProvider) {
    final achievements = Achievement.allAchievements;
    final unlocked = userProvider.achievements;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: achievements.map((achievement) {
        final isUnlocked = unlocked.contains(achievement.id);
        return Tooltip(
          message: '${achievement.title}\n${achievement.description}',
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isUnlocked 
                  ? AppColors.accent.withValues(alpha: 0.2) 
                  : context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnlocked ? AppColors.accent : context.outlineColor,
              ),
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 28,
                  color: isUnlocked ? null : Colors.grey,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard(String emoji, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.outlineColor),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: context.textMutedColor, fontSize: 12),
              ),
              Text(
                value,
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.logout, color: AppColors.danger, size: 24),
        ),
        title: Text(
          'Sign Out',
          style: TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Sign out of your account',
          style: TextStyle(color: context.textMutedColor, fontSize: 12),
        ),
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: context.isDarkMode ? AppColors.panel : AppColors.lightPanel,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Text(
                'Sign Out',
                style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Are you sure you want to sign out?',
                style: TextStyle(color: context.textPrimaryColor),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel', style: TextStyle(color: context.textMutedColor)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );

          if (confirm == true && mounted) {
            try {
              await AuthService().signOut();
              // Navigation will be handled by AuthWrapper
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to sign out: $e'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }
}


