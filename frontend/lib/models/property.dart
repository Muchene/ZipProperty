import 'dart:convert';

enum PropertyType { apartment, house, condo, townhouse, commercial }

class Property {
  final String id;
  final String ownerId;
  final String? agentId;
  final String name;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final PropertyType propertyType;
  final int totalUnits;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Property({
    required this.id,
    required this.ownerId,
    this.agentId,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.propertyType,
    required this.totalUnits,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'] ?? '',
      ownerId: map['owner_id'] ?? '',
      agentId: map['agent_id'],
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zip_code'] ?? '',
      country: map['country'] ?? '',
      propertyType: PropertyType.values.firstWhere(
        (e) => e.name == map['property_type'],
        orElse: () => PropertyType.apartment,
      ),
      totalUnits: map['total_units'] ?? 1,
      description: map['description'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  factory Property.fromJson(String source) =>
      Property.fromMap(json.decode(source));
}

class CreatePropertyRequest {
  final String name;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final PropertyType propertyType;
  final int totalUnits;
  final String? description;

  CreatePropertyRequest({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.propertyType,
    required this.totalUnits,
    this.description,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'address': address,
    'city': city,
    'state': state,
    'zip_code': zipCode,
    'country': country,
    'property_type': propertyType.name,
    'total_units': totalUnits,
    if (description != null) 'description': description,
  };
}

class AssignAgentResponse {
  final String propertyId;
  final String userId;
  final bool inviteSent;

  AssignAgentResponse({
    required this.propertyId,
    required this.userId,
    required this.inviteSent,
  });

  factory AssignAgentResponse.fromMap(Map<String, dynamic> map) =>
      AssignAgentResponse(
        propertyId: map['property_id'] ?? '',
        userId: map['user_id'] ?? '',
        inviteSent: map['invite_sent'] ?? false,
      );
}

extension PropertyTypeExtension on PropertyType {
  String get displayName {
    switch (this) {
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.house:
        return 'House';
      case PropertyType.condo:
        return 'Condo';
      case PropertyType.townhouse:
        return 'Townhouse';
      case PropertyType.commercial:
        return 'Commercial';
    }
  }
}
