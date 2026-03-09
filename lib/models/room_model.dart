class RoomModel {
  final String roomId;
  final String roomName;
  final double baseRent; // Giá phòng cố định (vd: 1.800.000)
  final double waterServicePerPerson; // Tiền nước + dịch vụ mỗi người (vd: 100.000)
  final int numberOfPeople; // Số người ở
  final double electricityPricePerUnit; // Giá điện mỗi số (vd: 3.000)

  RoomModel({
    required this.roomId,
    required this.roomName,
    required this.baseRent,
    required this.waterServicePerPerson,
    required this.numberOfPeople,
    required this.electricityPricePerUnit,
  });

  double get totalWaterService => waterServicePerPerson * numberOfPeople;
}
