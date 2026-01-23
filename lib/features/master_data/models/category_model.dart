class Category {
  final String name;
  final String ownership;
  final bool isMandatory;
  final String color;

  Category({
    required this.name,
    required this.ownership,
    required this.isMandatory,
    required this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] ?? '',
      ownership: json['ownership'] ?? '',
      isMandatory: json['isMandatory'] ?? false,
      color: json['color'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "ownership": ownership,
      "isMandatory": isMandatory,
      "color": color,
    };
  }
}
