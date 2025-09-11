import 'package:ferma_app/models/customer.dart';
import 'package:ferma_app/models/egg_record.dart';

class Sale {
  final String id;
  final String customerId;
  final String eggRecordId;
  final int quantity;
  final double pricePerEgg;
  final double totalPrice;
  final DateTime saleDate;
  final String? notes;
  final Customer? customer;
  final EggRecord? eggRecord;

  Sale({
    required this.id,
    required this.customerId,
    required this.eggRecordId,
    required this.quantity,
    required this.pricePerEgg,
    required this.totalPrice,
    required this.saleDate,
    this.notes,
    this.customer,
    this.eggRecord,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      eggRecordId: json['egg_record_id'] as String,
      quantity: json['quantity'] as int,
      pricePerEgg: (json['price_per_egg'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      saleDate: DateTime.parse(json['sale_date'] as String),
      notes: json['notes'] as String?,
      customer: json['customer'] != null 
          ? Customer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      eggRecord: json['egg_record'] != null
          ? EggRecord.fromJson(json['egg_record'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'egg_record_id': eggRecordId,
      'quantity': quantity,
      'price_per_egg': pricePerEgg,
      'total_price': totalPrice,
      'sale_date': saleDate.toIso8601String(),
      'notes': notes,
      if (customer != null) 'customer': customer!.toJson(),
      if (eggRecord != null) 'egg_record': eggRecord!.toJson(),
    };
  }

  Sale copyWith({
    String? id,
    String? customerId,
    String? eggRecordId,
    int? quantity,
    double? pricePerEgg,
    double? totalPrice,
    DateTime? saleDate,
    String? notes,
    Customer? customer,
    EggRecord? eggRecord,
  }) {
    return Sale(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      eggRecordId: eggRecordId ?? this.eggRecordId,
      quantity: quantity ?? this.quantity,
      pricePerEgg: pricePerEgg ?? this.pricePerEgg,
      totalPrice: totalPrice ?? this.totalPrice,
      saleDate: saleDate ?? this.saleDate,
      notes: notes ?? this.notes,
      customer: customer ?? this.customer,
      eggRecord: eggRecord ?? this.eggRecord,
    );
  }
}
