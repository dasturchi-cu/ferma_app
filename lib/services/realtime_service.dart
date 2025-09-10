import 'package:supabase_flutter/supabase_flutter.dart';

typedef RealtimeCallback = void Function(Map<String, dynamic> payload);

/// Service for handling realtime subscriptions and presence
class RealtimeService {
  final RealtimeClient _realtime;
  final SupabaseClient _supabase;

  // Map to store subscription references
  final Map<String, RealtimeChannel> _channels = {};

  /// Create a new RealtimeService instance
  RealtimeService({required SupabaseClient supabaseClient})
    : _supabase = supabaseClient,
      _realtime = supabaseClient.realtime;

  /// Subscribe to table changes
  ///
  /// [table] - The name of the table to subscribe to
  /// [event] - The event type to listen for (INSERT, UPDATE, DELETE, * for all)
  /// [schema] - Database schema (defaults to 'public')
  /// [filter] - Optional filter for the subscription (e.g., 'id=eq.1')
  RealtimeChannel subscribeToTable({
    required String table,
    String event = '*',
    String schema = 'public',
    String? filter,
  }) {
    try {
      final channelName =
          '${table}_$event${filter != null ? '_${filter.hashCode}' : ''}';

      // Return existing channel if it exists
      if (_channels.containsKey(channelName)) {
        return _channels[channelName]!;
      }

      // Create a new channel
      final channel = _realtime.channel(channelName);

      // Build the subscription
      channel.onPostgresChanges(
        event: event == '*'
            ? PostgresChangeEvent.all
            : PostgresChangeEvent.insert,
        schema: schema,
        table: table,
        filter: filter != null
            ? PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: filter,
              )
            : null,
        callback: (payload) {
          // Handle the payload in the callback
          print('Realtime update for $table: $payload');
        },
      );

      // Subscribe to the channel
      channel.subscribe();

      // Store the channel reference
      _channels[channelName] = channel;

      return channel;
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribe(String channelName) async {
    try {
      final channel = _channels[channelName];
      if (channel != null) {
        await _realtime.removeChannel(channel);
        _channels.remove(channelName);
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  /// Unsubscribe from all channels
  Future<void> unsubscribeAll() async {
    try {
      for (final channel in _channels.values) {
        await _realtime.removeChannel(channel);
      }
      _channels.clear();
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  /// Initialize user-specific subscriptions
  Future<void> initializeUserSubscriptions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Subscribe to user-specific notifications
      subscribeToTable(table: 'notifications', filter: 'user_id=eq.$userId');

      // Track user presence
      await _trackUserPresence(userId);
    } catch (e) {
      print('Error initializing user subscriptions: $e');
      rethrow;
    }
  }

  /// Track user presence in the application
  Future<void> _trackUserPresence(String userId) async {
    try {
      final presenceChannel = _realtime.channel('presence:users');

      // Track when this client joins the presence channel
      await presenceChannel.track({
        'user_id': userId,
        'last_seen': DateTime.now().toIso8601String(),
        'status': 'online',
      });

      // Handle presence state changes
      presenceChannel
        ..onPresenceSync((payload) {
          final state = presenceChannel.presenceState();
          print('Presence state synced: $state');
        })
        ..onPresenceJoin((payload) {
          print('User joined: $payload');
        })
        ..onPresenceLeave((payload) {
          print('User left: $payload');
        });

      // Store the presence channel
      _channels['presence:users'] = presenceChannel;
    } catch (e) {
      print('Error tracking user presence: $e');
      rethrow;
    }
  }

  /// Update authentication token for realtime connections
  void updateAuthToken() {
    try {
      // Supabase client automatically handles token refresh
      // This method is a placeholder for any additional token update logic
    } catch (e) {
      print('Error updating auth token: $e');
      rethrow;
    }
  }

  /// Subscribe to presence channel
  RealtimeChannel subscribeToPresence({
    required String channelName,
    required Map<String, dynamic> presenceData,
  }) {
    try {
      final channel = _realtime.channel(channelName);

      channel
        ..onPresenceSync((payload) {
          print('Presence synced: ${channel.presenceState()}');
        })
        ..onPresenceJoin((payload) {
          print('User joined: $payload');
        })
        ..onPresenceLeave((payload) {
          print('User left: $payload');
        });

      // Track presence
      channel.track(presenceData);

      // Subscribe to the channel
      channel.subscribe();

      // Store the channel reference
      _channels[channelName] = channel;

      return channel;
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  /// Send a broadcast message to a channel
  Future<void> broadcast({
    required String channelName,
    required String event,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final channel = _channels[channelName];
      if (channel != null) {
        // Broadcast functionality - simplified for now
        print('Broadcast to $channelName: $event - $payload');
        // TODO: Implement proper broadcast when Supabase client supports it
      } else {
        throw Exception('Channel $channelName not found');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  /// Listen to broadcast messages on a channel
  void listenToBroadcast({
    required String channelName,
    required String event,
    required Function(Map<String, dynamic> payload) onData,
  }) {
    try {
      final channel = _channels[channelName];
      if (channel != null) {
        channel.onBroadcast(
          event: event,
          callback: (payload) => onData(payload),
        );
      } else {
        throw Exception('Channel $channelName not found');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  /// Close all connections and clean up
  Future<void> dispose() async {
    try {
      await unsubscribeAll();
      // No need to dispose the realtime client as it's managed by Supabase
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }
}
