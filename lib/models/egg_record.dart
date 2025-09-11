class EggRecord {
  final String id;
  final DateTime date;
  final int totalEggs;
  final int goodEggs;
  final int brokenEggs;
  final int smallEggs;
  final int mediumEggs;
  final int largeEggs;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  EggRecord({
    required this.id,
    required this.date,
    required this.totalEggs,
    required this.goodEggs,
    required this.brokenEggs,
    required this.smallEggs,
    required this.mediumEggs,
    required this.largeEggs,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EggRecord.fromJson(Map<String, dynamic> json) {
    return EggRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      totalEggs: json['total_eggs'] as int,
      goodEggs: json['good_eggs'] as int,
      brokenEggs: json['broken_eggs'] as int,
      smallEggs: json['small_eggs'] as int,
      mediumEggs: json['medium_eggs'] as int,
      largeEggs: json['large_eggs'] as int,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'total_eggs': totalEggs,
      'good_eggs': goodEggs,
      'broken_eggs': brokenEggs,
      'small_eggs': smallEggs,
      'medium_eggs': mediumEggs,
      'large_eggs': largeEggs,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  EggRecord copyWith({
    String? id,
    DateTime? date,
    int? totalEggs,
    int? goodEggs,
    int? brokenEggs,
    int? smallEggs,
    int? mediumEggs,
    int? largeEggs,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EggRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      totalEggs: totalEggs ?? this.totalEggs,
      goodEggs: goodEggs ?? this.goodEggs,
      brokenEggs: brokenEggs ?? this.brokenEggs,
      smallEggs: smallEggs ?? this.smallEggs,
      mediumEggs: mediumEggs ?? this.mediumEggs,
      largeEggs: largeEggs ?? this.largeEggs,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EggRecord &&
        other.id == id &&
        other.date == date &&
        other.totalEggs == totalEggs &&
        other.goodEggs == goodEggs &&
        other.brokenEggs == brokenEggs &&
        other.smallEggs == smallEggs &&
        other.mediumEggs == mediumEggs &&
        other.largeEggs == largeEggs &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      date,
      totalEggs,
      goodEggs,
      brokenEggs,
      smallEggs,
      mediumEggs,
      largeEggs,
      notes,
    );
  }
}
