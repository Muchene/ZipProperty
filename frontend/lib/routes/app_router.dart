import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/accept_invite_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/properties/properties_screen.dart';
import '../screens/tenants/tenants_screen.dart';
import '../screens/payments/payments_screen.dart';
import '../screens/maintenance/maintenance_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoginRoute =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';
        final isPublicRoute =
            isLoginRoute || state.matchedLocation.startsWith('/invite/accept');

        if (!isAuthenticated && !isPublicRoute) {
          return '/login';
        }

        if (isAuthenticated && isLoginRoute) {
          return '/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/invite/accept/:token',
          builder: (context, state) =>
              AcceptInviteScreen(token: state.pathParameters['token'] ?? ''),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/properties',
          builder: (context, state) => const PropertiesScreen(),
        ),
        GoRoute(
          path: '/tenants',
          builder: (context, state) => const TenantsScreen(),
        ),
        GoRoute(
          path: '/payments',
          builder: (context, state) => const PaymentsScreen(),
        ),
        GoRoute(
          path: '/maintenance',
          builder: (context, state) => const MaintenanceScreen(),
        ),
      ],
    );
  }
}
