import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockData.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          // Header
          Container(
            color: AppTheme.primary,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white24,
                  child: Text(
                    user.avatarInitials,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(user.role, style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(user.department, style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Info section
          _SectionHeader(title: 'Contact Information'),
          _InfoTile(icon: Icons.email_outlined, label: 'Email', value: user.email),
          _InfoTile(icon: Icons.phone_outlined, label: 'Phone', value: user.phone),

          _SectionHeader(title: 'Attendance This Month'),
          _StatsTile(),

          _SectionHeader(title: 'Settings'),
          _ActionTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () {}),
          _ActionTile(icon: Icons.language_outlined, label: 'Language', value: 'English', onTap: () {}),
          _ActionTile(icon: Icons.lock_outline, label: 'Change Password', onTap: () {}),
          _ActionTile(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}),

          _SectionHeader(title: ''),
          _ActionTile(
            icon: Icons.logout,
            label: 'Sign Out',
            labelColor: AppTheme.danger,
            iconColor: AppTheme.danger,
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text('Zeus v1.0.0 · Powered by ERPNext',
                style: TextStyle(fontSize: 11, color: AppTheme.borderLight)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSubtle, letterSpacing: 0.8),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textMuted),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSubtle)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color? labelColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.value,
    this.labelColor,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppTheme.textMuted),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 14, color: labelColor ?? AppTheme.textPrimary)),
            ),
            if (value != null) Text(value!, style: const TextStyle(fontSize: 13, color: AppTheme.textSubtle)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: labelColor?.withValues(alpha: 0.5) ?? AppTheme.borderLight),
          ],
        ),
      ),
    );
  }
}

class _StatsTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          _StatCell(label: 'Present', value: '18', color: AppTheme.success),
          _StatCell(label: 'Absent', value: '1', color: AppTheme.danger),
          _StatCell(label: 'On Leave', value: '2', color: AppTheme.warning),
          _StatCell(label: 'Working Days', value: '21', color: AppTheme.primary),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSubtle), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
