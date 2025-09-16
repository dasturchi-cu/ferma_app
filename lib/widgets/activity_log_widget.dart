import 'package:flutter/material.dart';
import 'dart:async';
import '../models/activity_log.dart';
import '../services/activity_log_service.dart';
import '../utils/app_theme.dart';
import '../providers/farm_provider.dart';

class ActivityLogWidget extends StatefulWidget {
  final String farmId;
  final int maxItems;
  final bool showTitle;
  final double height;

  const ActivityLogWidget({
    super.key,
    required this.farmId,
    this.maxItems = 10,
    this.showTitle = true,
    this.height = 300,
  });

  @override
  State<ActivityLogWidget> createState() => _ActivityLogWidgetState();
}

class _ActivityLogWidgetState extends State<ActivityLogWidget> {
  List<ActivityLog> _activities = [];
  bool _isLoading = true;
  
  // REAL-TIME UPDATE: Refresh every 10 seconds
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _startAutoRefresh();
    
    // Register callback for immediate updates when activity logs are added
    FarmProvider.onActivityLogUpdated = () {
      if (mounted) {
        _loadActivities(showLoading: false);
      }
    };
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    // Clean up callback
    FarmProvider.onActivityLogUpdated = null;
    super.dispose();
  }
  
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadActivities(showLoading: false); // Silent refresh
      }
    });
  }

  Future<void> _loadActivities({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }
    
    try {
      // First clean old logs to keep only recent ones
      await ActivityLogService.clearOldLogs(keepCount: 50);
      
      final activities = await ActivityLogService.getRecentActivityLogs(
        farmId: widget.farmId,
        limit: widget.maxItems,
      );
      
      if (mounted) {
        setState(() {
          _activities = activities;
          _isLoading = false;
        });
        // Silent update
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('❌ Activity Log yuklashda xatolik: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle) _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _activities.isEmpty
                    ? _buildEmptyState()
                    : _buildActivityList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'So\'nggi Harakatlar',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: _loadActivities,
            child: Icon(
              Icons.refresh,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Hech qanday harakat topilmadi',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ishlarni boshlasangiz, ular bu yerda ko\'rinadi',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: _activities.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return _buildActivityItem(activity);
      },
    );
  }

  Widget _buildActivityItem(ActivityLog activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActivityIcon(activity),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  activity.formattedDate,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _buildImportanceBadge(activity.importance),
        ],
      ),
    );
  }

  Widget _buildActivityIcon(ActivityLog activity) {
    Color backgroundColor;
    IconData iconData;
    Color iconColor = Colors.white;

    switch (activity.type) {
      case ActivityType.eggProduction:
        backgroundColor = Colors.green;
        iconData = Icons.egg_outlined;
        break;
      case ActivityType.eggSale:
        backgroundColor = Colors.blue;
        iconData = Icons.monetization_on;
        break;
      case ActivityType.customerAdded:
        backgroundColor = Colors.purple;
        iconData = Icons.person_add;
        break;
      case ActivityType.debtAdded:
        backgroundColor = Colors.orange;
        iconData = Icons.credit_card;
        break;
      case ActivityType.debtPaid:
        backgroundColor = Colors.green;
        iconData = Icons.payment;
        break;
      case ActivityType.chickenAdded:
        backgroundColor = Colors.teal;
        iconData = Icons.add_circle;
        break;
      case ActivityType.chickenDeath:
        backgroundColor = Colors.red;
        iconData = Icons.warning;
        break;
      case ActivityType.brokenEggs:
        backgroundColor = Colors.red.shade300;
        iconData = Icons.broken_image;
        break;
      case ActivityType.largeEggs:
        backgroundColor = Colors.amber;
        iconData = Icons.star;
        break;
      case ActivityType.other:
      default:
        backgroundColor = Colors.grey;
        iconData = Icons.info;
        break;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 18,
      ),
    );
  }

  Widget _buildImportanceBadge(ActivityImportance importance) {
    if (importance == ActivityImportance.normal || importance == ActivityImportance.low) {
      return const SizedBox.shrink();
    }

    Color color;
    String text;

    switch (importance) {
      case ActivityImportance.high:
        color = Colors.orange;
        text = '!';
        break;
      case ActivityImportance.critical:
        color = Colors.red;
        text = '!!';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ActivityLogScreen extends StatefulWidget {
  final String farmId;

  const ActivityLogScreen({
    super.key,
    required this.farmId,
  });

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ActivityLog> _allActivities = [];
  List<ActivityLog> _todayActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      final [allActivities, todayActivities] = await Future.wait([
        ActivityLogService.getRecentActivityLogs(
          farmId: widget.farmId,
          limit: 100,
        ),
        ActivityLogService.getTodayActivityLogs(widget.farmId),
      ]);

      setState(() {
        _allActivities = allActivities as List<ActivityLog>;
        _todayActivities = todayActivities as List<ActivityLog>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading activities: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('So\'nggi Harakatlar'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'Bugun (${_todayActivities.length})',
              icon: const Icon(Icons.today, size: 20),
            ),
            Tab(
              text: 'Hammasi (${_allActivities.length})',
              icon: const Icon(Icons.history, size: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadActivities,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActivityList(_todayActivities),
                _buildActivityList(_allActivities),
              ],
            ),
    );
  }

  Widget _buildActivityList(List<ActivityLog> activities) {
    if (activities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Hech qanday harakat topilmadi',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActivities,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: activities.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildFullActivityCard(activity);
        },
      ),
    );
  }

  Widget _buildFullActivityCard(ActivityLog activity) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActivityIcon(activity),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _buildImportanceBadge(activity.importance),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity.formattedDate,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activity.type.displayName,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityIcon(ActivityLog activity) {
    Color backgroundColor;
    IconData iconData;

    switch (activity.type) {
      case ActivityType.eggProduction:
        backgroundColor = Colors.green;
        iconData = Icons.egg_outlined;
        break;
      case ActivityType.eggSale:
        backgroundColor = Colors.blue;
        iconData = Icons.monetization_on;
        break;
      case ActivityType.customerAdded:
        backgroundColor = Colors.purple;
        iconData = Icons.person_add;
        break;
      case ActivityType.debtAdded:
        backgroundColor = Colors.orange;
        iconData = Icons.credit_card;
        break;
      case ActivityType.debtPaid:
        backgroundColor = Colors.green;
        iconData = Icons.payment;
        break;
      case ActivityType.chickenAdded:
        backgroundColor = Colors.teal;
        iconData = Icons.add_circle;
        break;
      case ActivityType.chickenDeath:
        backgroundColor = Colors.red;
        iconData = Icons.warning;
        break;
      case ActivityType.brokenEggs:
        backgroundColor = Colors.red.shade300;
        iconData = Icons.broken_image;
        break;
      case ActivityType.largeEggs:
        backgroundColor = Colors.amber;
        iconData = Icons.star;
        break;
      case ActivityType.other:
      default:
        backgroundColor = Colors.grey;
        iconData = Icons.info;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        iconData,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildImportanceBadge(ActivityImportance importance) {
    if (importance == ActivityImportance.normal || importance == ActivityImportance.low) {
      return const SizedBox.shrink();
    }

    Color color;
    String text;

    switch (importance) {
      case ActivityImportance.high:
        color = Colors.orange;
        text = 'Muhim';
        break;
      case ActivityImportance.critical:
        color = Colors.red;
        text = 'Juda Muhim';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}