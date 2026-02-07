import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../providers/data_provider.dart';
import '../theme/ms_todo_colors.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  List<Todo> _allTodos = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final dataProvider = context.read<DataProvider>();
    await dataProvider.initialize();
    if (!mounted) return;
    setState(() {
      _allTodos = dataProvider.todos;
      _isLoading = false;
    });
  }

  int get _totalCompletedCount => _allTodos.where((t) => t.isCompleted).length;
  int get _totalTasksCount => _allTodos.length;

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

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? MSToDoColors.msBackgroundDark : MSToDoColors.msBackground,
        body: const Center(
          child: CircularProgressIndicator(color: MSToDoColors.msBlue),
        ),
      );
    }

    final stats = _getLast7DaysStats();
    final totalTasks = _totalTasksCount;
    final totalCompleted = _totalCompletedCount;
    final pendingTasks = totalTasks - totalCompleted;
    final progressPercent = totalTasks == 0 ? 0.0 : totalCompleted / totalTasks;

    return Scaffold(
      backgroundColor: isDark ? MSToDoColors.msBackgroundDark : MSToDoColors.msBackground,
      body: Column(
        children: [
          // Clean header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 65, 16, 8),
            decoration: BoxDecoration(
              color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.show_chart,
                  color: MSToDoColors.msBlue,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Progress',
                  style: TextStyle(
                    color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Simple tab bar with underline
          Container(
            decoration: BoxDecoration(
              color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: MSToDoColors.msBlue,
                  width: 2,
                ),
              ),
              labelColor: MSToDoColors.msTextSecondary,
              unselectedLabelColor: MSToDoColors.msTextSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w500),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Statistics'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(stats, totalTasks, totalCompleted, pendingTasks, progressPercent, isDark),
                _buildStatisticsTab(totalTasks, totalCompleted, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, int> stats, int totalTasks, int totalCompleted, int pendingTasks, double progressPercent, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last 7 Days Chart
          Text(
            'Last 7 Days',
            style: TextStyle(
              color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
              border: Border.all(
                color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
              ),
              borderRadius: BorderRadius.circular(4),
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
                    getTooltipColor: (_) => isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.round()} tasks',
                        TextStyle(
                          color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                          fontWeight: FontWeight.w500,
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
                                color: MSToDoColors.msTextSecondary,
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
                              color: MSToDoColors.msTextSecondary,
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
                    return FlLine(
                      color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
                      strokeWidth: 1,
                    );
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
                        color: MSToDoColors.msBlue,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Overall Statistics Grid
          Text(
            'Statistics',
            style: TextStyle(
              color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSimpleStatCard('Total', '$totalTasks', 'tasks', isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleStatCard('Completed', '$totalCompleted', 'tasks', isDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSimpleStatCard('Pending', '$pendingTasks', 'tasks', isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleStatCard('Progress', '${(progressPercent * 100).round()}%', '', isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab(int totalTasks, int totalCompleted, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tasks by Priority
          Text(
            'Tasks by Priority',
            style: TextStyle(
              color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
              border: Border.all(
                color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                _buildPriorityRow('High', _allTodos.where((t) => t.priority == Priority.high).length, MSToDoColors.priorityHigh, isDark),
                const SizedBox(height: 16),
                _buildPriorityRow('Medium', _allTodos.where((t) => t.priority == Priority.medium).length, MSToDoColors.priorityMedium, isDark),
                const SizedBox(height: 16),
                _buildPriorityRow('Low', _allTodos.where((t) => t.priority == Priority.low).length, MSToDoColors.priorityLow, isDark),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tasks by Status
          Text(
            'Tasks by Status',
            style: TextStyle(
              color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
              border: Border.all(
                color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                _buildStatusRow('Completed', totalCompleted, totalTasks, MSToDoColors.success, isDark),
                const SizedBox(height: 16),
                _buildStatusRow('Pending', totalTasks - totalCompleted, totalTasks, MSToDoColors.msBlue, isDark),
                const SizedBox(height: 16),
                _buildStatusRow('Favorited', _allTodos.where((t) => t.isFavorite).length, totalTasks, MSToDoColors.warning, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStatCard(String title, String value, String suffix, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
        border: Border.all(
          color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: MSToDoColors.msBlue,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$title$suffix',
            style: TextStyle(
              color: MSToDoColors.msTextSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityRow(String label, int count, Color color, bool isDark) {
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
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
              fontSize: 15,
            ),
          ),
        ),
        Text(
          '$count tasks',
          style: TextStyle(
            color: MSToDoColors.msTextSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, int count, int total, Color color, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
              fontSize: 15,
            ),
          ),
        ),
        Text(
          '$count / $total',
          style: TextStyle(
            color: MSToDoColors.msTextSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
