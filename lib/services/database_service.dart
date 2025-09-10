import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

// Model imports
import '../models/farm.dart';
import '../models/chicken.dart';
import '../models/egg.dart';
import '../models/customer.dart';

class DatabaseService {
  final _supabase = SupabaseConfig.client;

  // Generic CRUD Operations
  Future<List<Map<String, dynamic>>> getCollection(
    String tableName, {
    String? filterColumn,
    dynamic filterValue,
    int? limit,
    int? offset,
    String? orderBy,
    bool ascending = true,
  }) async {
    try {
      dynamic query = _supabase.from(tableName).select();

      if (filterColumn != null && filterValue != null) {
        query = query.eq(filterColumn, filterValue);
      }

      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        final actualLimit = limit ?? 10;
        query = query.range(offset, offset + actualLimit - 1);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error in getCollection: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDocument(String tableName, String id) async {
    return await _supabase.from(tableName).select().eq('id', id).single();
  }

  Future<Map<String, dynamic>> createDocument(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    final response = await _supabase
        .from(tableName)
        .insert(data)
        .select()
        .single();

    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateDocument(
    String tableName,
    String id,
    Map<String, dynamic> updates,
  ) async {
    final response = await _supabase
        .from(tableName)
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return response as Map<String, dynamic>;
  }

  Future<void> deleteDocument(String tableName, String id) async {
    await _supabase.from(tableName).delete().eq('id', id);
  }

  // Realtime Subscriptions
  Stream<List<Map<String, dynamic>>> streamCollection(
    String tableName, {
    String? filterColumn,
    dynamic filterValue,
  }) {
    try {
      var query = _supabase.from(tableName);

      if (filterColumn != null && filterValue != null) {
        return query.stream(primaryKey: ['id']).eq(filterColumn, filterValue);
      }

      return query.stream(primaryKey: ['id']);
    } catch (e) {
      print('Error in streamCollection: $e');
      rethrow;
    }
  }

  // Farm Operations
  Future<Farm> createFarm(Farm farm) async {
    final data = farm.toJson();
    final response = await _supabase
        .from('farms')
        .insert(data)
        .select()
        .single();
    return Farm.fromJson(response as Map<String, dynamic>);
  }

  Future<Farm> updateFarm(Farm farm) async {
    final data = farm.toJson();
    final response = await _supabase
        .from('farms')
        .update(data)
        .eq('id', farm.id)
        .select()
        .single();
    return Farm.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteFarm(String farmId) async {
    await _supabase.from('farms').delete().eq('id', farmId);
  }

  // Chicken Operations
  Future<List<Chicken>> getChickens(String farmId) async {
    final response = await getCollection(
      'chickens',
      filterColumn: 'farm_id',
      filterValue: farmId,
    );
    return response.map((e) => Chicken.fromJson(e)).toList();
  }

  Future<Chicken> createChicken(Chicken chicken) async {
    final data = chicken.toJson();
    final response = await _supabase
        .from('chickens')
        .insert(data)
        .select()
        .single();
    return Chicken.fromJson(response as Map<String, dynamic>);
  }

  // Egg Production Operations
  Future<List<EggProduction>> getEggProductions(String farmId) async {
    final response = await getCollection(
      'egg_productions',
      filterColumn: 'farm_id',
      filterValue: farmId,
      orderBy: 'date',
      ascending: false,
    );
    return response.map((e) => EggProduction.fromJson(e)).toList();
  }

  Future<EggProduction> createEggProduction(EggProduction production) async {
    final data = production.toJson();
    final response = await _supabase
        .from('egg_productions')
        .insert(data)
        .select()
        .single();
    return EggProduction.fromJson(response as Map<String, dynamic>);
  }

  // Customer Operations
  Future<List<Customer>> getCustomers(String farmId) async {
    final response = await getCollection(
      'customers',
      filterColumn: 'farm_id',
      filterValue: farmId,
    );
    return response.map((e) => Customer.fromJson(e)).toList();
  }

  Future<Customer> createCustomer(Customer customer) async {
    final data = customer.toJson();
    final response = await _supabase
        .from('customers')
        .insert(data)
        .select()
        .single();
    return Customer.fromJson(response as Map<String, dynamic>);
  }

  // Add more specific methods as needed
}
