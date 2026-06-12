import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tenant_provider.dart';

/// Shows the owner billing summary card. Safe to include on any owner screen;
/// loads data on first build and is a no-op for non-owners.
class BillingSummaryCard extends StatefulWidget {
  const BillingSummaryCard({super.key});

  @override
  State<BillingSummaryCard> createState() => _BillingSummaryCardState();
}

class _BillingSummaryCardState extends State<BillingSummaryCard> {
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user?.role == UserRole.owner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TenantProvider>().loadBillingSummary();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user?.role != UserRole.owner) return const SizedBox.shrink();

    return Consumer<TenantProvider>(
      builder: (context, provider, _) {
        final summary = provider.billingSummary;
        if (summary == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Billing Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: 'Refresh',
                      onPressed: provider.loadBillingSummary,
                    ),
                  ],
                ),
                const Divider(),
                _StatRow(
                  icon: Icons.people,
                  label: 'Billable Users',
                  value: summary.billableUsers.toString(),
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 8),
                _StatRow(
                  icon: Icons.person_pin,
                  label: 'Active Agents',
                  value: summary.activeAgents.toString(),
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                _StatRow(
                  icon: Icons.home,
                  label: 'Active Tenants',
                  value: summary.activeTenants.toString(),
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You are billed for ${summary.billableUsers} active user(s) across your properties. '
                          'Pending invites are not counted until accepted.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
