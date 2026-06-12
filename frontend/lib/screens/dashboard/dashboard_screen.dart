import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/billing_summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          authProvider.user?.name
                                  .substring(0, 1)
                                  .toUpperCase() ??
                              'U',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(authProvider.user?.name ?? 'User'),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Logout'),
                    onTap: () async {
                      await authProvider.logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          if (user == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message
                Text(
                  'Welcome back, ${user.name}!',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Role: ${user.role.name.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Quick stats cards
                _buildStatsSection(context, user.role),
                const SizedBox(height: 32),

                // Billing summary (owners only)
                const BillingSummaryCard(),
                if (user.role == UserRole.owner) const SizedBox(height: 32),

                // Quick actions
                _buildQuickActionsSection(context, user.role),
                const SizedBox(height: 32),

                // Recent activity (placeholder)
                _buildRecentActivitySection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, UserRole role) {
    List<_StatCard> stats = [];

    switch (role) {
      case UserRole.member:
        stats = [
          _StatCard(
            title: 'Create a property to become an owner',
            value: '',
            icon: Icons.add_business,
          ),
        ];
        break;
      case UserRole.owner:
        stats = [
          _StatCard(
            title: 'Total Properties',
            value: '0',
            icon: Icons.business,
          ),
          _StatCard(title: 'Active Tenants', value: '0', icon: Icons.people),
          _StatCard(
            title: 'Monthly Revenue',
            value: '\$0',
            icon: Icons.attach_money,
          ),
          _StatCard(
            title: 'Pending Maintenance',
            value: '0',
            icon: Icons.build,
          ),
        ];
        break;
      case UserRole.agent:
        stats = [
          _StatCard(
            title: 'Managed Properties',
            value: '0',
            icon: Icons.business,
          ),
          _StatCard(title: 'Active Tenants', value: '0', icon: Icons.people),
          _StatCard(title: 'Pending Tasks', value: '0', icon: Icons.task),
          _StatCard(
            title: 'This Month Collection',
            value: '\$0',
            icon: Icons.attach_money,
          ),
        ];
        break;
      case UserRole.tenant:
        stats = [
          _StatCard(title: 'Current Rent', value: '\$0', icon: Icons.home),
          _StatCard(
            title: 'Next Payment',
            value: 'N/A',
            icon: Icons.calendar_today,
          ),
          _StatCard(
            title: 'Maintenance Requests',
            value: '0',
            icon: Icons.build,
          ),
          _StatCard(title: 'Payment History', value: '0', icon: Icons.history),
        ];
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      stat.icon,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                    const Spacer(),
                    Text(
                      stat.value,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      stat.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, UserRole role) {
    List<_QuickAction> actions = [];

    switch (role) {
      case UserRole.member:
        actions = [
          _QuickAction(
            title: 'Create a Property',
            icon: Icons.add_business,
            onTap: () => context.go('/properties'),
          ),
        ];
        break;
      case UserRole.owner:
        actions = [
          _QuickAction(
            title: 'Manage Properties',
            icon: Icons.business,
            onTap: () => context.go('/properties'),
          ),
          _QuickAction(
            title: 'View Tenants',
            icon: Icons.people,
            onTap: () => context.go('/tenants'),
          ),
          _QuickAction(
            title: 'Payment Records',
            icon: Icons.payment,
            onTap: () => context.go('/payments'),
          ),
          _QuickAction(
            title: 'Maintenance Requests',
            icon: Icons.build,
            onTap: () => context.go('/maintenance'),
          ),
        ];
        break;
      case UserRole.agent:
        actions = [
          _QuickAction(
            title: 'Assigned Properties',
            icon: Icons.business,
            onTap: () => context.go('/properties'),
          ),
          _QuickAction(
            title: 'Manage Tenants',
            icon: Icons.people,
            onTap: () => context.go('/tenants'),
          ),
          _QuickAction(
            title: 'Collect Payments',
            icon: Icons.payment,
            onTap: () => context.go('/payments'),
          ),
          _QuickAction(
            title: 'Handle Maintenance',
            icon: Icons.build,
            onTap: () => context.go('/maintenance'),
          ),
        ];
        break;
      case UserRole.tenant:
        actions = [
          _QuickAction(
            title: 'Make Payment',
            icon: Icons.payment,
            onTap: () => context.go('/payments'),
          ),
          _QuickAction(
            title: 'Request Maintenance',
            icon: Icons.build,
            onTap: () => context.go('/maintenance'),
          ),
          _QuickAction(
            title: 'Payment History',
            icon: Icons.history,
            onTap: () => context.go('/payments'),
          ),
          _QuickAction(
            title: 'Contact Manager',
            icon: Icons.message,
            onTap: () {
              // TODO: Implement contact functionality
            },
          ),
        ];
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return Card(
              child: InkWell(
                onTap: action.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        action.icon,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          action.title,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.timeline,
                  size: 48,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No recent activity',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Activity will appear here as you use the system',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard {
  final String title;
  final String value;
  final IconData icon;

  _StatCard({required this.title, required this.value, required this.icon});
}

class _QuickAction {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _QuickAction({required this.title, required this.icon, required this.onTap});
}
