import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/property_model.dart';
import '../models/room_model.dart';
import '../core/interfaces/i_property_service.dart';
import 'local_db_service.dart';

class PropertyService implements IPropertyService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _local = LocalDbService();

  // ── PROPERTIES ────────────────────────────────────────────────

  Future<List<PropertyModel>> getProperties(String landlordId) async {
    // Đọc từ SQLite trước
    final rows = await _local.getAll('properties',
        where: 'landlord_id = ?', whereArgs: [landlordId]);
    if (rows.isNotEmpty) {
      return rows.map((r) => PropertyModel.fromSqlite(r)).toList();
    }
    // Fallback: pull từ Firestore
    final snap = await _db.collection('properties')
        .where('landlord_id', isEqualTo: landlordId).get();
    final list = snap.docs.map((d) => PropertyModel.fromFirestore(d)).toList();
    for (final p in list) {
      await _local.upsert('properties', p.toSqlite());
    }
    return list;
  }

  Stream<List<PropertyModel>> streamProperties(String landlordId) {
    return _db.collection('properties')
        .where('landlord_id', isEqualTo: landlordId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PropertyModel.fromFirestore(d)).toList());
  }

  Future<void> saveProperty(PropertyModel property) async {
    // Lưu SQLite trước (is_synced=0)
    final map = property.toSqlite();
    map['is_synced'] = 0;
    await _local.upsert('properties', map);
    // Sync Firestore
    await _db.collection('properties')
        .doc(property.id)
        .set(property.toFirestore(), SetOptions(merge: true));
    await _local.markSynced('properties', property.id);
  }

  Future<void> deleteProperty(String propertyId) async {
    await _local.delete('properties', propertyId);
    await _db.collection('properties').doc(propertyId).delete();
  }

  // ── ROOMS ─────────────────────────────────────────────────────

  Stream<List<RoomModel>> streamRooms(String propertyId) {
    return _db.collection('rooms')
        .where('property_id', isEqualTo: propertyId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => RoomModel.fromFirestore(d)).toList()
          ..sort((a, b) => a.roomNumber.compareTo(b.roomNumber)));
  }

  Future<void> saveRoom(RoomModel room) async {
    final map = room.toSqlite();
    map['is_synced'] = 0;
    await _local.upsert('rooms', map);
    await _db.collection('rooms')
        .doc(room.id)
        .set(room.toFirestore(), SetOptions(merge: true));
    await _local.markSynced('rooms', room.id);
  }

  Future<void> deleteRoom(String roomId) async {
    await _local.delete('rooms', roomId);
    await _db.collection('rooms').doc(roomId).delete();
  }

  // ── UPLOAD ẢNH ────────────────────────────────────────────────

  Future<String> uploadImage(File file, String path) async {
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<List<String>> uploadRoomImages(List<File> files, String roomId) async {
    final urls = <String>[];
    for (int i = 0; i < files.length; i++) {
      final url = await uploadImage(
          files[i], 'rooms/$roomId/image_$i.jpg');
      urls.add(url);
    }
    return urls;
  }
}
