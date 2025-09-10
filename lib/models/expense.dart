import 'package:hive/hive.dart';


@HiveType(typeId: 11)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String farmId;
  
  @HiveField(2)
  final String category; // feed, medicine, equipment, labor, utilities, other
  
  @HiveField(3)
  final String description;
  
  @HiveField(4)
  final double amount;
  
  @HiveField(5)
  final DateTime date;
  
  @HiveField(6)
  final String? receiptUrl;
  
  @HiveField(7)
  final String? supplier;
  
  @HiveField(8)
  final String? invoiceNumber;
  
  @HiveField(9)
  final String paymentMethod; // cash, bank_transfer, card, other
  
  @HiveField(10)
  final bool isRecurring;
  
  @HiveField(11)
  final String? recurrence; // daily, weekly, monthly, quarterly, yearly
  
  @HiveField(12)
  final String? notes;
  
  @HiveField(13)
  final String recordedBy;
  
  @HiveField(14)
  final DateTime createdAt;
  
  @HiveField(15)
  final DateTime? updatedAt;

  Expense({
    required this.id,
    required this.farmId,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    this.receiptUrl,
    this.supplier,
    this.invoiceNumber,
    this.paymentMethod = 'cash',
    this.isRecurring = false,
    this.recurrence,
    this.notes,
    required this.recordedBy,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      farmId: json['farm_id'],
      category: json['category'],
      description: json['description'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(json['date']),
      receiptUrl: json['receipt_url'],
      supplier: json['supplier'],
      invoiceNumber: json['invoice_number'],
      paymentMethod: json['payment_method'] ?? 'cash',
      isRecurring: json['is_recurring'] ?? false,
      recurrence: json['recurrence'],
      notes: json['notes'],
      recordedBy: json['recorded_by'],
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
      'category': category,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String().substring(0, 10), // YYYY-MM-DD
      'receipt_url': receiptUrl,
      'supplier': supplier,
      'invoice_number': invoiceNumber,
      'payment_method': paymentMethod,
      'is_recurring': isRecurring,
      'recurrence': recurrence,
      'notes': notes,
      'recorded_by': recordedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Expense copyWith({
    String? id,
    String? farmId,
    String? category,
    String? description,
    double? amount,
    DateTime? date,
    String? receiptUrl,
    String? supplier,
    String? invoiceNumber,
    String? paymentMethod,
    bool? isRecurring,
    String? recurrence,
    String? notes,
    String? recordedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      supplier: supplier ?? this.supplier,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrence: recurrence ?? this.recurrence,
      notes: notes ?? this.notes,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@HiveType(typeId: 12)
class ExpenseCategory extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String farmId;
  
  @HiveField(2)
  final String name;
  
  @HiveField(3)
  final String? description;
  
  @HiveField(4)
  final String? icon;
  
  @HiveField(5)
  final String? color;
  
  @HiveField(6)
  final bool isActive;
  
  @HiveField(7)
  final DateTime createdAt;
  
  @HiveField(8)
  final DateTime? updatedAt;

  ExpenseCategory({
    required this.id,
    required this.farmId,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.isActive = true,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'],
      farmId: json['farm_id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      color: json['color'],
      isActive: json['is_active'] ?? true,
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
      'description': description,
      'icon': icon,
      'color': color,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ExpenseCategory copyWith({
    String? id,
    String? farmId,
    String? name,
    String? description,
    String? icon,
    String? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
