import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/property.dart';
import '../../models/tenant.dart';
import '../../providers/property_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../theme/app_theme.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenantProvider>().loadTenants();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tenants')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssignTenantSheet(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Assign Tenant'),
      ),
      body: Consumer<TenantProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.tenants.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.tenants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: provider.loadTenants,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (provider.tenants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No tenants yet', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                    'Assign a tenant to one of your properties.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAssignTenantSheet(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Assign Tenant'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: provider.loadTenants,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: provider.tenants.length,
              itemBuilder: (context, index) {
                final t = provider.tenants[index];
                return _TenantCard(tenant: t);
              },
            ),
          );
        },
      ),
    );
  }

  void _showAssignTenantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AssignTenantSheet(),
    );
  }
}

class _TenantCard extends StatelessWidget {
  final Tenant tenant;

  const _TenantCard({required this.tenant});

  Color _statusColor(TenantStatus status) {
    switch (status) {
      case TenantStatus.active:
        return Colors.green;
      case TenantStatus.pending:
        return Colors.orange;
      case TenantStatus.terminated:
        return Colors.red;
      case TenantStatus.inactive:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(tenant.status).withValues(alpha: 0.15),
          child: Icon(Icons.person, color: _statusColor(tenant.status)),
        ),
        title: Text(
          tenant.unitNumber != null
              ? 'Unit ${tenant.unitNumber}'
              : 'No unit assigned',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rent: KES ${tenant.monthlyRent.toStringAsFixed(0)}/mo'),
            Text(
              'Lease: ${_fmtDate(tenant.leaseStartDate)} – ${_fmtDate(tenant.leaseEndDate)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            tenant.status.name.toUpperCase(),
            style: const TextStyle(fontSize: 11),
          ),
          backgroundColor: _statusColor(tenant.status).withValues(alpha: 0.1),
          side: BorderSide(color: _statusColor(tenant.status)),
        ),
        isThreeLine: true,
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _AssignTenantSheet extends StatefulWidget {
  const _AssignTenantSheet();

  @override
  State<_AssignTenantSheet> createState() => _AssignTenantSheetState();
}

class _AssignTenantSheetState extends State<_AssignTenantSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();

  Property? _selectedProperty;
  DateTime _leaseStart = DateTime.now();
  DateTime _leaseEnd = DateTime.now().add(const Duration(days: 365));

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _rentCtrl.dispose();
    _depositCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _leaseStart : _leaseEnd,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _leaseStart = picked;
        } else {
          _leaseEnd = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProperty == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a property')));
      return;
    }

    final provider = context.read<TenantProvider>();
    final result = await provider.assignTenant(
      AssignTenantRequest(
        email: _emailCtrl.text.trim(),
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        propertyId: _selectedProperty!.id,
        unitNumber: _unitCtrl.text.trim().isEmpty
            ? null
            : _unitCtrl.text.trim(),
        leaseStartDate: _leaseStart,
        leaseEndDate: _leaseEnd,
        monthlyRent: double.tryParse(_rentCtrl.text) ?? 0,
        securityDeposit: double.tryParse(_depositCtrl.text) ?? 0,
      ),
    );
    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pop();
      final msg = result.inviteSent
          ? 'Invite sent to ${_emailCtrl.text.trim()}.'
          : 'Tenant assigned successfully.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to assign tenant'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final properties = context.watch<PropertyProvider>().properties;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Assign Tenant',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              const Text(
                'If the tenant does not have an account, they will receive an invitation email.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Property>(
                initialValue: _selectedProperty,
                decoration: const InputDecoration(labelText: 'Property *'),
                items: properties
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedProperty = v),
                validator: (v) => v == null ? 'Select a property' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tenant Email *',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!RegExp(
                    r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(v)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tenant Name (optional)',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitCtrl,
                decoration: const InputDecoration(
                  labelText: 'Unit Number (optional)',
                  prefixIcon: Icon(Icons.door_front_door),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Monthly Rent (KES) *',
                        prefixIcon: Icon(Icons.payments),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _depositCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Deposit (KES)',
                        prefixIcon: Icon(Icons.security),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v != null &&
                            v.isNotEmpty &&
                            double.tryParse(v) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Lease Start',
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        '${_leaseStart.day}/${_leaseStart.month}/${_leaseStart.year}',
                      ),
                      onTap: () => _pickDate(isStart: true),
                      trailing: const Icon(Icons.calendar_today, size: 18),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Lease End',
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        '${_leaseEnd.day}/${_leaseEnd.month}/${_leaseEnd.year}',
                      ),
                      onTap: () => _pickDate(isStart: false),
                      trailing: const Icon(Icons.calendar_today, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Consumer<TenantProvider>(
                builder: (_, provider, __) => ElevatedButton(
                  onPressed: provider.isLoading ? null : _submit,
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Assign Tenant'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
