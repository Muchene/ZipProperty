import 'dart:convert';

enum TenantStatus { active, inactive, pending, terminated }

class Tenant {
  final String id;
  final String userId;
  final String propertyId;
  final String? unitNumber;
  final DateTime leaseStartDate;
  final DateTime leaseEndDate;
  final double monthlyRent;
  final double securityDeposit;
  final TenantStatus status;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tenant({
    required this.id,
    required this.userId,
    required this.propertyId,
    this.unitNumber,
    required this.leaseStartDate,
    required this.leaseEndDate,
    required this.monthlyRent,
    required this.securityDeposit,
    required this.status,
    this.emergencyContactName,
    this.emergencyContactPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      propertyId: map['property_id'] ?? '',
      unitNumber: map['unit_number'],
      leaseStartDate: DateTime.parse(map['lease_start_date']),
      leaseEndDate: DateTime.parse(map['lease_end_date']),
      monthlyRent: (map['monthly_rent'] ?? 0).toDouble(),
      securityDeposit: (map['security_deposit'] ?? 0).toDouble(),
      status: TenantStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TenantStatus.pending,
      ),
      emergencyContactName: map['emergency_contact_name'],
      emergencyContactPhone: map['emergency_contact_phone'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  factory Tenant.fromJson(String source) => Tenant.fromMap(json.decode(source));

  bool get isActive => status == TenantStatus.active;
}

class AssignTenantRequest {
  final String email;
  final String? name;
  final String propertyId;
  final String? unitNumber;
  final DateTime leaseStartDate;
  final DateTime leaseEndDate;
  final double monthlyRent;
  final double securityDeposit;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  AssignTenantRequest({
    required this.email,
    this.name,
    required this.propertyId,
    this.unitNumber,
    required this.leaseStartDate,
    required this.leaseEndDate,
    required this.monthlyRent,
    required this.securityDeposit,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  Map<String, dynamic> toMap() => {
    'email': email,
    if (name != null) 'name': name,
    'property_id': propertyId,
    if (unitNumber != null) 'unit_number': unitNumber,
    'lease_start_date': leaseStartDate.toIso8601String(),
    'lease_end_date': leaseEndDate.toIso8601String(),
    'monthly_rent': monthlyRent,
    'security_deposit': securityDeposit,
    if (emergencyContactName != null)
      'emergency_contact_name': emergencyContactName,
    if (emergencyContactPhone != null)
      'emergency_contact_phone': emergencyContactPhone,
  };
}

class AssignTenantResponse {
  final String tenantId;
  final String userId;
  final String propertyId;
  final bool inviteSent;

  AssignTenantResponse({
    required this.tenantId,
    required this.userId,
    required this.propertyId,
    required this.inviteSent,
  });

  factory AssignTenantResponse.fromMap(Map<String, dynamic> map) =>
      AssignTenantResponse(
        tenantId: map['tenant_id'] ?? '',
        userId: map['user_id'] ?? '',
        propertyId: map['property_id'] ?? '',
        inviteSent: map['invite_sent'] ?? false,
      );
}

class BillingSummary {
  final String ownerId;
  final int billableUsers;
  final int activeAgents;
  final int activeTenants;

  BillingSummary({
    required this.ownerId,
    required this.billableUsers,
    required this.activeAgents,
    required this.activeTenants,
  });

  factory BillingSummary.fromMap(Map<String, dynamic> map) => BillingSummary(
    ownerId: map['owner_id'] ?? '',
    billableUsers: map['billable_users'] ?? 0,
    activeAgents: map['active_agents'] ?? 0,
    activeTenants: map['active_tenants'] ?? 0,
  );
}
