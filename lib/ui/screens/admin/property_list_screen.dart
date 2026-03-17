import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/property_provider.dart';
import '../../../models/property_model.dart';
import 'property_form_screen.dart';
import 'room_list_screen.dart';

class PropertyListScreen extends StatefulWidget {
  final String landlordId;
  const PropertyListScreen({super.key, required this.landlordId});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().listenProperties(widget.landlordId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý tòa nhà', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => PropertyFormScreen(landlordId: widget.landlordId),
        )),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm tòa', style: TextStyle(color: Colors.white)),
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, _) {
          if (provider.properties.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.apartment_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Chưa có tòa nhà nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.properties.length,
            itemBuilder: (context, index) {
              final p = provider.properties[index];
              return _PropertyCard(
                property: p,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => RoomListScreen(property: p, landlordId: widget.landlordId),
                )),
                onEdit: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PropertyFormScreen(landlordId: widget.landlordId, property: p),
                )),
                onDelete: () => _confirmDelete(context, provider, p),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, PropertyProvider provider, PropertyModel p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá tòa nhà'),
        content: Text('Bạn chắc chắn muốn xoá "${p.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteProperty(p.id);
            },
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PropertyCard({required this.property, required this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.apartment, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(property.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(property.fullAddress, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: property.status == 'active' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          property.status == 'active' ? 'Hoạt động' : 'Tạm đóng',
                          style: TextStyle(
                            fontSize: 11,
                            color: property.status == 'active' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${property.totalRooms} phòng', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ]),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Sửa')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Xoá', style: TextStyle(color: Colors.red))])),
                ],
                onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
