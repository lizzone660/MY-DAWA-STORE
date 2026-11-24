class Sale {
  const Sale({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.unitSellingPrice,
    required this.unitCostSnapshot,
    required this.soldAt,
    required this.workerId,
  });

  final String id;
  final String medicineId;
  final String medicineName;
  final int quantity;
  final int unitSellingPrice;
  // Snapshot preserves correct historical margin if purchase cost changes later.
  final int unitCostSnapshot;
  final DateTime soldAt;
  final String workerId;

  int get revenue => quantity * unitSellingPrice;
  int get grossProfit => quantity * (unitSellingPrice - unitCostSnapshot);
}
