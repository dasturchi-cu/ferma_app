import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'egg.g.dart';

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

@HiveType(typeId: 2)
@JsonSerializable()
class Egg {
  @HiveField(0)
  String id;

  @HiveField(1)
  List<EggProduction> production;

  @HiveField(2)
  List<EggSale> sales;

  @HiveField(3)
  List<BrokenEgg> brokenEggs;

  @HiveField(4)
  List<LargeEgg> largeEggs;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  Egg({
    required this.id,
    List<EggProduction>? production,
    List<EggSale>? sales,
    List<BrokenEgg>? brokenEggs,
    List<LargeEgg>? largeEggs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : production = production ?? [],
       sales = sales ?? [],
       brokenEggs = brokenEggs ?? [],
       largeEggs = largeEggs ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Egg.fromJson(Map<String, dynamic> json) => _$EggFromJson(json);

  Map<String, dynamic> toJson() => _$EggToJson(this);

  // Bugungi ishlab chiqarish
  int get todayProduction {
    DateTime today = DateTime.now();
    return production
        .where(
          (prod) =>
              prod.date.year == today.year &&
              prod.date.month == today.month &&
              prod.date.day == today.day,
        )
        .fold(0, (sum, prod) => sum + prod.trayCount);
  }

  // Bugungi sotuvlar
  int get todaySales {
    DateTime today = DateTime.now();
    return sales
        .where(
          (sale) =>
              sale.date.year == today.year &&
              sale.date.month == today.month &&
              sale.date.day == today.day,
        )
        .fold(0, (sum, sale) => sum + sale.trayCount);
  }

  // Bugungi siniq tuxumlar
  int get todayBroken {
    DateTime today = DateTime.now();
    return brokenEggs
        .where(
          (broken) =>
              broken.date.year == today.year &&
              broken.date.month == today.month &&
              broken.date.day == today.day,
        )
        .fold(0, (sum, broken) => sum + broken.trayCount);
  }

  // Bugungi katta tuxumlar
  int get todayLarge {
    DateTime today = DateTime.now();
    return largeEggs
        .where(
          (large) =>
              large.date.year == today.year &&
              large.date.month == today.month &&
              large.date.day == today.day,
        )
        .fold(0, (sum, large) => sum + large.trayCount);
  }

  // Joriy zaxira
  int get currentStock {
    int totalProduction = production.fold(
      0,
      (sum, prod) => sum + prod.trayCount,
    );
    int totalSales = sales.fold(0, (sum, sale) => sum + sale.trayCount);
    int totalBroken = brokenEggs.fold(
      0,
      (sum, broken) => sum + broken.trayCount,
    );
    int totalLarge = largeEggs.fold(
      0,
      (sum, large) => sum + large.trayCount,
    );
    // Katta tuxumlar alohida chiqarilishi kerak
    return totalProduction - totalSales - totalBroken - totalLarge;
  }
  
  // Tuxumlarni zaxiradan chiqarish
  bool deductFromStock(int trayCount, {String? note}) {
    if (trayCount <= 0) return false;
    
    // Check if we have enough stock
    if (trayCount > currentStock) {
      return false; // Not enough stock
    }
    
    // Add to sales with 0 price since this is just a stock deduction
    addSale(trayCount, 0.0, note: note ?? 'Stock deduction');
    return true;
  }

  // Oxirgi N kun uchun ishlab chiqarish yig'indisi
  int productionLastNDays(int days) {
    if (days <= 0) return 0;
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    return production
        .where(
          (p) =>
              p.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              p.date.isBefore(
                DateTime(
                  now.year,
                  now.month,
                  now.day,
                ).add(const Duration(days: 1)),
              ),
        )
        .fold(0, (sum, p) => sum + p.trayCount);
  }

  // Oxirgi N kun uchun kunlik o'rtacha ishlab chiqarish
  double productionDailyAverageLastNDays(int days) {
    if (days <= 0) return 0.0;
    final total = productionLastNDays(days);
    return total / days;
  }

  // Oxirgi N kun uchun sotuvlar yig'indisi
  int salesLastNDays(int days) {
    if (days <= 0) return 0;
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    return sales
        .where(
          (s) =>
              s.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              s.date.isBefore(
                DateTime(
                  now.year,
                  now.month,
                  now.day,
                ).add(const Duration(days: 1)),
              ),
        )
        .fold(0, (sum, s) => sum + s.trayCount);
  }

  // Oxirgi N kun uchun siniq tuxumlar yig'indisi
  int brokenLastNDays(int days) {
    if (days <= 0) return 0;
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    return brokenEggs
        .where(
          (b) =>
              b.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              b.date.isBefore(
                DateTime(
                  now.year,
                  now.month,
                  now.day,
                ).add(const Duration(days: 1)),
              ),
        )
        .fold(0, (sum, b) => sum + b.trayCount);
  }

  // Oxirgi N kun uchun katta tuxumlar yig'indisi
  int largeLastNDays(int days) {
    if (days <= 0) return 0;
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    return largeEggs
        .where(
          (l) =>
              l.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              l.date.isBefore(
                DateTime(
                  now.year,
                  now.month,
                  now.day,
                ).add(const Duration(days: 1)),
              ),
        )
        .fold(0, (sum, l) => sum + l.trayCount);
  }

  // Ishlab chiqarish statistikasi
  Map<String, dynamic> get productionStats {
    if (production.isEmpty) {
      return {
        'totalProduction': 0,
        'mostProductionDay': null,
        'leastProductionDay': null,
        'averageProduction': 0.0,
      };
    }

    // Per-day aggregation
    final Map<DateTime, int> daily = {};
    for (final p in production) {
      final d = DateTime(p.date.year, p.date.month, p.date.day);
      daily[d] = (daily[d] ?? 0) + p.trayCount;
    }

    final totalProduction = daily.values.fold(0, (a, b) => a + b);
    final averageProduction = totalProduction / daily.length;

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
      'totalProduction': totalProduction,
      'mostProductionDay': {'date': mostDay, 'count': mostCount},
      'leastProductionDay': {'date': leastDay, 'count': leastCount},
      'averageProduction': averageProduction,
    };
  }

  // Siniq tuxumlar statistikasi
  Map<String, dynamic> get brokenStats {
    if (brokenEggs.isEmpty) {
      return {
        'totalBroken': 0,
        'mostBrokenDay': null,
        'leastBrokenDay': null,
        'zeroBrokenDays': 0,
      };
    }

    // Per-day aggregation
    final Map<DateTime, int> daily = {};
    for (final b in brokenEggs) {
      final d = DateTime(b.date.year, b.date.month, b.date.day);
      daily[d] = (daily[d] ?? 0) + b.trayCount;
    }

    final totalBroken = daily.values.fold(0, (a, b) => a + b);

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

    // Siniq tuxum bo'lmagan kunlar soni
    int zeroBrokenDays = 0;
    // Start from earliest among production and brokenEggs
    DateTime? minProd = production.isNotEmpty
        ? production.map((p) => p.date).reduce((a, b) => a.isBefore(b) ? a : b)
        : null;
    DateTime minBroken = brokenEggs
        .map((b) => b.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    DateTime startDate = (minProd == null || minBroken.isBefore(minProd))
        ? minBroken
        : minProd;
    DateTime endDate = DateTime.now();

    for (
      DateTime date = DateTime(startDate.year, startDate.month, startDate.day);
      !date.isAfter(DateTime(endDate.year, endDate.month, endDate.day));
      date = date.add(const Duration(days: 1))
    ) {
      final hasBroken = daily.containsKey(date);
      if (!hasBroken) zeroBrokenDays++;
    }

    return {
      'totalBroken': totalBroken,
      'mostBrokenDay': {'date': mostDay, 'count': mostCount},
      'leastBrokenDay': {'date': leastDay, 'count': leastCount},
      'zeroBrokenDays': zeroBrokenDays,
    };
  }

  // Katta tuxumlar statistikasi
  Map<String, dynamic> get largeEggStats {
    if (largeEggs.isEmpty) {
      return {
        'totalLarge': 0,
        'mostLargeDay': null,
        'leastLargeDay': null,
        'averageLarge': 0.0,
      };
    }

    // Per-day aggregation
    final Map<DateTime, int> daily = {};
    for (final l in largeEggs) {
      final d = DateTime(l.date.year, l.date.month, l.date.day);
      daily[d] = (daily[d] ?? 0) + l.trayCount;
    }

    final totalLarge = daily.values.fold(0, (a, b) => a + b);
    final averageLarge = totalLarge / daily.length;

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
      'totalLarge': totalLarge,
      'mostLargeDay': {'date': mostDay, 'count': mostCount},
      'leastLargeDay': {'date': leastDay, 'count': leastCount},
      'averageLarge': averageLarge,
    };
  }

  // Ishlab chiqarish qo'shish
  void addProduction(int trayCount, {String? note}) {
    production.add(
      EggProduction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        trayCount: trayCount,
        date: DateTime.now(),
        note: note,
      ),
    );
    updatedAt = DateTime.now();
  }

  // Sotuv qo'shish
  void addSale(int trayCount, double pricePerTray, {String? note}) {
    sales.add(
      EggSale(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        trayCount: trayCount,
        pricePerTray: pricePerTray,
        date: DateTime.now(),
        note: note,
      ),
    );
    updatedAt = DateTime.now();
  }

  // Siniq tuxum qo'shish
  void addBroken(int trayCount, {String? note}) {
    brokenEggs.add(
      BrokenEgg(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        trayCount: trayCount,
        date: DateTime.now(),
        note: note,
      ),
    );
    updatedAt = DateTime.now();
  }

  // Katta tuxum qo'shish
  void addLarge(int trayCount, {String? note}) {
    largeEggs.add(
      LargeEgg(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        trayCount: trayCount,
        date: DateTime.now(),
        note: note,
      ),
    );
    updatedAt = DateTime.now();
  }
}

@HiveType(typeId: 3)
class EggProduction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int trayCount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String? note;

  EggProduction({
    required this.id,
    required this.trayCount,
    required this.date,
    this.note,
  });

  // Firebase serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trayCount': trayCount,
      'date': date.millisecondsSinceEpoch,
      'note': note,
    };
  }

  // Firebase deserialization
  factory EggProduction.fromJson(Map<String, dynamic> json) {
    return EggProduction(
      id: json['id'] as String? ?? '',
      trayCount: json['trayCount'] as int? ?? 0,
      date: _parseDate(json['date']),
      note: json['note'] as String?,
    );
  }
}

@HiveType(typeId: 4)
class EggSale extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int trayCount;

  @HiveField(2)
  double pricePerTray;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? note;

  EggSale({
    required this.id,
    required this.trayCount,
    required this.pricePerTray,
    required this.date,
    this.note,
  });

  // Firebase serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trayCount': trayCount,
      'pricePerTray': pricePerTray,
      'date': date.millisecondsSinceEpoch,
      'note': note,
    };
  }

  // Firebase deserialization
  factory EggSale.fromJson(Map<String, dynamic> json) {
    return EggSale(
      id: json['id'] as String? ?? '',
      trayCount: json['trayCount'] as int? ?? 0,
      pricePerTray: (json['pricePerTray'] as num?)?.toDouble() ?? 0.0,
      date: _parseDate(json['date']),
      note: json['note'] as String?,
    );
  }
}

@HiveType(typeId: 5)
class BrokenEgg extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int trayCount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String? note;

  BrokenEgg({
    required this.id,
    required this.trayCount,
    required this.date,
    this.note,
  });

  // Firebase serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trayCount': trayCount,
      'date': date.millisecondsSinceEpoch,
      'note': note,
    };
  }

  // Firebase deserialization
  factory BrokenEgg.fromJson(Map<String, dynamic> json) {
    return BrokenEgg(
      id: json['id'] as String? ?? '',
      trayCount: json['trayCount'] as int? ?? 0,
      date: _parseDate(json['date']),
      note: json['note'] as String?,
    );
  }
}

@HiveType(typeId: 6)
class LargeEgg extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int trayCount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String? note;

  LargeEgg({
    required this.id,
    required this.trayCount,
    required this.date,
    this.note,
  });

  // Firebase serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trayCount': trayCount,
      'date': date.millisecondsSinceEpoch,
      'note': note,
    };
  }

  // Firebase deserialization
  factory LargeEgg.fromJson(Map<String, dynamic> json) {
    return LargeEgg(
      id: json['id'] as String? ?? '',
      trayCount: json['trayCount'] as int? ?? 0,
      date: _parseDate(json['date']),
      note: json['note'] as String?,
    );
  }
}
