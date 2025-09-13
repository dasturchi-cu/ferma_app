// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Activity _$ActivityFromJson(Map<String, dynamic> json) => Activity(
  id: json['id'] as String,
  farmId: json['farmId'] as String,
  type: $enumDecode(_$ActivityTypeEnumMap, json['type']),
  title: json['title'] as String,
  description: json['description'] as String,
  quantity: (json['quantity'] as num).toInt(),
  amount: (json['amount'] as num?)?.toDouble(),
  timestamp: DateTime.parse(json['timestamp'] as String),
  note: json['note'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ActivityToJson(Activity instance) => <String, dynamic>{
  'id': instance.id,
  'farmId': instance.farmId,
  'type': _$ActivityTypeEnumMap[instance.type]!,
  'title': instance.title,
  'description': instance.description,
  'quantity': instance.quantity,
  'amount': ?instance.amount,
  'timestamp': instance.timestamp.toIso8601String(),
  'note': ?instance.note,
  'metadata': ?instance.metadata,
};

const _$ActivityTypeEnumMap = {
  ActivityType.eggProduction: 'eggProduction',
  ActivityType.eggSale: 'eggSale',
  ActivityType.chickenAdded: 'chickenAdded',
  ActivityType.chickenDeath: 'chickenDeath',
  ActivityType.customerAdded: 'customerAdded',
  ActivityType.orderPaid: 'orderPaid',
  ActivityType.brokenEgg: 'brokenEgg',
  ActivityType.largeEgg: 'largeEgg',
};
