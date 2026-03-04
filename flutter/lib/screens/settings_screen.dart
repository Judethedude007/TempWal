import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showSetPinDialog(BuildContext context, AppState state, bool isDark) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Set 4-Digit PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 16),
          decoration: InputDecoration(
            hintText: '0000',
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.3), letterSpacing: 16),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.length == 4) {
                state.setPin(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN updated successfully')));
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF050506) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _SettingsHeader(state: state),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const SizedBox(height: 24),
                _ProfileSection(state: state, isDark: isDark),
                const SizedBox(height: 32),
                _SectionTitle(title: 'Preference', isDark: isDark),
                const SizedBox(height: 12),
                _AppearanceCard(state: state, isDark: isDark),
                const SizedBox(height: 12),
                _SoundCard(state: state, isDark: isDark),
                const SizedBox(height: 32),
                _SectionTitle(title: 'Security', isDark: isDark),
                const SizedBox(height: 12),
                _SecurityCard(state: state, isDark: isDark, onSetPin: () => _showSetPinDialog(context, state, isDark)),
                const SizedBox(height: 32),
                _SectionTitle(title: 'Account', isDark: isDark),
                const SizedBox(height: 12),
                _AccountActionCard(state: state, isDark: isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
      child: Row(children: [
        IconButton(
          onPressed: () => state.setView('dashboard'), 
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? const Color(0xFFFACC15) : const Color(0xFF6366F1))
        ),
        const SizedBox(width: 8),
        Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
      ]),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.state, required this.isDark});
  final AppState state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (state.localProfilePath != null) {
      imageProvider = FileImage(File(state.localProfilePath!));
    }

    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? const Color(0xFFFACC15) : const Color(0xFF6366F1), width: 2),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                backgroundImage: imageProvider,
                child: imageProvider == null
                  ? Text(state.userName?.substring(0, 1).toUpperCase() ?? 'U', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFFACC15) : const Color(0xFF6366F1)))
                  : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => state.updateProfilePicture(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFFFACC15) : const Color(0xFF6366F1),
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF050506) : Colors.white, width: 2),
                  ),
                  child: Icon(Icons.camera_alt_rounded, size: 18, color: isDark ? Colors.black : Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(state.userName ?? 'User', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        Text(state.user?.email ?? '', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});
  final String title;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.grey[500])),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({required this.state, required this.isDark});
  final AppState state;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      isDark: isDark,
      child: Row(children: [
        _IconContainer(icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: const Color(0xFFFACC15)),
        const SizedBox(width: 16),
        const Expanded(child: Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
        Switch.adaptive(value: isDark, onChanged: (val) => state.toggleTheme(), activeColor: const Color(0xFFFACC15)),
      ]),
    );
  }
}

class _SoundCard extends StatelessWidget {
  const _SoundCard({required this.state, required this.isDark});
  final AppState state;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      isDark: isDark,
      child: Row(children: [
        _IconContainer(icon: state.isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: Colors.blue),
        const SizedBox(width: 16),
        const Expanded(child: Text('Payment Voice', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
        Switch.adaptive(value: state.isSoundEnabled, onChanged: (val) => state.toggleSound(), activeColor: Colors.blue),
      ]),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.state, required this.isDark, required this.onSetPin});
  final AppState state;
  final bool isDark;
  final VoidCallback onSetPin;
  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      isDark: isDark,
      onTap: onSetPin,
      child: Row(children: [
        _IconContainer(icon: Icons.lock_outline_rounded, color: Colors.orange),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Transaction PIN', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              Text(state.userPin == null ? 'Not set - Set now' : 'PIN Protection Active', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
      ]),
    );
  }
}

class _AccountActionCard extends StatelessWidget {
  const _AccountActionCard({required this.state, required this.isDark});
  final AppState state;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      isDark: isDark,
      onTap: state.signOut,
      child: Row(children: [
        _IconContainer(icon: Icons.logout_rounded, color: Colors.red),
        const SizedBox(width: 16),
        const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
      ]),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child, required this.isDark, this.onTap});
  final Widget child;
  final bool isDark;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}

class _IconContainer extends StatelessWidget {
  const _IconContainer({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
