import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../models/rental/room_model.dart';
import '../../../models/rental/facility_model.dart';
import '../floors/owner_floors_controller.dart';

class OwnerRoomsController extends GetxController {
  final ApiService? apiService;
  final _storage = GetStorage();
  static const String _storageKey = "OWNER_ROOMS_PERSIST_KEY";

  final rooms = <RoomModel>[].obs;
  final selectedFilter = "ALL".obs; // ALL, AVAILABLE, OCCUPIED
  final searchQuery = "".obs;
  final selectedPropertyId = 1.obs;
  final isLoading = false.obs;

  OwnerRoomsController({this.apiService});

  @override
  void onInit() {
    super.onInit();
    loadRooms();
  }

  Future<void> loadRooms() async {
    // 1. Instant load from local storage
    _loadFromCache();

    // 2. Fetch fresh rooms from backend API if available
    if (apiService != null) {
      isLoading.value = true;
      try {
        final res = await apiService!.getApi(ConstantUri.propertyRooms(selectedPropertyId.value));
        if (res != null) {
          final decoded = res is Map ? res : jsonDecode(res.toString());
          final data = decoded['data'];
          if (data is List && data.isNotEmpty) {
            rooms.value = data
                .map((item) => RoomModel.fromJson(Map<String, dynamic>.from(item)))
                .toList();
            _saveRooms();
          }
        }
      } catch (e) {
        // Retain cached data on network error
      } finally {
        isLoading.value = false;
      }
    }
  }

  void _loadFromCache() {
    final stored = _storage.read(_storageKey);
    if (stored is List && stored.isNotEmpty) {
      try {
        rooms.value = stored
            .map((item) => RoomModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        return;
      } catch (e) {
        // Fallback to defaults
      }
    }

    // Default initial rooms from reference UI
    rooms.value = [
      RoomModel(
        id: 1,
        roomNumber: "00001",
        floor: 1,
        price: 50.0,
        roomType: "SINGLE",
        available: false,
        title: "បន្ទប់ជួលជាន់ទី១",
        facilities: [FacilityModel(name: "WIFI"), FacilityModel(name: "AIR_CONDITIONER")],
      ),
      RoomModel(
        id: 2,
        roomNumber: "00002",
        floor: 1,
        price: 50.0,
        roomType: "SINGLE",
        available: true,
        title: "បន្ទប់ទំនេរជាន់ទី១",
        facilities: [FacilityModel(name: "WIFI")],
      ),
      RoomModel(
        id: 3,
        roomNumber: "00003",
        floor: 2,
        price: 65.0,
        roomType: "DOUBLE",
        available: true,
        title: "បន្ទប់ធំជាន់ទី២",
        facilities: [FacilityModel(name: "WIFI"), FacilityModel(name: "PRIVATE_BATHROOM")],
      ),
      RoomModel(
        id: 4,
        roomNumber: "00004",
        floor: 2,
        price: 65.0,
        roomType: "DOUBLE",
        available: true,
        title: "បន្ទប់មានយ៉ជាន់ទី២",
        facilities: [FacilityModel(name: "WIFI"), FacilityModel(name: "AIR_CONDITIONER")],
      ),
      RoomModel(
        id: 5,
        roomNumber: "00005",
        floor: 2,
        price: 65.0,
        roomType: "DOUBLE",
        available: true,
        title: "បន្ទប់ជាន់ទី២",
        facilities: [FacilityModel(name: "WIFI")],
      ),
    ];
    _saveRooms();
  }

  void _saveRooms() {
    _storage.write(_storageKey, rooms.map((r) => r.toJson()).toList());
  }

  List<RoomModel> get filteredRooms {
    return rooms.where((r) {
      if (selectedFilter.value == "AVAILABLE" && r.available != true) return false;
      if (selectedFilter.value == "OCCUPIED" && r.available != false) return false;
      if (searchQuery.value.isNotEmpty) {
        return (r.roomNumber ?? '').toLowerCase().contains(searchQuery.value.toLowerCase());
      }
      return true;
    }).toList();
  }

  Future<void> addRoom({required String number, required int floor, double price = 50.0, String? desc}) async {
    AppFirebaseService.logAddRoomForm(
      roomNumber: number,
      floor: floor,
      price: price,
      success: true,
    );
    final optimisticRoom = RoomModel(
      id: rooms.length + 1,
      roomNumber: number,
      floor: floor,
      price: price,
      roomType: "SINGLE",
      available: true,
      description: desc,
      facilities: [FacilityModel(name: "WIFI"), FacilityModel(name: "AIR_CONDITIONER")],
    );

    rooms.add(optimisticRoom);
    _saveRooms();
    Get.snackbar("Success", "បានបន្ថែមបន្ទប់ $number ជោគជ័យ! Room added.", backgroundColor: Colors.green.shade50);

    // Save to PostgreSQL Backend API
    if (apiService != null) {
      try {
        final res = await apiService!.postApi(
          ConstantUri.propertyRooms(selectedPropertyId.value),
          body: {
            'roomNumber': number,
            'title': 'បន្ទប់ $number',
            'description': desc ?? '',
            'price': price,
            'floor': floor,
            'roomType': 'SINGLE',
            'available': true,
          },
        );
        if (res != null) {
          final decoded = res is Map ? res : jsonDecode(res.toString());
          final data = decoded['data'];
          if (data != null) {
            final serverRoom = RoomModel.fromJson(Map<String, dynamic>.from(data));
            final idx = rooms.indexOf(optimisticRoom);
            if (idx != -1) {
              rooms[idx] = serverRoom;
              _saveRooms();
            }
          }
        }
      } catch (_) {}
    }

    // Refresh floors count dynamically
    if (Get.isRegistered<OwnerFloorsController>()) {
      Get.find<OwnerFloorsController>().loadFloors();
    }
  }

  Future<void> toggleAvailability(RoomModel room) async {
    final idx = rooms.indexWhere((r) => r.id == room.id);
    if (idx != -1) {
      final newAvail = !(room.available ?? true);
      rooms[idx] = RoomModel(
        id: room.id,
        roomNumber: room.roomNumber,
        floor: room.floor,
        price: room.price,
        roomType: room.roomType,
        available: newAvail,
        description: room.description,
        facilities: room.facilities,
      );
      _saveRooms();
      Get.snackbar("Updated", "បន្ទប់ ${room.roomNumber} ត្រូវបានផ្លាស់ប្តូរស្ថានភាព", backgroundColor: Colors.white);

      if (Get.isRegistered<OwnerFloorsController>()) {
        Get.find<OwnerFloorsController>().loadFloors();
      }
    }
  }

  Future<void> deleteRoom(RoomModel room) async {
    rooms.removeWhere((r) => r.id == room.id);
    _saveRooms();
    Get.snackbar("Deleted", "បន្ទប់ ${room.roomNumber} ត្រូវបានលុប", backgroundColor: Colors.white);

    if (apiService != null && room.id != null) {
      try {
        await apiService!.deleteApi(ConstantUri.roomDetail(room.id));
      } catch (_) {}
    }

    if (Get.isRegistered<OwnerFloorsController>()) {
      Get.find<OwnerFloorsController>().loadFloors();
    }
  }
}
