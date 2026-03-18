import 'dart:io';
import '../../models/property_model.dart';
import '../../models/room_model.dart';

abstract class IPropertyService {
  Stream<List<PropertyModel>> streamProperties(String landlordId);
  Future<void> saveProperty(PropertyModel property);
  Future<void> deleteProperty(String propertyId);

  Stream<List<RoomModel>> streamRooms(String propertyId);
  Future<void> saveRoom(RoomModel room);
  Future<void> deleteRoom(String roomId);

  Future<List<String>> uploadRoomImages(List<File> files, String roomId);
}
