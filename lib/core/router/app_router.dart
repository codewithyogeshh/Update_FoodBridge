import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/permission_request_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/register_screen.dart';
import '../../features/authentication/presentation/otp_verification_screen.dart';
import '../../features/authentication/presentation/forgot_password_screen.dart';
import '../../features/authentication/presentation/reset_password_screen.dart';
import '../../features/authentication/presentation/auth_provider.dart';
import '../../features/donor/presentation/donor_dashboard_screen.dart';
import '../../features/donor/presentation/create_donation_screen.dart';
import '../../features/donor/presentation/donate_food_screen.dart';
import '../../features/donor/presentation/donate_clothes_screen.dart';
import '../../features/donor/presentation/donation_preview_screen.dart';
import '../../features/donor/presentation/edit_donation_screen.dart';
import '../../features/donor/presentation/my_donations_screen.dart';
import '../../features/donations/domain/models/donation.dart';
import '../../features/donations/presentation/donation_detail_screen.dart';
import '../../features/ngo/presentation/ngo_dashboard_screen.dart';
import '../../features/ngo/presentation/ngo_claims_screen.dart';
import '../../features/ngo/presentation/ngo_verification_screen.dart';
import '../../features/ngo/presentation/distribution_records_screen.dart';
import '../../features/volunteer/presentation/volunteer_dashboard_screen.dart';
import '../../features/volunteer/presentation/volunteer_history_screen.dart';
import '../../features/volunteer/presentation/volunteer_mission_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/donor/presentation/analytics_screen.dart';
import '../../features/donor/presentation/restaurant_donor_dashboard_screen.dart';
import '../../features/authentication/presentation/admin_login_screen.dart';
import '../../features/donations/presentation/tracking_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/volunteer/presentation/volunteer_get_started_screen.dart';
import '../../features/volunteer/presentation/volunteer_available_tasks_screen.dart';
import '../../features/volunteer/presentation/volunteer_task_tracking_screen.dart';
import '../../features/volunteer/presentation/volunteer_activity_screen.dart';
import '../../features/volunteer/presentation/volunteer_impact_screen.dart';
import '../../features/volunteer/presentation/volunteer_profile_screen.dart';
import '../../features/volunteer/presentation/volunteer_rewards_screen.dart';
import 'route_guard.dart';

class AppRouter {
  static GoRouter createRouter([AuthProvider? authProvider]) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        if (authProvider == null) return null;
        return RouteGuard.evaluate(
          location: state.matchedLocation,
          isAuthenticated: authProvider.isAuthenticated,
          userRole: authProvider.user?.role,
          donorCategory: authProvider.user?.donorCategory,
        );
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/permissions',
          builder: (context, state) => const PermissionRequestScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) {
            final role = state.uri.queryParameters['role'];
            return RegisterScreen(initialRole: role);
          },
        ),
        GoRoute(
          path: '/verify-otp',
          builder: (context, state) {
            final email = state.uri.queryParameters['email'] ?? '';
            final role = state.uri.queryParameters['role'];
            final lengthParam = state.uri.queryParameters['length'];
            final otpLength = int.tryParse(lengthParam ?? '') ?? 8;
            return OtpVerificationScreen(
              email: email,
              initialRole: role,
              otpLength: otpLength,
            );
          },
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final email = state.uri.queryParameters['email'];
            return ResetPasswordScreen(initialEmail: email);
          },
        ),
        GoRoute(
          path: '/donor',
          builder: (context, state) => const DonorDashboardScreen(),
        ),
        GoRoute(
          path: '/restaurant-donor',
          builder: (context, state) => const RestaurantDonorDashboardScreen(),
        ),
        GoRoute(
          path: '/admin-login',
          builder: (context, state) => const AdminLoginScreen(),
        ),
        GoRoute(
          path: '/tracking/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? 'dn-101';
            return TrackingScreen(donationId: id);
          },
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/donor/dashboard',
          builder: (context, state) => const DonorDashboardScreen(),
        ),
        GoRoute(
          path: '/donor/my-donations',
          builder: (context, state) => const MyDonationsScreen(),
        ),
        GoRoute(
          path: '/create-donation',
          builder: (context, state) => const CreateDonationScreen(),
        ),
        GoRoute(
          path: '/donate-food',
          builder: (context, state) {
            final title = state.uri.queryParameters['title'];
            final qty = state.uri.queryParameters['qty'];
            final desc = state.uri.queryParameters['desc'];
            return DonateFoodScreen(
              initialTitle: title,
              initialQty: qty,
              initialDesc: desc,
            );
          },
        ),
        GoRoute(
          path: '/donate-clothes',
          builder: (context, state) {
            final title = state.uri.queryParameters['title'];
            final qty = state.uri.queryParameters['qty'];
            final desc = state.uri.queryParameters['desc'];
            return DonateClothesScreen(
              initialTitle: title,
              initialQty: qty,
              initialDesc: desc,
            );
          },
        ),
        GoRoute(
          path: '/donation-preview',
          builder: (context, state) {
            final donation = state.extra as Donation;
            return DonationPreviewScreen(donation: donation);
          },
        ),
        GoRoute(
          path: '/edit-donation/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return EditDonationScreen(donationId: id);
          },
        ),
        GoRoute(
          path: '/donation-detail/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return DonationDetailScreen(donationId: id);
          },
        ),
        GoRoute(
          path: '/ngo',
          builder: (context, state) => const NgoDashboardScreen(),
        ),
        GoRoute(
          path: '/ngo/dashboard',
          builder: (context, state) => const NgoDashboardScreen(),
        ),
        GoRoute(
          path: '/ngo/my-claims',
          builder: (context, state) => const NgoClaimsScreen(),
        ),
        GoRoute(
          path: '/ngo/distribution-records',
          builder: (context, state) => const DistributionRecordsScreen(),
        ),
        GoRoute(
          path: '/ngo/verification',
          builder: (context, state) => const NgoVerificationScreen(),
        ),
        GoRoute(
          path: '/volunteer/get-started',
          builder: (context, state) => const VolunteerGetStartedScreen(),
        ),
        GoRoute(
          path: '/volunteer',
          builder: (context, state) => const VolunteerDashboardScreen(),
        ),
        GoRoute(
          path: '/volunteer/tasks',
          builder: (context, state) => const VolunteerAvailableTasksScreen(),
        ),
        GoRoute(
          path: '/volunteer/tracking',
          builder: (context, state) => const VolunteerTaskTrackingScreen(),
        ),
        GoRoute(
          path: '/volunteer/activity',
          builder: (context, state) => const VolunteerActivityScreen(),
        ),
        GoRoute(
          path: '/volunteer/impact',
          builder: (context, state) => const VolunteerImpactScreen(),
        ),
        GoRoute(
          path: '/volunteer/profile',
          builder: (context, state) => const VolunteerProfileScreen(),
        ),
        GoRoute(
          path: '/volunteer/rewards',
          builder: (context, state) => const VolunteerRewardsScreen(),
        ),
        GoRoute(
          path: '/volunteer/history',
          builder: (context, state) => const VolunteerHistoryScreen(),
        ),
        GoRoute(
          path: '/volunteer/mission/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return VolunteerMissionScreen(donationId: id);
          },
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) => const EditProfileScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page not found: ${state.uri}'),
        ),
      ),
    );
  }

  static final GoRouter router = createRouter();
}
