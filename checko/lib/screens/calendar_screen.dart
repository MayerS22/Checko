import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../models/todo.dart';
import '../providers/data_provider.dart';
import '../theme/ms_todo_colors.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Event> _events = [];
  List<Todo> _todosWithDates = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    final dataProvider = context.read<DataProvider>();
    final events = dataProvider.events;
    final todos = dataProvider.todos;
    final todosWithDates = todos.where((t) => t.dueDate != null).toList();

    setState(() {
      _events = events;
      _todosWithDates = todosWithDates;
    });
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final events = _events.where((event) {
      return isSameDay(event.startTime, day);
    }).toList();

    final todos = _todosWithDates.where((todo) {
      return isSameDay(todo.dueDate, day);
    }).toList();

    return [...events, ...todos];
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final dataProvider = context.watch<DataProvider>();
    final selectedDayEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

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
                  Icons.calendar_month,
                  color: MSToDoColors.msBlue,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Calendar',
                  style: TextStyle(
                    color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Calendar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
              ),
            ),
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  border: Border.all(
                    color: MSToDoColors.msBlue,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: MSToDoColors.msBlue,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: MSToDoColors.msBlue,
                  shape: BoxShape.circle,
                ),
                markerSizeScale: 0.1,
                markersMaxCount: 3,
                weekendTextStyle: TextStyle(
                  color: MSToDoColors.msTextSecondary,
                ),
                defaultTextStyle: TextStyle(
                  color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                ),
                outsideTextStyle: TextStyle(
                  color: MSToDoColors.msTextSecondary.withOpacity(0.5),
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                ),
                todayTextStyle: TextStyle(
                  color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                titleTextStyle: TextStyle(
                  color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                formatButtonTextStyle: TextStyle(
                  color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: MSToDoColors.msTextSecondary,
                  fontSize: 14,
                ),
                weekendStyle: TextStyle(
                  color: MSToDoColors.msTextSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // Selected date header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  _selectedDay != null
                      ? DateFormat('EEEE, MMMM d').format(_selectedDay!)
                      : 'Select a date',
                  style: TextStyle(
                    color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${selectedDayEvents.length} item${selectedDayEvents.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: MSToDoColors.msTextSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Events/Tasks list
          Expanded(
            child: selectedDayEvents.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: selectedDayEvents.length,
                    itemBuilder: (context, index) {
                      final item = selectedDayEvents[index];
                      if (item is Event) {
                        return _buildEventItem(item, isDark);
                      } else if (item is Todo) {
                        return _buildTodoItem(item, isDark);
                      }
                      return const SizedBox();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: MSToDoColors.msTextSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No events or tasks',
            style: TextStyle(
              color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add an event for this day',
            style: TextStyle(
              color: MSToDoColors.msTextSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(Event event, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
        border: Border.all(
          color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event,
                color: MSToDoColors.msBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
                  style: TextStyle(
                    color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (event.description != null) ...[
            const SizedBox(height: 4),
            Text(
              event.description!,
              style: TextStyle(
                color: MSToDoColors.msTextSecondary,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time, color: MSToDoColors.msTextSecondary, size: 14),
              const SizedBox(width: 4),
              Text(
                '${DateFormat('hh:mm a').format(event.startTime)} - ${DateFormat('hh:mm a').format(event.endTime)}',
                style: TextStyle(
                  color: MSToDoColors.msTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodoItem(Todo todo, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
        border: Border.all(
          color: todo.isCompleted ? MSToDoColors.success : (isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: todo.isCompleted ? MSToDoColors.success : MSToDoColors.msTextSecondary,
                width: 2,
              ),
              color: todo.isCompleted ? MSToDoColors.success : null,
            ),
            child: todo.isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              todo.title,
              style: TextStyle(
                color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                fontSize: 15,
                decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
