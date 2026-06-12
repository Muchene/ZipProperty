import 'package:flutter/foundation.dart';
import '../models/property.dart';
import '../services/property_service.dart';

class PropertyProvider extends ChangeNotifier {
  final PropertyService _service = PropertyService();

  List<Property> _properties = [];
  bool _isLoading = false;
  String? _error;

  List<Property> get properties => _properties;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProperties() async {
    _setLoading(true);
    _clearError();
    try {
      _properties = await _service.listProperties();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<Property?> createProperty(CreatePropertyRequest request) async {
    _setLoading(true);
    _clearError();
    try {
      final property = await _service.createProperty(request);
      _properties.insert(0, property);
      notifyListeners();
      return property;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<AssignAgentResponse?> assignAgent(
    String propertyId,
    String email, {
    String? name,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _service.assignAgent(propertyId, email, name: name);
      _setLoading(false);
      return result;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
