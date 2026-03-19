import 'dart:convert';

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
  const RoomListScreen(
      {super.key, required this.property, required this.landlordId});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().listenRooms(widget.property.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.property.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoomFormScreen(propertyId: widget.property.id),
          ),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm phòng', style: TextStyle(color: Colors.white)),
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, _) {
          final allRooms = provider.rooms;
          final filtered = _filterStatus == 'all'
              ? allRooms
              : allRooms.where((r) => r.status == _filterStatus).toList();

          return Column(
            children: [
              _StatsBar(
                total: allRooms.length,
                vacant: provider.vacantRooms,
                occupied: provider.occupiedRooms,
                maintenance:
                    allRooms.where((r) => r.status == 'maintenance').length,
              ),
              _FilterBar(
                selected: _filterStatus,
                onChanged: (v) => setState(() => _filterStatus = v),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.meeting_room_outlined,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              allRooms.isEmpty
                                  ? 'Chưa có phòng nào'
                                  : 'Không có phòng phù hợp',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _RoomCard(
                          room: filtered[i],
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoomFormScreen(
                                propertyId: widget.property.id,
                                room: filtered[i],
                              ),
                            ),
                          ),
                          onDelete: () =>
                              _confirmDelete(context, provider, filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, PropertyProvider provider, RoomModel room) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xoá phòng'),
        content: Text('Bạn chắc chắn muốn xoá phòng ${room.roomNumber}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huỷ')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteRoom(room.id, widget.property.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Đã xoá phòng ${room.roomNumber}')),
                );
              }
            },
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Stats Bar ────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final int total, vacant, occupied, maintenance;
  const _StatsBar(
      {required this.total,
      required this.vacant,
      required this.occupied,
      required this.maintenance});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _StatItem(label: 'Tổng', value: total, color: Colors.white),
          _StatItem(label: 'Trống', value: vacant, color: Colors.greenAccent),
          _StatItem(label: 'Có người', value: occupied, color: Colors.redAccent),
          _StatItem(label: 'Bảo trì', value: maintenance, color: Colors.orangeAccent),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Filter Bar ───────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('all', 'Tất cả'),
      ('vacant', 'Trống'),
      ('occupied', 'Có người'),
      ('maintenance', 'Bảo trì'),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = selected == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f.$2),
                selected: isSelected,
                onSelected: (_) => onChanged(f.$1),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.grey,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Room Card ────────────────────────────────────────────────────

class _RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoomCard({
    required this.room,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (room.status) {
      case 'occupied':
        return Colors.red;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String get _statusLabel {
    switch (room.status) {
      case 'occupied':
        return 'Có người';
      case 'maintenance':
        return 'Bảo trì';
      default:
        return 'Trống';
    }
  }

  Widget _imageFromSource(String source) {
    if (source.startsWith('data:image')) {
      try {
        final commaIndex = source.indexOf(',');
        if (commaIndex != -1) {
          final bytes = base64Decode(source.substring(commaIndex + 1));
          return Image.memory(
            bytes,
            width: 68,
            height: 68,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          );
        }
      } catch (_) {
        return _placeholder();
      }
      return _placeholder();
    }

    return Image.network(
      source,
      width: 68,
      height: 68,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: room.images.isNotEmpty
                    ? _imageFromSource(room.images.first)
                    : _placeholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('Phòng ${room.roomNumber}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 6),
                      Text('• Tầng ${room.floor}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(room.basePrice),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Row(children: [
                      if (room.areaSqm > 0) ...[
                        const Icon(Icons.square_foot,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text('${room.areaSqm.toStringAsFixed(0)}m²',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 10),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_statusLabel,
                            style: TextStyle(
                                fontSize: 11,
                                color: _statusColor,
                                fontWeight: FontWeight.bold)),
                      ),
                    ]),
                    if (room.description != null &&
                        room.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(room.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Chỉnh sửa'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Xoá', style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
                onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.meeting_room_outlined,
            color: AppColors.primary, size: 28),
      );
}
