import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_state.dart';
import 'screens/dashboard_screen.dart';
import 'screens/generate_qr_screen.dart';
import 'screens/active_qr_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/manage_wallets_screen.dart';
import 'screens/wallet_transactions_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  runApp(const TempWalApp());
}

class TempWalApp extends StatelessWidget {
  const TempWalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          final themeData = ThemeData(
            useMaterial3: true,
            colorScheme: state.isDarkMode
                ? const ColorScheme.dark(
                    primary: Color(0xFFFACC15),
                    secondary: Color(0xFF38BDF8),
                    surface: Color(0xFF0B0B0F),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF6366F1), // Professional Indigo
                    secondary: Color(0xFF4F46E5),
                    surface: Color(0xFFF8FAFC),
                    onSurface: Color(0xFF0F172A),
                  ),
            scaffoldBackgroundColor: state.isDarkMode ? const Color(0xFF050506) : const Color(0xFFF1F5F9),
            fontFamily: 'SF Pro',
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: state.isDarkMode ? const Color(0xFF111827) : Colors.white,
            ),
          );

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TempWal',
            theme: themeData,
            home: state.isAuthenticated ? const TempWalShell() : const AuthScreen(),
          );
        },
      ),
    );
  }
}

class TempWalShell extends StatelessWidget {
  const TempWalShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    return PopScope(
      canPop: state.currentView == 'dashboard',
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          state.setView('dashboard');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: state.isDarkMode ? Colors.black : const Color(0xFFF1F5F9),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                children: [
                  HeaderBar(state: state),
                  Expanded(child: _buildCurrentScreen(state)),
                  if (state.currentView == 'dashboard')
                    FloatingScannerButton(state: state),
                  BottomNavBar(state: state),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen(AppState state) {
    final activeWallet = state.selectedWalletId == null
        ? null
        : state.tempWallets.firstWhere(
            (wallet) => wallet.id == state.selectedWalletId,
            orElse: () => state.tempWallets.first,
          );

    switch (state.currentView) {
      case 'dashboard':
        return DashboardScreen(state: state);
      case 'generate':
        return GenerateQrScreen(state: state);
      case 'active':
        final qr = state.activeQR;
        return qr == null ? DashboardScreen(state: state) : ActiveQrScreen(state: state, qrData: qr);
      case 'history':
        return TransactionHistoryScreen(state: state);
      case 'wallets':
        return ManageWalletsScreen(state: state);
      case 'wallet-transactions':
        return (activeWallet == null) 
            ? DashboardScreen(state: state) 
            : WalletTransactionsScreen(state: state, wallet: activeWallet);
      case 'scanner':
        return ScannerScreen(state: state);
      case 'settings':
        return const SettingsScreen();
      default:
        return DashboardScreen(state: state);
    }
  }
}

class HeaderBar extends StatelessWidget {
  const HeaderBar({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final bool isDark = state.isDarkMode;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F12) : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TempWal',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: isDark ? const Color(0xFFFACC15) : const Color(0xFF6366F1),
                ),
              ),
              const Text(
                'the only wallet you need',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => state.setView('settings'),
              icon: Icon(
                Icons.settings_rounded,
                color: isDark ? const Color(0xFFFACC15) : const Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingScannerButton extends StatelessWidget {
  const FloatingScannerButton({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final bool isDark = state.isDarkMode;
    return Container(
      height: 80,
      width: 80,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFFFACC15) : const Color(0xFF6366F1),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFFFACC15) : const Color(0xFF6366F1)).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => state.setView('scanner'),
          customBorder: const CircleBorder(),
          child: Icon(
            Icons.qr_code_scanner_rounded,
            color: isDark ? Colors.black : Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F12) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            label: 'Home',
            icon: Icons.home_rounded,
            view: 'dashboard',
            state: state,
          ),
          _BottomNavItem(
            label: 'Generate',
            icon: Icons.add_circle_rounded,
            view: 'generate',
            state: state,
          ),
          _BottomNavItem(
            label: 'History',
            icon: Icons.history_rounded,
            view: 'history',
            state: state,
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.view,
    required this.state,
  });

  final String label;
  final IconData icon;
  final String view;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final bool active = state.currentView == view;
    final isDark = state.isDarkMode;
    final Color activeColor = isDark ? const Color(0xFFFACC15) : const Color(0xFF6366F1);
    final Color inactiveColor = isDark ? Colors.grey[700]! : Colors.grey[400]!;

    return InkWell(
      onTap: () => state.setView(view),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? activeColor : inactiveColor, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
