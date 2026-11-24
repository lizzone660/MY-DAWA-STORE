class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantity,
    this.barcode,
    this.reorderLevel = 5,
  });

  final String id;
  final String name;
  final int purchasePrice; // TZS whole shillings
  final int sellingPrice;
  final int quantity;
  final String? barcode;
  final int reorderLevel;

  Medicine copyWith({
    String? name,
    int? purchasePrice,
    int? sellingPrice,
    int? quantity,
    String? barcode,
    int? reorderLevel,
  }) => Medicine(
    id: id,
    name: name ?? this.name,
    purchasePrice: purchasePrice ?? this.purchasePrice,
    sellingPrice: sellingPrice ?? this.sellingPrice,
    quantity: quantity ?? this.quantity,
    barcode: barcode ?? this.barcode,
    reorderLevel: reorderLevel ?? this.reorderLevel,
  );
}
