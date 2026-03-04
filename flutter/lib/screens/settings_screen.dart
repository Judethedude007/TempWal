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
        title: const Text('Set 4-Digit PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter new PIN'),
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
              padding: const EdgeInsets.all(24),
              children: [
                _SectionTitle(title: 'Appearance', isDark: isDark),
                const SizedBox(height: 12),
                _AppearanceCard(state: state, isDark: isDark),
                const SizedBox(height: 32),
                _SectionTitle(title: 'Security', isDark: isDark),
                const SizedBox(height: 12),
                _SecurityCard(state: state, isDark: isDark, onSetPin: () => _showSetPinDialog(context, state, isDark)),
                const SizedBox(height: 32),
                _SectionTitle(title: 'Sound & Notifications', isDark: isDark),
                const SizedBox(height: 12),
                _SoundCard(state: state, isDark: isDark),
                const SizedBox(height: 32),
                _SectionTitle(title: 'Account', isDark: isDark),
                const SizedBox(height: 12),
                _AccountCard(state: state, isDark: isDark),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Row(children: [
        IconButton(onPressed: () => state.setView('dashboard'), icon: Icon(Icons.arrow_back_ios_new, color: state.isDarkMode ? const Color(0xFFFACC15) : const Color(0xFF1F2937))),
        const SizedBox(width: 8),
        Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: state.isDarkMode ? Colors.white : const Color(0xFF0F172A))),
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
    return Container(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF111827) : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB))),
      child: ListTile(
        onTap: onSetPin,
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.lock_outline, color: Colors.orange)),
        title: const Text('Transaction PIN', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(state.userPin == null ? 'Not set - Set now' : 'PIN is active'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({required this.state, required this.isDark});
  final AppState state;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF111827) : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFACC15).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: const Color(0xFFFACC15))),
          const SizedBox(width: 16),
          const Expanded(child: Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          Switch.adaptive(value: isDark, onChanged: (val) => state.toggleTheme(), activeColor: const Color(0xFFFACC15)),
        ]),
      ),
    );
  }
}

class _SoundCard extends StatelessWidget {
  const _SoundCard({required this.state, required this.isDark});
  final AppState state;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF111827) : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(state.isSoundEnabled ? Icons.volume_up : Icons.volume_off, color: Colors.blue)),
          const SizedBox(width: 16),
          const Expanded(child: Text('Payment Voice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          Switch.adaptive(value: state.isSoundEnabled, onChanged: (val) => state.toggleSound(), activeColor: Colors.blue),
        ]),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.state, required this.isDark});
  final AppState state;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF111827) : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB))),
      child: Column(children: [
        ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(backgroundColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6), child: Text(state.userName?.substring(0, 1).toUpperCase() ?? 'U', style: TextStyle(color: isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED)))),
          title: Text(state.userName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(state.user?.email ?? ''),
        ),
        const Divider(height: 1),
        ListTile(onTap: state.signOut, leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});
  final String title;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: isDark ? Colors.grey[500] : Colors.grey[600]));
  }
}
