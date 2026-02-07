import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/data_provider.dart';
import '../theme/dark_modern_theme.dart';

/// Dark & Modern Progress Screen
///
/// Features:
/// - Glassmorphism stat cards
/// - Clean charts with primary colors
/// - Compact design
class DarkProgressScreen extends StatefulWidget {
  const DarkProgressScreen({super.key});

  @override
  State<DarkProgressScreen> createState() => _DarkProgressScreenState();
}

class _DarkProgressScreenState extends State<DarkProgressScreen> with SingleTickerProviderStateMixin {
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: DarkModernTheme.background,
        body: const Center(
          child: CircularProgressIndicator(color: DarkModernTheme.primary),
        ),
      );
    }

    final stats = _getLast7DaysStats();
    final totalTasks = _totalTasksCount;
    final totalCompleted = _totalCompletedCount;
    final pendingTasks = totalTasks - totalCompleted;
    final progressPercent = totalTasks == 0 ? 0.0 : totalCompleted / totalTasks;

    return Scaffold(
      backgroundColor: DarkModernTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Compact header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: GlassContainer(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: DarkModernTheme.accentBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.assessment_outlined,
                        color: DarkModernTheme.accentBlue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Progress',
                      style: DarkModernTheme.titleLarge,
                    ),
                    const Spacer(),
                    // Menu button
                    GestureDetector(
                      onTap: () => Scaffold.of(context).openEndDrawer(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.menu,
                          color: DarkModernTheme.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Glass tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: DarkModernTheme.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: DarkModernTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(DarkModernTheme.radiusSmall),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: DarkModernTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Statistics'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(stats, totalTasks, totalCompleted, pendingTasks, progressPercent),
                  _buildStatisticsTab(totalTasks, totalCompleted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, int> stats, int totalTasks, int totalCompleted, int pendingTasks, double progressPercent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last 7 Days Chart
          Text(
            'Last 7 Days',
            style: DarkModernTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DarkModernTheme.surface.withOpacity(0.6),
                  DarkModernTheme.surface.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
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
                    getTooltipColor: (_) => DarkModernTheme.surface.withOpacity(0.9),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.round()}',
                        TextStyle(
                          color: DarkModernTheme.textPrimary,
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
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              dates[value.toInt()],
                              style: TextStyle(
                                color: DarkModernTheme.textTertiary,
                                fontSize: 10,
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
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: DarkModernTheme.textTertiary,
                              fontSize: 10,
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
                      color: DarkModernTheme.textTertiary.withOpacity(0.1),
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
                        gradient: DarkModernTheme.primaryGradient,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Statistics Grid
          Text(
            'Statistics',
            style: DarkModernTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGlassStatCard('Total', '$totalTasks', 'tasks', DarkModernTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGlassStatCard('Completed', '$totalCompleted', 'tasks', DarkModernTheme.accentGreen),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGlassStatCard('Pending', '$pendingTasks', 'tasks', DarkModernTheme.accentYellow),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGlassStatCard('Progress', '${(progressPercent * 100).round()}%', '', DarkModernTheme.accentPurple),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab(int totalTasks, int totalCompleted) {
    final highPriority = _allTodos.where((t) => t.priority == Priority.high).length;
    final mediumPriority = _allTodos.where((t) => t.priority == Priority.medium).length;
    final lowPriority = _allTodos.where((t) => t.priority == Priority.low).length;
    final favorited = _allTodos.where((t) => t.isFavorite).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tasks by Priority
          Text(
            'Tasks by Priority',
            style: DarkModernTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DarkModernTheme.surface.withOpacity(0.6),
                  DarkModernTheme.surface.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildPriorityBar('High', highPriority, totalTasks, DarkModernTheme.accentRed),
                const SizedBox(height: 12),
                _buildPriorityBar('Medium', mediumPriority, totalTasks, DarkModernTheme.accentYellow),
                const SizedBox(height: 12),
                _buildPriorityBar('Low', lowPriority, totalTasks, DarkModernTheme.accentGreen),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tasks by Status
          Text(
            'Tasks by Status',
            style: DarkModernTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DarkModernTheme.surface.withOpacity(0.6),
                  DarkModernTheme.surface.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildStatusRow('Completed', totalCompleted, totalTasks, DarkModernTheme.accentGreen),
                const SizedBox(height: 12),
                _buildStatusRow('Pending', totalTasks - totalCompleted, totalTasks, DarkModernTheme.primary),
                const SizedBox(height: 12),
                _buildStatusRow('Favorited', favorited, totalTasks, DarkModernTheme.accentYellow),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGlassStatCard(String title, String value, String suffix, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.15),
            DarkModernTheme.surface.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$title $suffix'.trim(),
            style: DarkModernTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBar(String label, int count, int total, Color color) {
    final percent = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: DarkModernTheme.bodyMedium,
            ),
            Text(
              '$count tasks',
              style: DarkModernTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: DarkModernTheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percent,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, int count, int total, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: DarkModernTheme.bodyMedium,
          ),
        ),
        Text(
          '$count / $total',
          style: DarkModernTheme.bodySmall,
        ),
      ],
    );
  }
}
