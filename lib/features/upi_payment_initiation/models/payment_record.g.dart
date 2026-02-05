// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentRecord _$PaymentRecordFromJson(Map<String, dynamic> json) =>
    PaymentRecord(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      notes: json['notes'] as String?,
      paymentMethod: $enumDecode(_$PaymentModeEnumMap, json['paymentMethod']),
      status: $enumDecode(_$PaymentStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$PaymentRecordToJson(PaymentRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'categoryId': instance.categoryId,
      'notes': instance.notes,
      'paymentMethod': _$PaymentModeEnumMap[instance.paymentMethod]!,
      'status': _$PaymentStatusEnumMap[instance.status]!,
    };

const _$PaymentModeEnumMap = {
  PaymentMode.upi: 'upi',
  PaymentMode.cash: 'cash',
  PaymentMode.card: 'card',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.initiated: 'initiated',
  PaymentStatus.pending: 'pending',
  PaymentStatus.confirmed: 'confirmed',
  PaymentStatus.failed: 'failed',
};
