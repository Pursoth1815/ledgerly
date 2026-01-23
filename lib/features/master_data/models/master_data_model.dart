import 'category_model.dart';

class MasterData {
  final List<Category> categories;
  final List<String> paymentModes;

  MasterData({
    required this.categories,
    required this.paymentModes,
  });

  factory MasterData.fromJson(Map<String, dynamic> json) {
    final categoriesJson = json['category']['data'] as List;
    final paymentModesJson = json['paymentMode']['data'] as List;

    return MasterData(
      categories: categoriesJson.map((e) => Category.fromJson(e)).toList(),
      paymentModes: List<String>.from(paymentModesJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((c) => c.toJson()).toList(),
      'paymentModes': paymentModes,
    };
  }
}
