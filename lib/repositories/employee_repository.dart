import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import '../constants/constant_uri.dart';
import '../core/services/api_service.dart';
import '../models/employee/employee_model.dart';

abstract class EmployeeRepository {
  Future<List<EmployeeModel>> getEmployees();
  Future<EmployeeModel?> getEmployeeById(dynamic id);
  Future<EmployeeModel> createEmployee(EmployeeModel employee);
  Future<EmployeeModel> updateEmployee(dynamic id, EmployeeModel employee);
  Future<bool> deleteEmployee(dynamic id);
}

class EmployeeRepositoryImpl implements EmployeeRepository {
  final ApiService apiService;
  final GetStorage _storage = GetStorage();
  static const String _localEmployeesKey = "CACHE_LOCAL_EMPLOYEES";

  EmployeeRepositoryImpl({required this.apiService});

  @override
  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final response = await apiService.getApi(ConstantUri.employees);
      if (response != null) {
        final decoded = response is String ? jsonDecode(response) : response;
        List<dynamic>? rawList;

        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is List) {
            rawList = decoded['data'];
          }
        }

        if (rawList != null && rawList.isNotEmpty) {
          final list = rawList.map((item) => EmployeeModel.fromJson(Map<String, dynamic>.from(item))).toList();
          _saveLocalEmployees(list);
          return list;
        }
      }
    } catch (e) {
      debugPrint("EmployeeRepository getEmployees error: $e");
    }

    // Return cached/seeded employees
    return _getLocalEmployees();
  }

  @override
  Future<EmployeeModel?> getEmployeeById(dynamic id) async {
    try {
      final response = await apiService.getApi(ConstantUri.employeeDetail(id));
      if (response != null) {
        final decoded = response is String ? jsonDecode(response) : response;
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'] ?? decoded;
          return EmployeeModel.fromJson(Map<String, dynamic>.from(data));
        }
      }
    } catch (e) {
      debugPrint("EmployeeRepository getEmployeeById error: $e");
    }

    final localList = _getLocalEmployees();
    try {
      return localList.firstWhere((e) => e.id.toString() == id.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<EmployeeModel> createEmployee(EmployeeModel employee) async {
    try {
      final body = employee.toJson();
      final response = await apiService.postApi(ConstantUri.employees, body: body);
      if (response != null) {
        final decoded = response is String ? jsonDecode(response) : response;
        if (decoded is Map<String, dynamic> && decoded['data'] != null) {
          final created = EmployeeModel.fromJson(Map<String, dynamic>.from(decoded['data']));
          _insertLocalEmployee(created);
          return created;
        }
      }
    } catch (e) {
      debugPrint("EmployeeRepository createEmployee error: $e");
    }

    // Local fallback creation
    final newId = DateTime.now().millisecondsSinceEpoch;
    final created = employee.copyWith(
      id: newId,
      status: 'ACT',
    );
    _insertLocalEmployee(created);
    return created;
  }

  @override
  Future<EmployeeModel> updateEmployee(dynamic id, EmployeeModel employee) async {
    try {
      final body = employee.toJson();
      final response = await apiService.putApi(ConstantUri.employeeDetail(id), body: body);
      if (response != null) {
        final decoded = response is String ? jsonDecode(response) : response;
        if (decoded is Map<String, dynamic> && decoded['data'] != null) {
          final updated = EmployeeModel.fromJson(Map<String, dynamic>.from(decoded['data']));
          _updateLocalEmployee(updated);
          return updated;
        }
      }
    } catch (e) {
      debugPrint("EmployeeRepository updateEmployee error: $e");
    }

    // Local fallback update
    _updateLocalEmployee(employee);
    return employee;
  }

  @override
  Future<bool> deleteEmployee(dynamic id) async {
    try {
      final response = await apiService.deleteApi(ConstantUri.employeeDetail(id));
      if (response != null) {
        _deleteLocalEmployee(id);
        return true;
      }
    } catch (e) {
      debugPrint("EmployeeRepository deleteEmployee error: $e");
    }

    // Local fallback delete
    _deleteLocalEmployee(id);
    return true;
  }

  // --- Local Cache Helpers ---

  List<EmployeeModel> _getLocalEmployees() {
    final raw = _storage.read(_localEmployeesKey);
    if (raw is List && raw.isNotEmpty) {
      return raw.map((item) => EmployeeModel.fromJson(Map<String, dynamic>.from(item))).toList();
    }
    final initial = _getInitialDummyEmployees();
    _saveLocalEmployees(initial);
    return initial;
  }

  void _saveLocalEmployees(List<EmployeeModel> list) {
    _storage.write(_localEmployeesKey, list.map((e) => e.toJson()).toList());
  }

  void _insertLocalEmployee(EmployeeModel employee) {
    final list = _getLocalEmployees();
    list.insert(0, employee);
    _saveLocalEmployees(list);
  }

  void _updateLocalEmployee(EmployeeModel employee) {
    final list = _getLocalEmployees();
    final idx = list.indexWhere((e) => e.id.toString() == employee.id.toString());
    if (idx != -1) {
      list[idx] = employee;
      _saveLocalEmployees(list);
    }
  }

  void _deleteLocalEmployee(dynamic id) {
    final list = _getLocalEmployees();
    list.removeWhere((e) => e.id.toString() == id.toString());
    _saveLocalEmployees(list);
  }

  List<EmployeeModel> _getInitialDummyEmployees() {
    return [
      EmployeeModel(
        id: 1,
        name: 'Sokha Chan',
        email: 'sokha.chan@company.com',
        phone: '012345678',
        position: 'Senior Fullstack Engineer',
        department: 'Engineering',
        salary: 2500.0,
        status: 'ACT',
      ),
      EmployeeModel(
        id: 2,
        name: 'Bopha Keo',
        email: 'bopha.keo@company.com',
        phone: '098765432',
        position: 'Lead UI/UX Designer',
        department: 'Design',
        salary: 1800.0,
        status: 'ACT',
      ),
      EmployeeModel(
        id: 3,
        name: 'Vicheka Heng',
        email: 'vicheka.heng@company.com',
        phone: '089112233',
        position: 'Backend Developer',
        department: 'Engineering',
        salary: 1600.0,
        status: 'ACT',
      ),
      EmployeeModel(
        id: 4,
        name: 'Dara Sam',
        email: 'dara.sam@company.com',
        phone: '077889900',
        position: 'Product Manager',
        department: 'Product',
        salary: 2200.0,
        status: 'ACT',
      ),
      EmployeeModel(
        id: 5,
        name: 'Leakhena Meas',
        email: 'leakhena.meas@company.com',
        phone: '011223344',
        position: 'QA Automation Engineer',
        department: 'Quality Assurance',
        salary: 1400.0,
        status: 'ACT',
      ),
      EmployeeModel(
        id: 6,
        name: 'Rathana Kim',
        email: 'rathana.kim@company.com',
        phone: '088776655',
        position: 'DevOps & Cloud Engineer',
        department: 'Infrastructure',
        salary: 2300.0,
        status: 'ACT',
      ),
    ];
  }
}

