import 'package:ledgerly/core/constants/constants.dart';
import 'package:ledgerly/features/master_data/constants/master_data_constants.dart';

import 'category_model.dart';

class MasterData {
  final List<Category> categories;
  final List<String> paymentModes;

  MasterData({required this.categories, required this.paymentModes});

  factory MasterData.fromJson(Map<String, dynamic> json) {
    final categoriesJson = json[MasterDataConstants.categoryKey][ApiConstants.dataKey] as List;
    final paymentModesJson = json[MasterDataConstants.paymentModeKey][ApiConstants.dataKey] as List;

    return MasterData(
      categories: categoriesJson.map((e) => Category.fromJson(e)).toList(),
      paymentModes: List<String>.from(paymentModesJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {'categories': categories.map((c) => c.toJson()).toList(), 'paymentModes': paymentModes};
  }
}
