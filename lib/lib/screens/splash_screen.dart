import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'auth/login_screen.dart';
import 'main/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;
  late VoidCallback _authListener;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    
    // Animatsiyalarni sozlash
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    // Animatsiyalarni boshlash
    _startAnimations();

    // AuthProvider holatini tinglash va farm tayyor bo'lganda navigatsiya qilish
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _authListener = () {
      _navigateIfReady();
    };
    authProvider.addListener(_authListener);
  }

  void _startAnimations() async {
    // Logo animatsiyasini boshlash
    await _logoController.forward();
    
    // Fade animatsiyasini boshlash
    await _fadeController.forward();
    
    // 1 soniya kutish
    await Future.delayed(const Duration(seconds: 1));
    
    // Authentication holatini tekshirish
    _navigateIfReady();

    // Fallback: yuklash cho'zilib ketsa, 5 soniyada Dashboard/Login ga o'tish
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || _navigated) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        _removeAuthListenerSafely();
        _navigated = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        _removeAuthListenerSafely();
        _navigated = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  void _navigateIfReady() {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Agar foydalanuvchi tizimga kirmagan bo'lsa darhol login sahifasiga
    if (!authProvider.isAuthenticated) {
      _removeAuthListenerSafely();
      _navigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    // Agar tizimga kirgan bo'lsa va yuklash tugagan bo'lsa, Dashboard'ga o'tamiz
    // Farm null bo'lsa ham Dashboard ichida sinxronlash davom etadi
    if (!authProvider.isLoading && authProvider.isAuthenticated) {
      _removeAuthListenerSafely();
      _navigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    _removeAuthListenerSafely();
    super.dispose();
  }

  void _removeAuthListenerSafely() {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.removeListener(_authListener);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo va app nomi
            AnimatedBuilder(
              animation: _logoAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoAnimation.value,
                  child: Column(
                    children: [
                      // App ikonkasi
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(60),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          AppConstants.chickenIcon,
                          size: 60,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // App nomi
                      Text(
                        AppConstants.appName,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      
                      // App tavsifi
                      const SizedBox(height: 8),
                      Text(
                        'Tovuq fermasi boshqaruvi',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 80),
            
            // Loading indikatori
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppConstants.loadingMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 