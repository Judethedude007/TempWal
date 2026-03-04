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
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF7C3AED),
                    secondary: Color(0xFF2563EB),
                    surface: Color(0xFFFFFFFF),
                  ),
            fontFamily: 'SF Pro',
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
        color: state.isDarkMode ? Colors.black : const Color(0xFF1F173B),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: state.isDarkMode ? const Color(0xFF0F0F12) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                child: Scaffold(
                  backgroundColor: state.isDarkMode ? const Color(0xFF050506) : null,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      decoration: BoxDecoration(
        color: state.isDarkMode ? const Color(0xFF111113) : null,
        gradient: state.isDarkMode ? null : const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: state.isDarkMode ? const Border(bottom: BorderSide(color: Color(0xFF27272A))) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TempWal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: state.isDarkMode ? const Color(0xFFFACC15) : Colors.white,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: state.toggleTheme,
                icon: Icon(
                  Icons.settings_outlined,
                  color: state.isDarkMode ? const Color(0xFFFACC15) : Colors.white,
                ),
              ),
              IconButton(
                onPressed: state.signOut,
                icon: Icon(
                  Icons.logout,
                  color: state.isDarkMode ? const Color(0xFFFACC15) : Colors.white,
                ),
              ),
            ],
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
    return SizedBox(
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -32,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 72,
                height: 72,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.isDarkMode ? const Color(0xFFFACC15) : null,
                    gradient: state.isDarkMode ? null : const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6))],
                  ),
                  child: IconButton(
                    onPressed: () => state.setView('scanner'),
                    icon: Icon(
                      Icons.qr_code_scanner,
                      color: state.isDarkMode ? Colors.black : Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: state.isDarkMode ? const Color(0xFF111113) : Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BottomNavItem(
              label: 'Home',
              icon: Icons.home_outlined,
              view: 'dashboard',
              state: state,
            ),
          ),
          Expanded(
            child: _BottomNavItem(
              label: 'Generate',
              icon: Icons.add_circle_outline,
              view: 'generate',
              state: state,
            ),
          ),
          Expanded(
            child: _BottomNavItem(
              label: 'History',
              icon: Icons.history,
              view: 'history',
              state: state,
            ),
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
    final Color activeColor = state.isDarkMode ? const Color(0xFFFACC15) : const Color(0xFF7C3AED);
    final Color inactiveColor = state.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);

    return InkWell(
      onTap: () => state.setView(view),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: active ? BoxDecoration(
          border: Border(top: BorderSide(color: activeColor, width: 3)),
          color: activeColor.withOpacity(0.05),
        ) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? activeColor : inactiveColor, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
