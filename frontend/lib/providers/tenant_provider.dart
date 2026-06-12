import 'package:flutter/foundation.dart';
import '../models/tenant.dart';
import '../services/tenant_service.dart';

class TenantProvider extends ChangeNotifier {
  final TenantService _service = TenantService();

  List<Tenant> _tenants = [];
  BillingSummary? _billingSummary;
  bool _isLoading = false;
  String? _error;

  List<Tenant> get tenants => _tenants;
  BillingSummary? get billingSummary => _billingSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTenants() async {
    _setLoading(true);
    _clearError();
    try {
      _tenants = await _service.listTenants();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<AssignTenantResponse?> assignTenant(
    AssignTenantRequest request,
  ) async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _service.assignTenant(request);
      await loadTenants();
      return result;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  Future<void> loadBillingSummary() async {
    _clearError();
    try {
      _billingSummary = await _service.getBillingSummary();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
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
