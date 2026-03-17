import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/property_model.dart';
import '../models/room_model.dart';
import '../services/property_service.dart';

class PropertyProvider extends ChangeNotifier {
  final _service = PropertyService();

  List<PropertyModel> _properties = [];
  List<RoomModel> _rooms = [];
  bool isLoading = false;
  String? error;

  List<PropertyModel> get properties => _properties;
  List<RoomModel> get rooms => _rooms;

  void listenProperties(String landlordId) {
    _service.streamProperties(landlordId).listen((list) {
      _properties = list;
      notifyListeners();
    }, onError: (e) {
      error = e.toString();
      notifyListeners();
    });
  }

  void listenRooms(String propertyId) {
    _service.streamRooms(propertyId).listen((list) {
      _rooms = list;
      notifyListeners();
    });
  }

  Future<void> addProperty({
    required String landlordId,
    required String name,
    required String address,
    required String ward,
    required String district,
    required String city,
    String? description,
  }) async {
    final now = DateTime.now();
    final property = PropertyModel(
      id: const Uuid().v4(),
      landlordId: landlordId,
      name: name,
      address: address,
      ward: ward,
      district: district,
      city: city,
      description: description,
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );
    await _service.saveProperty(property);
  }

  Future<void> updateProperty(PropertyModel property) async {
    await _service.saveProperty(property);
  }

  Future<void> deleteProperty(String propertyId) async {
    await _service.deleteProperty(propertyId);
  }

  Future<void> addRoom({
    required String propertyId,
    required String roomNumber,
    required int floor,
    required double areaSqm,
    required double basePrice,
    required double depositAmount,
    String? description,
    List<File> imageFiles = const [],
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final roomId = const Uuid().v4();
      List<String> imageUrls = [];
      if (imageFiles.isNotEmpty) {
        imageUrls = await _service.uploadRoomImages(imageFiles, roomId);
      }
      final now = DateTime.now();
      final room = RoomModel(
        id: roomId,
        propertyId: propertyId,
        roomNumber: roomNumber,
        floor: floor,
        areaSqm: areaSqm,
        basePrice: basePrice,
        depositAmount: depositAmount,
        description: description,
        images: imageUrls,
        status: 'vacant',
        createdAt: now,
        updatedAt: now,
      );
      await _service.saveRoom(room);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRoom(RoomModel room, {List<File> newImages = const []}) async {
    isLoading = true;
    notifyListeners();
    try {
      List<String> imageUrls = room.images;
      if (newImages.isNotEmpty) {
        final uploaded = await _service.uploadRoomImages(newImages, room.id);
        imageUrls = [...imageUrls, ...uploaded];
      }
      final updated = RoomModel(
        id: room.id,
        propertyId: room.propertyId,
        currentTenantId: room.currentTenantId,
        currentContractId: room.currentContractId,
        roomNumber: room.roomNumber,
        floor: room.floor,
        areaSqm: room.areaSqm,
        basePrice: room.basePrice,
        depositAmount: room.depositAmount,
        description: room.description,
        images: imageUrls,
        status: room.status,
        createdAt: room.createdAt,
        updatedAt: DateTime.now(),
      );
      await _service.saveRoom(updated);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRoom(String roomId) async {
    await _service.deleteRoom(roomId);
  }
}
