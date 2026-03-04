import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final state = context.read<AppState>();
    
    try {
      if (_isLogin) {
        await state.signIn(_emailController.text, _passwordController.text);
      } else {
        await state.signUp(_emailController.text, _passwordController.text);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF050506) : const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED),
              ),
              const SizedBox(height: 16),
              Text(
                'TempWal',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'Welcome Back!' : 'Create your account',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF111827) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF111827) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED),
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_isLogin ? 'Sign In' : 'Sign Up'),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? 'New here? Create an account' : 'Already have an account? Sign in',
                  style: TextStyle(color: isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
