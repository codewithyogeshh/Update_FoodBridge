import '../../features/authentication/domain/models/app_user.dart';
import '../../features/authentication/presentation/auth_provider.dart';

/// Resolves the first screen a user should land on after the splash (or the
/// first-launch permission screen). Mirrors the role-based routing used by the
/// splash screen so both entry points behave identically.
String resolveInitialRoute(AuthProvider auth) {
  if (auth.isAuthenticated && auth.user != null) {
    final user = auth.user!;
    switch (user.role) {
      case UserRole.donor:
        if (user.donorCategory?.toLowerCase().contains('restaurant') == true) {
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
  return '/onboarding';
}
