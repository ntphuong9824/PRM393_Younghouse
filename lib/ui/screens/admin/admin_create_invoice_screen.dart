import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/contract_model.dart';
import '../../../models/invoice_model.dart';
import '../../../models/invoice_service_model.dart';
import '../../../models/room_service_model.dart';
import '../../../services/contract_service.dart';
import '../../../services/invoice_service.dart';
import '../../../services/notification_service.dart';

class AdminCreateInvoiceScreen extends StatefulWidget {
  final String landlordId;

  const AdminCreateInvoiceScreen({
    super.key,
    required this.landlordId,
  });

  @override
  State<AdminCreateInvoiceScreen> createState() =>
      _AdminCreateInvoiceScreenState();
}

class _AdminCreateInvoiceScreenState extends State<AdminCreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contractService = ContractService();
  final _invoiceService = InvoiceService();
  final _notificationService = NotificationService();
  final _db = FirebaseFirestore.instance;

  final _rentCtrl = TextEditingController();
  final _manualOtherFeeCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  final Map<String, TextEditingController> _quantityCtrls = {};
  final Map<String, TextEditingController> _meterPrevCtrls = {};
  final Map<String, TextEditingController> _meterCurrCtrls = {};

  List<ContractModel> _contracts = const [];
  List<RoomServiceModel> _roomServices = const [];
  Map<String, String> _roomDisplayById = const {};
  Map<String, String> _tenantDisplayById = const {};

  String? _selectedContractId;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  DateTime _dueDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 10);

  bool _isLoading = true;
  bool _isSaving = false;

  ContractModel? get _selectedContract {
    if (_selectedContractId == null) return null;
    for (final c in _contracts) {
      if (c.id == _selectedContractId) return c;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  @override
  void dispose() {
    _rentCtrl.dispose();
    _manualOtherFeeCtrl.dispose();
    _notesCtrl.dispose();
    _disposeServiceControllers();
    super.dispose();
  }

  void _disposeServiceControllers() {
    for (final controller in _quantityCtrls.values) {
      controller.dispose();
    }
    for (final controller in _meterPrevCtrls.values) {
      controller.dispose();
    }
    for (final controller in _meterCurrCtrls.values) {
      controller.dispose();
    }
    _quantityCtrls.clear();
    _meterPrevCtrls.clear();
    _meterCurrCtrls.clear();
  }

  Future<void> _loadContracts() async {
    setState(() => _isLoading = true);
    try {
      final contracts =
          await _contractService.getActiveContractsByLandlord(widget.landlordId);
      final roomDisplay = await _loadRoomDisplay(contracts);
      final tenantDisplay = await _loadTenantDisplay(contracts);

      if (!mounted) return;
      setState(() {
        _contracts = contracts;
        _roomDisplayById = roomDisplay;
        _tenantDisplayById = tenantDisplay;
        _selectedContractId = contracts.isNotEmpty ? contracts.first.id : null;
      });

      await _loadRoomServicesForSelectedContract();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được danh sách hợp đồng: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, String>> _loadRoomDisplay(
    List<ContractModel> contracts,
  ) async {
    final roomIds =
        contracts.map((e) => e.roomId).where((e) => e.isNotEmpty).toSet();
    final result = <String, String>{};

    await Future.wait(roomIds.map((roomId) async {
      final doc = await _db.collection('rooms').doc(roomId).get();
      final data = doc.data();
      final roomNumber = ((data?['room_number'] as String?) ?? '').trim();
      result[roomId] = roomNumber.isNotEmpty ? roomNumber : roomId;
    }));

    return result;
  }

  Future<Map<String, String>> _loadTenantDisplay(
    List<ContractModel> contracts,
  ) async {
    final tenantIds =
        contracts.map((e) => e.tenantId).where((e) => e.isNotEmpty).toSet();
    final result = <String, String>{};

    await Future.wait(tenantIds.map((tenantId) async {
      final doc = await _db.collection('users').doc(tenantId).get();
      final data = doc.data();
      final fullName = ((data?['full_name'] as String?) ?? '').trim();
      final phone = ((data?['phone'] as String?) ?? '').trim();
      final email = ((data?['email'] as String?) ?? '').trim();

      if (fullName.isNotEmpty) {
        result[tenantId] = fullName;
      } else if (phone.isNotEmpty) {
        result[tenantId] = phone;
      } else if (email.isNotEmpty) {
        result[tenantId] = email;
      } else {
        result[tenantId] = tenantId;
      }
    }));

    return result;
  }

  Future<void> _loadRoomServicesForSelectedContract() async {
    final contract = _selectedContract;
    if (contract == null) {
      setState(() {
        _roomServices = const [];
      });
      _disposeServiceControllers();
      return;
    }

    try {
      final services = await _invoiceService.getRoomServicesByRoom(contract.roomId);
      if (!mounted) return;

      _disposeServiceControllers();
      for (final service in services) {
        if (service.isMetered) {
          _meterPrevCtrls[service.id] = TextEditingController(text: '0');
          _meterCurrCtrls[service.id] = TextEditingController(text: '0');
        } else {
          _quantityCtrls[service.id] = TextEditingController(text: '1');
        }
      }

      setState(() {
        _roomServices = services;
        _rentCtrl.text = contract.monthlyRent.toStringAsFixed(0);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được dịch vụ phòng: $e')),
      );
    }
  }

  String _contractLabel(ContractModel contract) {
    final room = _roomDisplayById[contract.roomId] ?? contract.roomId;
    final tenant = _tenantDisplayById[contract.tenantId] ?? contract.tenantId;
    return 'Phòng $room - $tenant';
  }

  bool _isElectricService(RoomServiceModel service) {
    return service.serviceName.trim().toLowerCase() == 'electric';
  }

  bool _isWaterService(RoomServiceModel service) {
    return service.serviceName.trim().toLowerCase() == 'water';
  }

  double _serviceQuantity(RoomServiceModel service) {
    if (service.isMetered) {
      final prev = int.tryParse(_meterPrevCtrls[service.id]?.text ?? '') ?? 0;
      final curr = int.tryParse(_meterCurrCtrls[service.id]?.text ?? '') ?? 0;
      return max(0, curr - prev).toDouble();
    }

    final raw = double.tryParse(_quantityCtrls[service.id]?.text ?? '') ?? 0;
    return raw < 0 ? 0 : raw;
  }

  double _serviceAmount(RoomServiceModel service) {
    return _serviceQuantity(service) * service.pricePerUnit;
  }

  double get _servicesTotal {
    return _roomServices.fold<double>(0, (total, s) => total + _serviceAmount(s));
  }

  double get _manualOtherFee {
    final value = double.tryParse(_manualOtherFeeCtrl.text) ?? 0;
    return value < 0 ? 0 : value;
  }

  double get _rentAmount {
    final value = double.tryParse(_rentCtrl.text) ?? 0;
    return value < 0 ? 0 : value;
  }

  double get _totalAmount => _rentAmount + _servicesTotal + _manualOtherFee;

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(_year, _month, 1),
      lastDate: DateTime(_year, _month + 2, 28),
    );
    if (picked == null) return;
    setState(() => _dueDate = picked);
  }

  Future<void> _sendInvoiceNotifications(
    ContractModel contract,
    String invoiceId,
  ) async {
    final room = _roomDisplayById[contract.roomId] ?? contract.roomId;
    final title = 'Hoá đơn tháng $_month/$_year';
    final message =
        'Hoá đơn phòng $room tháng $_month/$_year đã được tạo. '
        'Tổng tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VND ').format(_totalAmount)}. '
        'Hạn thanh toán: ${DateFormat('dd/MM/yyyy').format(_dueDate)}.';

    final recipients = [contract.tenantId, ...contract.coTenants]
        .where((id) => id.isNotEmpty)
        .toSet();

    await Future.wait(
      recipients.map(
        (userId) => _notificationService.sendNotification(
          title: title,
          message: message,
          targetUserId: userId,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final contract = _selectedContract;
    if (contract == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn hợp đồng')),
      );
      return;
    }

    for (final service in _roomServices.where((s) => s.isMetered)) {
      final prev = int.tryParse(_meterPrevCtrls[service.id]?.text ?? '') ?? 0;
      final curr = int.tryParse(_meterCurrCtrls[service.id]?.text ?? '') ?? 0;
      if (curr < prev) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chỉ số cuối kỳ của ${service.serviceName} phải >= đầu kỳ',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final invoiceId = _invoiceService.buildInvoiceId(
        contractId: contract.id,
        month: _month,
        year: _year,
      );

      final existed = await _invoiceService.hasInvoiceForContractMonth(
        contract.id,
        _month,
        _year,
      );
      if (existed) {
        throw Exception('Hợp đồng đã có hoá đơn trong tháng này');
      }

      int electricPrev = 0;
      int electricCurr = 0;
      double electricPrice = 0;
      int waterPrev = 0;
      int waterCurr = 0;
      double waterPrice = 0;

      final details = <InvoiceServiceModel>[];
      for (final service in _roomServices) {
        final qty = _serviceQuantity(service);
        final amount = qty * service.pricePerUnit;

        String? note;
        if (service.isMetered) {
          final prev = int.tryParse(_meterPrevCtrls[service.id]?.text ?? '') ?? 0;
          final curr = int.tryParse(_meterCurrCtrls[service.id]?.text ?? '') ?? 0;
          note = 'meter:$prev-$curr';

          if (_isElectricService(service)) {
            electricPrev = prev;
            electricCurr = curr;
            electricPrice = service.pricePerUnit;
          }
          if (_isWaterService(service)) {
            waterPrev = prev;
            waterCurr = curr;
            waterPrice = service.pricePerUnit;
          }
        }

        details.add(
          InvoiceServiceModel(
            id: '${invoiceId}_${service.id}',
            invoiceId: invoiceId,
            serviceName: service.serviceName,
            quantity: qty,
            unitPrice: service.pricePerUnit,
            amount: amount,
            note: note,
          ),
        );
      }

      if (_manualOtherFee > 0) {
        details.add(
          InvoiceServiceModel(
            id: '${invoiceId}_manual_other_fee',
            invoiceId: invoiceId,
            serviceName: 'manual_other_fee',
            quantity: 1,
            unitPrice: _manualOtherFee,
            amount: _manualOtherFee,
            note: 'Phí bổ sung do admin nhập tay',
          ),
        );
      }

      final otherFees = details
          .where((item) => item.serviceName.trim().toLowerCase() != 'electric')
          .fold<double>(0, (total, item) => total + item.amount);

      final now = DateTime.now();
      final invoice = InvoiceModel(
        id: invoiceId,
        contractId: contract.id,
        roomId: contract.roomId,
        tenantId: contract.tenantId,
        landlordId: widget.landlordId,
        month: _month,
        year: _year,
        electricPrev: electricPrev,
        electricCurr: electricCurr,
        electricPrice: electricPrice,
        waterPrev: waterPrev,
        waterCurr: waterCurr,
        waterPrice: waterPrice,
        rentAmount: _rentAmount,
        otherFees: otherFees,
        totalAmount: _totalAmount,
        status: 'unpaid',
        dueDate: _dueDate,
        paidAt: null,
        paymentMethod: null,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdBy: widget.landlordId,
        createdAt: now,
        updatedAt: now,
      );

      await _invoiceService.createInvoiceWithServices(invoice, details);

      // Gửi thông báo cho tenant và co-tenants
      await _sendInvoiceNotifications(contract, invoice.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo hoá đơn thành công'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tạo hoá đơn: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tạo hoá đơn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              onChanged: () => setState(() {}),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_contracts.isEmpty)
                      _infoBanner('Chưa có hợp đồng active để tạo hoá đơn'),
                    if (_contracts.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _selectedContractId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Hợp đồng',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.assignment,
                            color: AppColors.primary,
                          ),
                        ),
                        items: _contracts
                            .map(
                              (contract) => DropdownMenuItem<String>(
                                value: contract.id,
                                child: Text(_contractLabel(contract)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) async {
                          setState(() => _selectedContractId = value);
                          await _loadRoomServicesForSelectedContract();
                        },
                        validator: (value) =>
                            value == null ? 'Vui lòng chọn hợp đồng' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _month,
                              decoration: const InputDecoration(
                                labelText: 'Tháng',
                                border: OutlineInputBorder(),
                              ),
                              items: List.generate(12, (i) => i + 1)
                                  .map(
                                    (m) => DropdownMenuItem<int>(
                                      value: m,
                                      child: Text('Tháng $m'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _month = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _year,
                              decoration: const InputDecoration(
                                labelText: 'Năm',
                                border: OutlineInputBorder(),
                              ),
                              items: {_year - 1, _year, _year + 1}
                                  .map(
                                    (y) => DropdownMenuItem<int>(
                                      value: y,
                                      child: Text('$y'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _year = value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _rentCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Tiền phòng',
                          border: OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.home_work, color: AppColors.primary),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tiền phòng';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed < 0) {
                            return 'Tiền phòng không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _datePickerField(),
                      const SizedBox(height: 16),
                      const Text(
                        'Dịch vụ phòng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_roomServices.isEmpty)
                        _infoBanner(
                          'Phòng này chưa khai báo room_services, hoá đơn chỉ có tiền phòng',
                        ),
                      ..._roomServices.map(_serviceCard),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _manualOtherFeeCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Phí khác bổ sung',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.receipt_long,
                            color: AppColors.primary,
                          ),
                        ),
                        validator: (value) {
                          final parsed = double.tryParse((value ?? '').trim());
                          if (parsed == null) return 'Giá trị không hợp lệ';
                          if (parsed < 0) return 'Phí khác không được âm';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tiền phòng: ${currency.format(_rentAmount)}'),
                            const SizedBox(height: 4),
                            Text('Dịch vụ: ${currency.format(_servicesTotal)}'),
                            const SizedBox(height: 4),
                            Text(
                              'Phí khác bổ sung: ${currency.format(_manualOtherFee)}',
                            ),
                            const Divider(height: 20),
                            Text(
                              'Tổng cộng: ${currency.format(_totalAmount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'TẠO HOÁ ĐƠN',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _serviceCard(RoomServiceModel service) {
    final qty = _serviceQuantity(service);
    final amount = _serviceAmount(service);
    final subtitle = service.isMetered
        ? '${qty.toStringAsFixed(0)} ${service.unit} x ${service.pricePerUnit.toStringAsFixed(0)}'
        : '${qty.toStringAsFixed(2)} ${service.unit} x ${service.pricePerUnit.toStringAsFixed(0)}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service.serviceName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (service.isMetered)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _meterPrevCtrls[service.id],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Chỉ số đầu',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) return 'Nhập đầu';
                        if (int.tryParse((value ?? '').trim()) == null) {
                          return 'Không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _meterCurrCtrls[service.id],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Chỉ số cuối',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) return 'Nhập cuối';
                        if (int.tryParse((value ?? '').trim()) == null) {
                          return 'Không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              )
            else
              TextFormField(
                controller: _quantityCtrls[service.id],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Số lượng',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return 'Nhập số lượng';
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null || parsed < 0) return 'Không hợp lệ';
                  return null;
                },
              ),
            const SizedBox(height: 8),
            Text(
              'Thành tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VND ').format(amount)}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePickerField() {
    final label = DateFormat('dd/MM/yyyy').format(_dueDate);
    return InkWell(
      onTap: _pickDueDate,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Hạn thanh toán',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today, color: AppColors.primary),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _infoBanner(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.orange),
      ),
    );
  }
}



