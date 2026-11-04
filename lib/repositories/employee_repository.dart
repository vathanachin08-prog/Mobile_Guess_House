import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  EmployeeRepositoryImpl({required this.apiService});

  @override
  Future<List<EmployeeModel>> getEmployees() async {
    final response = await apiService.getApi(ConstantUri.employees);
    if (response == null) {
      throw Exception("Unable to connect to server at ${ConstantUri.baseUri}. Please verify the backend is running and the Server URL is set properly.");
    }

    final decoded = response is String ? jsonDecode(response) : response;
    List<dynamic>? rawList;

    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is List) {
        rawList = decoded['data'];
      } else if (decoded['content'] is List) {
        rawList = decoded['content'];
      } else if (decoded['message'] != null && decoded['code'] != 'SUC-000' && decoded['code'] != '200') {
        throw Exception(decoded['message'].toString());
      }
    }

    if (rawList != null) {
      return rawList.map((item) => EmployeeModel.fromJson(Map<String, dynamic>.from(item))).toList();
    }

    return [];
  }

  @override
  Future<EmployeeModel?> getEmployeeById(dynamic id) async {
    final response = await apiService.getApi(ConstantUri.employeeDetail(id));
    if (response == null) {
      throw Exception("Unable to connect to server at ${ConstantUri.baseUri}");
    }

    final decoded = response is String ? jsonDecode(response) : response;
    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] != null) {
        return EmployeeModel.fromJson(Map<String, dynamic>.from(decoded['data']));
      }
      return EmployeeModel.fromJson(decoded);
    }
    return null;
  }

  @override
  Future<EmployeeModel> createEmployee(EmployeeModel employee) async {
    final body = employee.toJson();
    final response = await apiService.postApi(ConstantUri.employees, body: body);
    if (response == null) {
      throw Exception("Failed to reach server at ${ConstantUri.baseUri}");
    }

    final decoded = response is String ? jsonDecode(response) : response;
    if (decoded is Map<String, dynamic>) {
      // Check if server returned an error
      if (decoded['code'] != null && decoded['code'] != 'SUC-000' && decoded['code'] != '200' && decoded['data'] == null) {
        throw Exception(decoded['message'] ?? 'Failed to create employee');
      }
      if (decoded['data'] != null) {
        return EmployeeModel.fromJson(Map<String, dynamic>.from(decoded['data']));
      }
      return EmployeeModel.fromJson(decoded);
    }

    return employee;
  }

  @override
  Future<EmployeeModel> updateEmployee(dynamic id, EmployeeModel employee) async {
    final body = employee.toJson();
    final response = await apiService.putApi(ConstantUri.employeeDetail(id), body: body);
    if (response == null) {
      throw Exception("Failed to reach server at ${ConstantUri.baseUri}");
    }

    final decoded = response is String ? jsonDecode(response) : response;
    if (decoded is Map<String, dynamic>) {
      if (decoded['code'] != null && decoded['code'] != 'SUC-000' && decoded['code'] != '200' && decoded['data'] == null) {
        throw Exception(decoded['message'] ?? 'Failed to update employee');
      }
      if (decoded['data'] != null) {
        return EmployeeModel.fromJson(Map<String, dynamic>.from(decoded['data']));
      }
      return EmployeeModel.fromJson(decoded);
    }

    return employee;
  }

  @override
  Future<bool> deleteEmployee(dynamic id) async {
    final response = await apiService.deleteApi(ConstantUri.employeeDetail(id));
    if (response == null) {
      throw Exception("Failed to reach server at ${ConstantUri.baseUri}");
    }

    final decoded = response is String ? jsonDecode(response) : response;
    if (decoded is Map<String, dynamic>) {
      if (decoded['code'] != null && decoded['code'] != 'SUC-000' && decoded['code'] != '200' && decoded['status'] == 500) {
        throw Exception(decoded['message'] ?? 'Failed to delete employee');
      }
    }

    return true;
  }
}
