import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sale.g.dart';

@HiveType(typeId: 12)
@JsonSerializable()
class Sale extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime saleDate;

  @HiveField(2)
  final String customerId;

  @HiveField(3)
  final String customerName;

  @HiveField(4)
  final int eggsCount;

  @HiveField(5)
  final double pricePerTray;

  @HiveField(6)
  final double totalAmount;

  @HiveField(7)
  final String paymentStatus;

  @HiveField(8)
  final double paidAmount;

  @HiveField(9)
  final double remainingDebt;

  @HiveField(10)
  final String paymentMethod;

  @HiveField(11)
  final DateTime? paymentDate;

  @HiveField(12)
  final DateTime? deliveryDate;

  @HiveField(13)
  final String deliveryStatus;

  @HiveField(14)
  final String deliveryAddress;

  @HiveField(15)
  final double discount;

  @HiveField(16)
  final String? notes;

  @HiveField(17)
  final DateTime createdAt;

  Sale({
    required this.id,
    required this.saleDate,
    required this.customerId,
    required this.customerName,
    required this.eggsCount,
    required this.pricePerTray,
    required this.totalAmount,
    required this.paymentStatus,
    required this.paidAmount,
    required this.remainingDebt,
    required this.paymentMethod,
    this.paymentDate,
    this.deliveryDate,
    required this.deliveryStatus,
    required this.deliveryAddress,
    required this.discount,
    this.notes,
    required this.createdAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) => _$SaleFromJson(json);
  Map<String, dynamic> toJson() => _$SaleToJson(this);

  Sale copyWith({
    String? id,
    DateTime? saleDate,
    String? customerId,
    String? customerName,
    int? eggsCount,
    double? pricePerTray,
    double? totalAmount,
    String? paymentStatus,
    double? paidAmount,
    double? remainingDebt,
    String? paymentMethod,
    DateTime? paymentDate,
    DateTime? deliveryDate,
    String? deliveryStatus,
    String? deliveryAddress,
    double? discount,
    String? notes,
    DateTime? createdAt,
  }) {
    return Sale(
      id: id ?? this.id,
      saleDate: saleDate ?? this.saleDate,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      eggsCount: eggsCount ?? this.eggsCount,
      pricePerTray: pricePerTray ?? this.pricePerTray,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingDebt: remainingDebt ?? this.remainingDebt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      discount: discount ?? this.discount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Sale(id: $id, saleDate: $saleDate, customerId: $customerId, customerName: $customerName, eggsCount: $eggsCount, pricePerTray: $pricePerTray, totalAmount: $totalAmount, paymentStatus: $paymentStatus, paidAmount: $paidAmount, remainingDebt: $remainingDebt, paymentMethod: $paymentMethod, paymentDate: $paymentDate, deliveryDate: $deliveryDate, deliveryStatus: $deliveryStatus, deliveryAddress: $deliveryAddress, discount: $discount, notes: $notes, createdAt: $createdAt)';
  }
} 