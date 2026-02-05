import 'package:json_annotation/json_annotation.dart';

import 'model.dart';


part 'payment_record.g.dart';

@JsonSerializable(explicitToJson: true)
class PaymentRecord {
  final String id;
  final double amount;
  final String categoryId;
  final String? notes;

  final PaymentMode paymentMethod;
  final PaymentStatus status;

  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.categoryId,
    this.notes,
    required this.paymentMethod,
    required this.status,
  });

  /// JSON → Model
  factory PaymentRecord.fromJson(Map<String, dynamic> json) => _$PaymentRecordFromJson(json);

  /// Model → JSON
  Map<String, dynamic> toJson() => _$PaymentRecordToJson(this);
}
