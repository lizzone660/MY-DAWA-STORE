import 'package:flutter_test/flutter_test.dart';
import 'package:my_dawa_store/models/sale.dart';

void main() {
  group('Sale accounting', () {
    test('revenue and gross profit use the sale-time cost snapshot', () {
      final sale = Sale(
        id: 'sale-1',
        medicineId: 'med-1',
        medicineName: 'Paracetamol 500mg',
        quantity: 4,
        unitSellingPrice: 500,
        unitCostSnapshot: 300,
        soldAt: DateTime(2026, 11, 24, 10),
        workerId: 'worker-1',
      );

      expect(sale.revenue, 2000);
      expect(sale.grossProfit, 800);
    });

    test('loss-making sale produces negative gross profit', () {
      final sale = Sale(
        id: 'sale-2',
        medicineId: 'med-2',
        medicineName: 'Test item',
        quantity: 2,
        unitSellingPrice: 400,
        unitCostSnapshot: 500,
        soldAt: DateTime(2026, 11, 24, 11),
        workerId: 'worker-1',
      );

      expect(sale.revenue, 800);
      expect(sale.grossProfit, -200);
    });
  });
}
