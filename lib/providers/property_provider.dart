import 'dart:async';
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

  StreamSubscription? _propertiesSub;
  StreamSubscription? _roomsSub;
  String? _currentPropertyId;

  List<PropertyModel> get properties => _properties;
  List<RoomModel> get rooms => _rooms;

  int get totalRooms => _rooms.length;
  int get vacantRooms => _rooms.where((r) => r.status == 'vacant').length;
  int get occupiedRooms => _rooms.where((r) => r.status == 'occupied').length;

  void listenProperties(String landlordId) {
    _propertiesSub?.cancel();
    _propertiesSub = _service.streamProperties(landlordId).listen((list) {
      _properties = list;
      notifyListeners();
    }, onError: (e) {
      error = e.toString();
      notifyListeners();
    });
  }

  void listenRooms(String propertyId) {
    if (_currentPropertyId == propertyId) return; // tránh re-subscribe cùng property
    _roomsSub?.cancel();
    _currentPropertyId = propertyId;
    _rooms = [];
    _roomsSub = _service.streamRooms(propertyId).listen((list) {
      _rooms = list;
      notifyListeners();
    }, onError: (e) {
      error = e.toString();
      notifyListeners();
    });
  }

  void resetRooms() {
    _roomsSub?.cancel();
    _currentPropertyId = null;
    _rooms = [];
    notifyListeners();
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
      // Cập nhật totalRooms trên property
      final prop = _properties.firstWhere((p) => p.id == propertyId,
          orElse: () => throw Exception('Property not found'));
      await _service.saveProperty(prop.copyWith(
        totalRooms: prop.totalRooms + 1,
        updatedAt: now,
      ));
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
      await _service.saveRoom(room.copyWith(
        images: imageUrls,
        updatedAt: DateTime.now(),
      ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRoom(String roomId, String propertyId) async {
    await _service.deleteRoom(roomId);
    // Cập nhật totalRooms
    final propIndex = _properties.indexWhere((p) => p.id == propertyId);
    if (propIndex != -1) {
      final prop = _properties[propIndex];
      final newTotal = (prop.totalRooms - 1).clamp(0, 999);
      await _service.saveProperty(prop.copyWith(
        totalRooms: newTotal,
        updatedAt: DateTime.now(),
      ));
    }
  }

  @override
  void dispose() {
    _propertiesSub?.cancel();
    _roomsSub?.cancel();
    super.dispose();
  }
}
