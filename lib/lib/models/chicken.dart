import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'chicken.g.dart';

DateTime _parseDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is Timestamp) return v.toDate();
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) {
    final asInt = int.tryParse(v);
    if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
    try { return DateTime.parse(v); } catch (_) {}
  }
  return DateTime.now();
}

@HiveType(typeId: 0)
class Chicken extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int totalCount;

  @HiveField(2)
  List<ChickenDeath> deaths;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  Chicken({
    required this.id,
    required this.totalCount,
    List<ChickenDeath>? deaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : deaths = deaths ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Joriy tovuqlar sonini hisoblash
  int get currentCount {
    int totalDeaths = deaths.fold(0, (sum, death) => sum + death.count);
    return totalCount - totalDeaths;
  }

  // Bugungi o'limlar soni
  int get todayDeaths {
    DateTime today = DateTime.now();
    return deaths
        .where((death) => death.date.year == today.year &&
            death.date.month == today.month &&
            death.date.day == today.day)
        .fold(0, (sum, death) => sum + death.count);
  }

  // O'limlar statistikasi
  Map<String, dynamic> get deathStats {
    if (deaths.isEmpty) {
      return {
        'totalDeaths': 0,
        'mostDeathsDay': null,
        'leastDeathsDay': null,
        'averageDeaths': 0.0,
      };
    }

    // Per-day aggregation
    final Map<DateTime, int> daily = {};
    for (final d in deaths) {
      final day = DateTime(d.date.year, d.date.month, d.date.day);
      daily[day] = (daily[day] ?? 0) + d.count;
    }

    final totalDeaths = daily.values.fold(0, (a, b) => a + b);
    final averageDeaths = totalDeaths / daily.length;

    DateTime mostDay = daily.entries.first.key;
    DateTime leastDay = daily.entries.first.key;
    int mostCount = daily[mostDay] ?? 0;
    int leastCount = daily[leastDay] ?? 0;
    daily.forEach((day, count) {
      if (count > mostCount) { mostDay = day; mostCount = count; }
      if (count < leastCount) { leastDay = day; leastCount = count; }
    });

    return {
      'totalDeaths': totalDeaths,
      'mostDeathsDay': {
        'date': mostDay,
        'count': mostCount,
      },
      'leastDeathsDay': {
        'date': leastDay,
        'count': leastCount,
      },
      'averageDeaths': averageDeaths,
    };
  }

  // O'lim qo'shish
  void addDeath(int count) {
    deaths.add(ChickenDeath(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      count: count,
      date: DateTime.now(),
    ));
    updatedAt = DateTime.now();
  }

  // O'limni o'chirish (faqat bugungi)
  void removeTodayDeath() {
    DateTime today = DateTime.now();
    deaths.removeWhere((death) => death.date.year == today.year &&
        death.date.month == today.month &&
        death.date.day == today.day);
    updatedAt = DateTime.now();
  }

  // Firebase serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'totalCount': totalCount,
      'deaths': deaths.map((death) => death.toJson()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Firebase deserialization
  factory Chicken.fromJson(Map<String, dynamic> json) {
    return Chicken(
      id: json['id'] as String? ?? '',
      totalCount: json['totalCount'] as int? ?? 0,
      deaths: (json['deaths'] as List<dynamic>?)
          ?.map((death) => ChickenDeath.fromJson(death as Map<String, dynamic>))
          .toList() ??
          [],
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

@HiveType(typeId: 1)
class ChickenDeath extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int count;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String? note;

  ChickenDeath({
    required this.id,
    required this.count,
    required this.date,
    this.note,
  });

  // Firebase serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'count': count,
      'date': date.millisecondsSinceEpoch,
      'note': note,
    };
  }

  // Firebase deserialization
  factory ChickenDeath.fromJson(Map<String, dynamic> json) {
    return ChickenDeath(
      id: json['id'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      date: _parseDate(json['date']),
      note: json['note'] as String?,
    );
  }
} 