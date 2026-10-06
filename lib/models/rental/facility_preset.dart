import 'package:flutter/material.dart';
import '../../core/services/language_service.dart';

class FacilityPreset {
  final int id;
  final String code;
  final String nameKm;
  final String nameEn;
  final IconData icon;

  const FacilityPreset({
    required this.id,
    required this.code,
    required this.nameKm,
    required this.nameEn,
    required this.icon,
  });

  String get displayName => LanguageService.isKhmer ? nameKm : nameEn;
}

const List<FacilityPreset> kAllFacilityPresets = [
  FacilityPreset(
    id: 1,
    code: 'WIFI',
    nameKm: 'អ៊ីនធឺណិត (WiFi)',
    nameEn: 'Wi-Fi Internet',
    icon: Icons.wifi,
  ),
  FacilityPreset(
    id: 2,
    code: 'AIR_CONDITIONER',
    nameKm: 'ម៉ាស៊ីនត្រជាក់ (AC)',
    nameEn: 'Air Conditioner',
    icon: Icons.ac_unit,
  ),
  FacilityPreset(
    id: 3,
    code: 'PRIVATE_BATHROOM',
    nameKm: 'បន្ទប់ទឹកផ្ទាល់ខ្លួន',
    nameEn: 'Private Bathroom',
    icon: Icons.bathtub_outlined,
  ),
  FacilityPreset(
    id: 4,
    code: 'PARKING',
    nameKm: 'កន្លែងចតយានយន្ត',
    nameEn: 'Parking Space',
    icon: Icons.local_parking,
  ),
  FacilityPreset(
    id: 5,
    code: 'KITCHEN',
    nameKm: 'ចង្ក្រានបាយ',
    nameEn: 'Kitchen',
    icon: Icons.kitchen,
  ),
  FacilityPreset(
    id: 6,
    code: 'WASHING_MACHINE',
    nameKm: 'ម៉ាស៊ីនបោកគក់',
    nameEn: 'Washing Machine',
    icon: Icons.local_laundry_service,
  ),
  FacilityPreset(
    id: 7,
    code: 'SECURITY',
    nameKm: 'សន្តិសុខ / CCTV',
    nameEn: '24/7 Security',
    icon: Icons.shield_outlined,
  ),
  FacilityPreset(
    id: 8,
    code: 'FURNITURE',
    nameKm: 'គ្រឿងសង្ហារិម',
    nameEn: 'Furnished',
    icon: Icons.chair_outlined,
  ),
];
