import '../../features/authentication/domain/models/app_user.dart';

class RouteGuard {
  RouteGuard._();

  static const List<String> publicRoutes = [
    '/',
    '/onboarding',
    '/permissions',
    '/login',
    '/admin-login',
    '/register',
    '/forgot-password',
    '/reset-password',
    '/volunteer/get-started',
    '/verify-otp',
  ];

  static String homeForRole(UserRole role, [String? donorCategory]) {
    switch (role) {
      case UserRole.donor:
        if (donorCategory?.toLowerCase().contains('restaurant') == true) {
          return '/restaurant-donor';
        }
        return '/donor';
      case UserRole.ngo:
        return '/ngo';
      case UserRole.volunteer:
        return '/volunteer';
      case UserRole.admin:
        return '/admin';
    }
  }

  /// Evaluates target route and returns redirect path if unauthorized, or null if allowed
  static String? evaluate({
    required String location,
    required bool isAuthenticated,
    required UserRole? userRole,
    String? donorCategory,
  }) {
    final isPublic = publicRoutes.any(
      (route) =>
          location == route ||
          location.startsWith('/register') ||
          location.startsWith('/reset-password') ||
          location.startsWith('/verify-otp'),
    );

    // 1. Unauthenticated user attempting to access private route
    if (!isAuthenticated && !isPublic) {
      return '/login';
    }

    // 2. Strict Role-based access control (Authorization)
    if (isAuthenticated && userRole != null) {
      // Admin protection: Non-admins cannot enter any /admin route
      if (location.startsWith('/admin') && !location.startsWith('/admin-login') && userRole != UserRole.admin) {
        return homeForRole(userRole, donorCategory);
      }

      // Volunteer protection: Non-volunteers and non-admins cannot enter /volunteer
      if (location.startsWith('/volunteer') && !location.startsWith('/volunteer/get-started') && userRole != UserRole.volunteer && userRole != UserRole.admin) {
        return homeForRole(userRole, donorCategory);
      }

      // NGO protection: Non-NGOs and non-admins cannot enter /ngo
      if (location.startsWith('/ngo') && userRole != UserRole.ngo && userRole != UserRole.admin) {
        return homeForRole(userRole, donorCategory);
      }

      // Donor protection: Non-donors and non-admins cannot enter donation creation
      if ((location.startsWith('/donate-food') || location.startsWith('/donate-clothes') || location.startsWith('/create-donation')) &&
          userRole != UserRole.donor && userRole != UserRole.admin) {
        return homeForRole(userRole, donorCategory);
      }
    }

    return null;
  }
}

