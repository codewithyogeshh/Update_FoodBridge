import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/router/initial_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/foodbridge_logo.dart';
import '../../authentication/presentation/auth_provider.dart';
import 'permission_request_screen.dart';

/// The official FoodBridge Splash Screen (Matching Image 1 Screen 1).
/// Features a deep emerald gradient, the glowing FoodBridge white heart emblem,
/// the brand mission tagline, and a bottom organic container with fresh food visuals
/// and a progress bar indicator.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _navigateToNext();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    await auth.restoreSession();

    if (!mounted) return;

    // First launch: ask for runtime permissions before proceeding.
    var permissionsRequested = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      permissionsRequested =
          prefs.getBool(PermissionRequestScreen.storageKey) ?? false;
    } catch (_) {}

    if (!mounted) return;

    if (!permissionsRequested) {
      context.go('/permissions');
      return;
    }

    context.go(resolveInitialRoute(auth));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A331D), // Dark lush emerald
              Color(0xFF135A37), // Primary deep green
              Color(0xFF1B6E44), // Vibrant forest
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Hero FoodBridge Logo & Tagline (White variant)
              const FoodBridgeLogo(
                size: 96,
                isLight: true,
                showTagline: true,
                customTagline: 'Share More. Waste Less. Bridge the Need.',
              ),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Text(
                  'Together for a Hunger-Free Tomorrow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Bottom organic card with appetizing food and progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Column(
                    children: [
                      // Food plate emblem / visual representation
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withOpacity(0.2),
                          border: Border.all(color: AppColors.white.withOpacity(0.4), width: 2),
                        ),
                        child: const Icon(
                          Icons.ramen_dining,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Connecting Donors • NGOs • Volunteers',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Animated progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 4,
                          width: 140,
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              return LinearProgressIndicator(
                                value: _progressController.value,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
