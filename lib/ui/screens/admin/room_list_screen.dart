import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/property_model.dart';
import '../../../models/room_model.dart';
import '../../../providers/property_provider.dart';
import 'room_form_screen.dart';

class RoomListScreen extends StatefulWidget {
  final PropertyModel property;
  final String landlordId;
  const RoomListScreen({super.key, required this.property, required this.landlordId});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().listenRooms(widget.property.id);
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'occupied': return Colors.red;
      case 'maintenance': return Colors.orange;
      default: return Colors.green;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'occupied': return 'Có người';
      case 'maintenance': return 'Bảo trì';
      default: return 'Trống';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.property.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(widget.property.fullAddress,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => RoomFormScreen(propertyId: widget.property.id),
        )),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm phòng', style: TextStyle(color: Colors.white)),
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, _) {
          if (provider.rooms.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Chưa có phòng nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: provider.rooms.length,
            itemBuilder: (context, index) {
              final room = provider.rooms[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => RoomFormScreen(propertyId: widget.property.id, room: room),
                  )),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Ảnh phòng hoặc placeholder
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: room.images.isNotEmpty
                              ? Image.network(room.images.first, width: 64, height: 64, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _placeholder())
                              : _placeholder(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text('Phòng ${room.roomNumber}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(width: 8),
                                Text('Tầng ${room.floor}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ]),
                              const SizedBox(height: 4),
                              Text(currency.format(room.basePrice),
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Row(children: [
                                if (room.areaSqm > 0) ...[
                                  const Icon(Icons.square_foot, size: 14, color: Colors.grey),
                                  const SizedBox(width: 2),
                                  Text('${room.areaSqm.toInt()}m²',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _statusColor(room.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(_statusLabel(room.status),
                                      style: TextStyle(fontSize: 11,
                                          color: _statusColor(room.status),
                                          fontWeight: FontWeight.bold)),
                                ),
                              ]),
                            ],
                          ),
                        ),
                        PopupMenuButton(
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Sửa')])),
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Xoá', style: TextStyle(color: Colors.red))])),
                          ],
                          onSelected: (v) {
                            if (v == 'edit') {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => RoomFormScreen(propertyId: widget.property.id, room: room),
                              ));
                            } else {
                              _confirmDelete(context, provider, room);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 64, height: 64,
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.meeting_room, color: AppColors.primary),
  );

  void _confirmDelete(BuildContext context, PropertyProvider provider, RoomModel room) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá phòng'),
        content: Text('Bạn chắc chắn muốn xoá phòng ${room.roomNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteRoom(room.id);
            },
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
