//uzbekman
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chicken.g.dart';

DateTime _parseDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) {
    final asInt = int.tryParse(v);
    if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
    try {
      return DateTime.parse(v);
    } catch (_) {}
  }
  return DateTime.now();
}

@HiveType(typeId: 0)
@JsonSerializable()
class Chicken {
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
  }) : deaths = deaths ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Chicken.fromJson(Map<String, dynamic> json) =>
      _$ChickenFromJson(json);

  Map<String, dynamic> toJson() => _$ChickenToJson(this);

  // Joriy tovuqlar sonini hisoblash
  int get currentCount {
    int totalDeaths = deaths.fold(0, (sum, death) => sum + death.count);
    return totalCount - totalDeaths;
  }

  // Bugungi o'limlar soni
  int get todayDeaths {
    DateTime today = DateTime.now();
    return deaths
        .where(
          (death) =>
              death.date.year == today.year &&
              death.date.month == today.month &&
              death.date.day == today.day,
        )
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
      if (count > mostCount) {
        mostDay = day;
        mostCount = count;
      }
      if (count < leastCount) {
        leastDay = day;
        leastCount = count;
      }
    });

    return {
      'totalDeaths': totalDeaths,
      'mostDeathsDay': {'date': mostDay, 'count': mostCount},
      'leastDeathsDay': {'date': leastDay, 'count': leastCount},
      'averageDeaths': averageDeaths,
    };
  }

  // O'lim qo'shish
  void addDeath(int count, {String? note}) {
    deaths.add(
      ChickenDeath(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        count: count,
        date: DateTime.now(),
        note: note,
      ),
    );
    updatedAt = DateTime.now();
  }

  // O'limni o'chirish (faqat bugungi)
  void removeTodayDeath() {
    DateTime today = DateTime.now();
    deaths.removeWhere(
      (death) =>
          death.date.year == today.year &&
          death.date.month == today.month &&
          death.date.day == today.day,
    );
    updatedAt = DateTime.now();
  }

  Chicken copyWith({
    String? id,
    int? totalCount,
    List<ChickenDeath>? deaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chicken(
      id: id ?? this.id,
      totalCount: totalCount ?? this.totalCount,
      deaths: deaths ?? List.from(this.deaths),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@HiveType(typeId: 1)
@JsonSerializable()
class ChickenDeath {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int count;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String? note;

  ChickenDeath({
    required this.id,
    required this.count,
    required this.date,
    this.note,
  });

  factory ChickenDeath.fromJson(Map<String, dynamic> json) =>
      _$ChickenDeathFromJson(json);

  Map<String, dynamic> toJson() => _$ChickenDeathToJson(this);
}
