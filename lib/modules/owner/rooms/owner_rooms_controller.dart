import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/rental/room_model.dart';
import '../../../models/rental/facility_model.dart';

class OwnerRoomsController extends GetxController {
  final rooms = <RoomModel>[
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
  ].obs;

  final selectedFilter = "ALL".obs; // ALL, AVAILABLE, OCCUPIED
  final searchQuery = "".obs;

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

  void addRoom({required String number, required int floor, double price = 50.0, String? desc}) {
    rooms.add(RoomModel(
      id: rooms.length + 1,
      roomNumber: number,
      floor: floor,
      price: price,
      roomType: "SINGLE",
      available: true,
      description: desc,
      facilities: [FacilityModel(name: "WIFI"), FacilityModel(name: "AIR_CONDITIONER")],
    ));
    Get.snackbar("Success", "បានបន្ថែមបន្ទប់ $number ជោគជ័យ! Room added.", backgroundColor: Colors.green.shade50);
  }

  void toggleAvailability(RoomModel room) {
    final idx = rooms.indexWhere((r) => r.id == room.id);
    if (idx != -1) {
      rooms[idx] = RoomModel(
        id: room.id,
        roomNumber: room.roomNumber,
        floor: room.floor,
        price: room.price,
        roomType: room.roomType,
        available: !(room.available ?? true),
        description: room.description,
        facilities: room.facilities,
      );
      Get.snackbar("Updated", "បន្ទប់ ${room.roomNumber} ត្រូវបានផ្លាស់ប្តូរស្ថានភាព", backgroundColor: Colors.white);
    }
  }

  void deleteRoom(RoomModel room) {
    rooms.removeWhere((r) => r.id == room.id);
    Get.snackbar("Deleted", "បន្ទប់ ${room.roomNumber} ត្រូវបានលុប", backgroundColor: Colors.white);
  }
}
