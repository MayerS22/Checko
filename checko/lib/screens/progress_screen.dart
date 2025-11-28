import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../database/firestore_service.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  List<Todo> _allTodos = [];
  Map<DateTime, int> _heatmapData = {};
  Map<int, int> _hourlyData = {};
  bool _isLoading = true;
  late TabController _tabController;
  late DateTime _selectedMonth;
  String? _myDayListId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedMonth = DateTime.now();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final lists = await FirestoreService.instance.readAllTodoLists();
    final todos = await FirestoreService.instance.readAllTodos();
    final heatmap = await FirestoreService.instance.getMonthlyHeatmapData(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final hourly = await FirestoreService.instance.getProductivityByHour();
    
    if (!mounted) return;
    setState(() {
      _allTodos = todos;
      _heatmapData = heatmap;
      _hourlyData = hourly;
      final myDay = lists.firstWhere(
        (l) => l.name == 'My Day',
        orElse: () => TodoList(id: '', name: ''),
      );
      _myDayListId = myDay.id.isEmpty ? null : myDay.id;
      _isLoading = false;
    });
  }

  Map<String, int> _getLast7DaysStats() {
    final Map<String, int> stats = {};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateFormat('MM/dd').format(date);
      stats[dateKey] = 0;
    }

    for (var todo in _allTodos) {
      if (todo.isCompleted && todo.completedAt != null) {
        final dateKey = DateFormat('MM/dd').format(todo.completedAt!);
        if (stats.containsKey(dateKey)) {
          stats[dateKey] = stats[dateKey]! + 1;
        }
      }
    }

    return stats;
  }

  int get _todayCompletedCount {
    final today = DateTime.now();
    return _allTodos.where((todo) {
      return _isInMyDay(todo, today) && todo.isCompleted;
    }).length;
  }

  int get _todayTotalCount {
    final today = DateTime.now();
    return _allTodos.where((todo) {
      return _isInMyDay(todo, today);
    }).length;
  }

  int get _totalCompleted => _allTodos.where((t) => t.isCompleted).length;
  int get _totalTasks => _allTodos.length;
  double get _overallProgress =>
      _totalTasks == 0 ? 0 : _totalCompleted / _totalTasks;

  int get _mostProductiveHour {
    if (_hourlyData.isEmpty) return 9;
    int maxHour = 0;
    int maxCount = 0;
    _hourlyData.forEach((hour, count) {
      if (count > maxCount) {
        maxCount = count;
        maxHour = hour;
      }
    });
    return maxHour;
  }

  bool _isSameDay(DateTime? date, DateTime other) {
    if (date == null) return false;
    return date.year == other.year &&
        date.month == other.month &&
        date.day == other.day;
  }

  bool _isInMyDay(Todo todo, DateTime today) {
    final inMyDayList = _myDayListId != null && todo.listId == _myDayListId;
    final dueToday = _isSameDay(todo.dueDate, today);
    // My Day shows tasks due today regardless of list, or anything explicitly in My Day
    return inMyDayList || dueToday;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final stats = _getLast7DaysStats();
    final todayTotal = _todayTotalCount;
    final todayProgress =
        todayTotal == 0 ? 0.0 : _todayCompletedCount / todayTotal;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.backgroundColor,
                  AppColors.accent.withValues(alpha: 0.14),
                  AppColors.accentAlt.withValues(alpha: 0.14),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome ${userProvider.username}',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.surfaceElevatedColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.outlineColor),
                            ),
                            child: const Icon(
                              Icons.show_chart,
                              color: AppColors.accentAlt,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Checko',
                                style: TextStyle(
                                  color: context.textMutedColor,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Progress',
                                style: TextStyle(
                                  color: context.textPrimaryColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Refresh stats',
                            icon: const Icon(Icons.refresh),
                            color: context.textPrimaryColor,
                            onPressed: _loadData,
                          ),
                          // Streak badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.warning.withValues(alpha: 0.3),
                                  AppColors.danger.withValues(alpha: 0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text(
                                  '${userProvider.currentStreak}',
                                  style: TextStyle(
                                    color: context.textPrimaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: context.panelColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Tab bar
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.accent, AppColors.accentAlt],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: context.textMutedColor,
                              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(text: 'Overview'),
                                Tab(text: 'Heatmap'),
                                Tab(text: 'Insights'),
                              ],
                            ),
                          ),
                        ),
                        
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildOverviewTab(stats, todayProgress, userProvider),
                              _buildHeatmapTab(),
                              _buildInsightsTab(userProvider),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, int> stats, double todayProgress, UserProvider userProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last 7 Days Chart
          Text(
            'Last 7 Days',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.outlineColor),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (stats.values.isEmpty
                        ? 5
                        : stats.values.reduce((a, b) => a > b ? a : b) + 2)
                    .toDouble(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => context.surfaceElevatedColor,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.round()} tasks',
                        TextStyle(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final dates = stats.keys.toList();
                        if (value.toInt() >= 0 && value.toInt() < dates.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dates[value.toInt()],
                              style: TextStyle(
                                color: context.textMutedColor,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: context.textMutedColor,
                              fontSize: 11,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: context.outlineColor, strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: stats.entries.toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final count = entry.value.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.accentAlt],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Overall Statistics
          Text(
            'Overall Statistics',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total Tasks', _totalTasks.toString(), Icons.task_alt, AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Completed', _totalCompleted.toString(), Icons.check_circle, AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Pending', (_totalTasks - _totalCompleted).toString(), Icons.pending, AppColors.accentAlt),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Success Rate', '${(_overallProgress * 100).round()}%', Icons.trending_up, AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeatmapTab() {
    final now = DateTime.now();
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: context.textPrimaryColor),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                  });
                  _loadData();
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: context.textPrimaryColor),
                onPressed: _selectedMonth.isBefore(DateTime(now.year, now.month))
                    ? () {
                        setState(() {
                          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                        });
                        _loadData();
                      }
                    : null,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Weekday labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: context.textMutedColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          
          const SizedBox(height: 8),
          
          // Heatmap grid
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.outlineColor),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: daysInMonth + firstWeekday - 1,
              itemBuilder: (context, index) {
                if (index < firstWeekday - 1) {
                  return const SizedBox();
                }
                
                final day = index - firstWeekday + 2;
                final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
                final count = _heatmapData[date] ?? 0;
                
                Color cellColor;
                if (count == 0) {
                  cellColor = context.outlineColor;
                } else if (count <= 2) {
                  cellColor = AppColors.success.withValues(alpha: 0.3);
                } else if (count <= 4) {
                  cellColor = AppColors.success.withValues(alpha: 0.5);
                } else if (count <= 6) {
                  cellColor = AppColors.success.withValues(alpha: 0.7);
                } else {
                  cellColor = AppColors.success;
                }
                
                final isToday = date.year == now.year && 
                    date.month == now.month && 
                    date.day == now.day;

                return Tooltip(
                  message: '$count tasks completed',
                  child: Container(
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(6),
                      border: isToday
                          ? Border.all(color: AppColors.accent, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: count > 0 ? Colors.white : context.textMutedColor,
                          fontSize: 12,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Less', style: TextStyle(color: context.textMutedColor, fontSize: 12)),
              const SizedBox(width: 8),
              ...[0.1, 0.3, 0.5, 0.7, 1.0].map((opacity) => Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
              const SizedBox(width: 8),
              Text('More', style: TextStyle(color: context.textMutedColor, fontSize: 12)),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Monthly summary
          Text(
            'Monthly Summary',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.outlineColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_heatmapData.values.fold(0, (a, b) => a + b)}',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tasks Completed',
                        style: TextStyle(color: context.textMutedColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: context.outlineColor,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_heatmapData.values.where((v) => v > 0).length}',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Active Days',
                        style: TextStyle(color: context.textMutedColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(UserProvider userProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak stats
          Text(
            'Your Streaks',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStreakCard(
                  '🔥',
                  'Current Streak',
                  '${userProvider.currentStreak} days',
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStreakCard(
                  '🏆',
                  'Best Streak',
                  '${userProvider.longestStreak} days',
                  AppColors.accent,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Productivity by hour
          Text(
            'Most Productive Hours',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.outlineColor),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: context.outlineColor, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}h',
                          style: TextStyle(color: context.textMutedColor, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(24, (i) => FlSpot(i.toDouble(), (_hourlyData[i] ?? 0).toDouble())),
                    isCurved: true,
                    gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentAlt]),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppColors.accent.withValues(alpha: 0.3), AppColors.accentAlt.withValues(alpha: 0.1)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peak Productivity',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'You\'re most productive around $_mostProductiveHour:00',
                        style: TextStyle(color: context.textMutedColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Priority breakdown
          Text(
            'Task Priority Breakdown',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriorityBreakdown(),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.outlineColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: context.textMutedColor, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: context.textMutedColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBreakdown() {
    final high = _allTodos.where((t) => t.priority == Priority.high).length;
    final medium = _allTodos.where((t) => t.priority == Priority.medium).length;
    final low = _allTodos.where((t) => t.priority == Priority.low).length;
    final total = _totalTasks.toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.outlineColor),
      ),
      child: Column(
        children: [
          _buildPriorityRow('High', high, total, AppColors.priorityHigh),
          const SizedBox(height: 12),
          _buildPriorityRow('Medium', medium, total, AppColors.priorityMedium),
          const SizedBox(height: 12),
          _buildPriorityRow('Low', low, total, AppColors.priorityLow),
        ],
      ),
    );
  }

  Widget _buildPriorityRow(String label, int count, double total, Color color) {
    final percentage = total == 0 ? 0.0 : count / total;
    
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(label, style: TextStyle(color: context.textPrimaryColor)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: context.outlineColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$count',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
