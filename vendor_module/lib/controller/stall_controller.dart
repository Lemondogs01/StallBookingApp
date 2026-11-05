import 'package:mfu_market/controller/mock_db.dart';
import 'package:mfu_market/model/stall_model.dart';

class StallController {
  Future<List<StallModel>> fetchFreeStalls({
    required DateTime date,
    String? zone,
    String? type,
  }) async {
    final booked = MockDb.bookedStallIds(date);
    final result = MockDb.stalls
        .where((s) =>
            s.status == 'active' &&
            !booked.contains(s.id) &&
            (zone == null || s.zone == zone) &&
            (type == null || s.productType == type))
        .toList();
    result.sort((a, b) => a.code.compareTo(b.code));
    return result;
  }

  /// Every stall that is open for booking (free or not), sorted by code.
  Future<List<StallModel>> fetchActiveStalls() async {
    final result = MockDb.stalls.where((s) => s.status == 'active').toList();
    result.sort((a, b) => a.code.compareTo(b.code));
    return result;
  }

  Future<bool> isFree(StallModel stall, DateTime date) async {
    return stall.status == 'active' &&
        !MockDb.bookedStallIds(date).contains(stall.id);
  }
}
