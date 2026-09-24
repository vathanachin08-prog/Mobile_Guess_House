import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';

class FloorItem {
  final int? id;
  final String name;
  final int totalRooms;
  final int occupiedRooms;
  final int? floorOrder;

  FloorItem({
    this.id,
    required this.name,
    this.totalRooms = 0,
    this.occupiedRooms = 0,
    this.floorOrder,
  });

  int get floorNumber {
    if (floorOrder != null && floorOrder! > 0) return floorOrder!;
    final khmerDigits = {'១': '1', '២': '2', '៣': '3', '៤': '4', '៥': '5', '៦': '6', '៧': '7', '៨': '8', '៩': '9', '០': '0'};
    String s = name;
    khmerDigits.forEach((k, v) => s = s.replaceAll(k, v));
    final match = RegExp(r'\d+').firstMatch(s);
    if (match != null) {
      return int.tryParse(match.group(0) ?? '') ?? 1;
    }
    return id ?? 1;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'totalRooms': totalRooms,
    'occupiedRooms': occupiedRooms,
    'floorOrder': floorOrder,
  };

  factory FloorItem.fromJson(Map<String, dynamic> json) => FloorItem(
    id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
    name: json['name']?.toString() ?? '',
    totalRooms: json['totalRooms'] is int ? json['totalRooms'] : int.tryParse(json['totalRooms']?.toString() ?? '0') ?? 0,
    occupiedRooms: json['occupiedRooms'] is int ? json['occupiedRooms'] : int.tryParse(json['occupiedRooms']?.toString() ?? '0') ?? 0,
    floorOrder: json['floorOrder'] is int ? json['floorOrder'] : int.tryParse(json['floorOrder']?.toString() ?? ''),
  );
}

class OwnerFloorsController extends GetxController {
  final ApiService apiService;
  final _storage = GetStorage();
  static const String _storageKey = "OWNER_FLOORS_PERSIST_KEY";

  OwnerFloorsController({required this.apiService});

  final floors = <FloorItem>[].obs;
  final searchQuery = "".obs;
  final isLoading = false.obs;
  final selectedPropertyId = 1.obs;

  @override
  void onInit() {
    super.onInit();
    loadFloors();
  }

  Future<void> loadFloors() async {
    // First load from local storage cache for instant UI rendering
    _loadFromCache();

    isLoading.value = true;
    try {
      final res = await apiService.getApi(ConstantUri.propertyFloors(selectedPropertyId.value));
      if (res != null) {
        final decoded = res is Map ? res : jsonDecode(res.toString());
        final data = decoded['data'];
        if (data is List && data.isNotEmpty) {
          floors.value = data.map((item) => FloorItem.fromJson(Map<String, dynamic>.from(item))).toList();
          _saveFloors();
        }
      }
    } catch (e) {
      // If server unreachable, retain cached local data
    } finally {
      isLoading.value = false;
    }
  }

  void _loadFromCache() {
    final stored = _storage.read(_storageKey);
    if (stored is List && stored.isNotEmpty) {
      try {
        floors.value = stored
            .map((item) => FloorItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        return;
      } catch (_) {}
    }

    if (floors.isEmpty) {
      floors.value = [
        FloorItem(name: "ជាន់ទី ៣", totalRooms: 0, occupiedRooms: 0),
        FloorItem(name: "ជាន់ទី ១", totalRooms: 2, occupiedRooms: 1),
        FloorItem(name: "ជាន់ទី ២", totalRooms: 3, occupiedRooms: 0),
      ];
      _saveFloors();
    }
  }

  void _saveFloors() {
    _storage.write(_storageKey, floors.map((f) => f.toJson()).toList());
  }

  List<FloorItem> get filteredFloors {
    if (searchQuery.value.isEmpty) return floors;
    return floors
        .where((f) => f.name.toLowerCase().contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  Future<void> addFloor(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    // Optimistically add to UI & cache immediately
    final optimisticFloor = FloorItem(name: trimmedName, totalRooms: 0, occupiedRooms: 0);
    floors.insert(0, optimisticFloor);
    _saveFloors();

    // Persist directly to Spring Boot PostgreSQL database
    try {
      final res = await apiService.postApi(
        ConstantUri.propertyFloors(selectedPropertyId.value),
        body: {'name': trimmedName, 'floorOrder': floors.length},
      );
      if (res != null) {
        final decoded = res is Map ? res : jsonDecode(res.toString());
        final data = decoded['data'];
        if (data != null) {
          // Replace with real database entity including generated ID
          final idx = floors.indexOf(optimisticFloor);
          if (idx != -1) {
            floors[idx] = FloorItem.fromJson(Map<String, dynamic>.from(data));
            _saveFloors();
          }
        }
      }
    } catch (e) {
      // Retained in cache even if network error
    }
  }

  Future<void> deleteFloor(int index) async {
    if (index >= 0 && index < floors.length) {
      final item = floors[index];
      floors.removeAt(index);
      _saveFloors();

      if (item.id != null) {
        try {
          await apiService.deleteApi(ConstantUri.deleteFloor(item.id));
        } catch (_) {}
      }
    }
  }
}
