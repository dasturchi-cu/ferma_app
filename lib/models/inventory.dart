import 'package:hive/hive.dart';

@HiveType(typeId: 13)
class InventoryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String farmId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String category; // feed, medicine, equipment, supplies, other

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final double quantity;

  @HiveField(6)
  final String unit; // kg, g, L, ml, pcs, etc.

  @HiveField(7)
  final double? unitPrice;

  @HiveField(8)
  final double? minStockLevel;

  @HiveField(9)
  final double? maxStockLevel;

  @HiveField(10)
  final String? supplier;

  @HiveField(11)
  final String? storageLocation;

  @HiveField(12)
  final DateTime? expiryDate;

  @HiveField(13)
  final String? batchNumber;

  @HiveField(14)
  final String? notes;

  @HiveField(15)
  final String? imageUrl;

  @HiveField(16)
  final DateTime createdAt;

  @HiveField(17)
  final DateTime? updatedAt;

  InventoryItem({
    required this.id,
    required this.farmId,
    required this.name,
    required this.category,
    this.description,
    required this.quantity,
    required this.unit,
    this.unitPrice,
    this.minStockLevel,
    this.maxStockLevel,
    this.supplier,
    this.storageLocation,
    this.expiryDate,
    this.batchNumber,
    this.notes,
    this.imageUrl,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      farmId: json['farm_id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      unit: json['unit'],
      unitPrice: json['unit_price'] != null
          ? (json['unit_price'] as num).toDouble()
          : null,
      minStockLevel: json['min_stock_level'] != null
          ? (json['min_stock_level'] as num).toDouble()
          : null,
      maxStockLevel: json['max_stock_level'] != null
          ? (json['max_stock_level'] as num).toDouble()
          : null,
      supplier: json['supplier'],
      storageLocation: json['storage_location'],
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      batchNumber: json['batch_number'],
      notes: json['notes'],
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm_id': farmId,
      'name': name,
      'category': category,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'min_stock_level': minStockLevel,
      'max_stock_level': maxStockLevel,
      'supplier': supplier,
      'storage_location': storageLocation,
      'expiry_date': expiryDate?.toIso8601String(),
      'batch_number': batchNumber,
      'notes': notes,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isLowStock => minStockLevel != null && quantity <= minStockLevel!;

  bool get isOutOfStock => quantity <= 0;

  InventoryItem copyWith({
    String? id,
    String? farmId,
    String? name,
    String? category,
    String? description,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? minStockLevel,
    double? maxStockLevel,
    String? supplier,
    String? storageLocation,
    DateTime? expiryDate,
    String? batchNumber,
    String? notes,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      maxStockLevel: maxStockLevel ?? this.maxStockLevel,
      supplier: supplier ?? this.supplier,
      storageLocation: storageLocation ?? this.storageLocation,
      expiryDate: expiryDate ?? this.expiryDate,
      batchNumber: batchNumber ?? this.batchNumber,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@HiveType(typeId: 14)
class InventoryTransaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String farmId;

  @HiveField(2)
  final String itemId;

  @HiveField(3)
  final String transactionType; // in, out, adjust, transfer

  @HiveField(4)
  final double quantity;

  @HiveField(5)
  final String unit;

  @HiveField(6)
  final double? unitPrice;

  @HiveField(7)
  final double? totalAmount;

  @HiveField(8)
  final String? referenceId; // invoice_id, order_id, adjustment_id, etc.

  @HiveField(9)
  final String? referenceType; // purchase, sale, adjustment, etc.

  @HiveField(10)
  final DateTime transactionDate;

  @HiveField(11)
  final String? notes;

  @HiveField(12)
  final String recordedBy;

  @HiveField(13)
  final DateTime createdAt;

  InventoryTransaction({
    required this.id,
    required this.farmId,
    required this.itemId,
    required this.transactionType,
    required this.quantity,
    required this.unit,
    this.unitPrice,
    this.totalAmount,
    this.referenceId,
    this.referenceType,
    required this.transactionDate,
    this.notes,
    required this.recordedBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    return InventoryTransaction(
      id: json['id'],
      farmId: json['farm_id'],
      itemId: json['item_id'],
      transactionType: json['transaction_type'],
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      unit: json['unit'],
      unitPrice: json['unit_price'] != null
          ? (json['unit_price'] as num).toDouble()
          : null,
      totalAmount: json['total_amount'] != null
          ? (json['total_amount'] as num).toDouble()
          : null,
      referenceId: json['reference_id'],
      referenceType: json['reference_type'],
      transactionDate: DateTime.parse(json['transaction_date']),
      notes: json['notes'],
      recordedBy: json['recorded_by'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm_id': farmId,
      'item_id': itemId,
      'transaction_type': transactionType,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'transaction_date': transactionDate.toIso8601String(),
      'notes': notes,
      'recorded_by': recordedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isIncoming => transactionType.toLowerCase() == 'in';
  bool get isOutgoing => transactionType.toLowerCase() == 'out';

  InventoryTransaction copyWith({
    String? id,
    String? farmId,
    String? itemId,
    String? transactionType,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? totalAmount,
    String? referenceId,
    String? referenceType,
    DateTime? transactionDate,
    String? notes,
    String? recordedBy,
    DateTime? createdAt,
  }) {
    return InventoryTransaction(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      itemId: itemId ?? this.itemId,
      transactionType: transactionType ?? this.transactionType,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      transactionDate: transactionDate ?? this.transactionDate,
      notes: notes ?? this.notes,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
