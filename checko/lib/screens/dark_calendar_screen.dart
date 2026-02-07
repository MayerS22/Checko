import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../models/todo.dart';
import '../providers/data_provider.dart';
import '../theme/dark_modern_theme.dart';
import '../screens/dark_create_event_screen.dart';

/// Dark & Modern Calendar Screen
///
/// Features:
/// - Glassmorphism calendar widget
/// - Events and tasks on selected day
/// - Clean, compact design
class DarkCalendarScreen extends StatefulWidget {
  const DarkCalendarScreen({super.key});

  @override
  State<DarkCalendarScreen> createState() => _DarkCalendarScreenState();
}

class _DarkCalendarScreenState extends State<DarkCalendarScreen> {
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
    final events = _events.where((event) => _eventOccursOnDay(event, day)).toList();

    final todos = _todosWithDates.where((todo) {
      return isSameDay(todo.dueDate, day);
    }).toList();

    return [...events, ...todos];
  }

  /// Check if an event occurs on a specific day
  /// This handles multi-day events that span multiple calendar days
  bool _eventOccursOnDay(Event event, DateTime day) {
    // Normalize the day to midnight for comparison
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // Normalize event dates
    final eventStart = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
    final eventEnd = DateTime(event.endTime.year, event.endTime.month, event.endTime.day).add(const Duration(days: 1));

    // Check if the event overlaps with this day
    // Event starts before or on this day AND ends after this day starts
    return eventStart.isBefore(dayEnd) && eventEnd.isAfter(dayStart);
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Scaffold(
      backgroundColor: DarkModernTheme.background,
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_calendar',
        onPressed: () => _createEvent(),
        backgroundColor: DarkModernTheme.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.add, size: 28),
      ),
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
                        color: DarkModernTheme.accentPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_month,
                        color: DarkModernTheme.accentPurple,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Calendar',
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

            // Calendar with glass effect
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DarkModernTheme.surface.withOpacity(0.8),
                    DarkModernTheme.surface.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
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
                      color: DarkModernTheme.primary,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    gradient: DarkModernTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: DarkModernTheme.accentPurple,
                    shape: BoxShape.circle,
                  ),
                  markerSizeScale: 0.15,
                  markersMaxCount: 4,
                  weekendTextStyle: TextStyle(
                    color: DarkModernTheme.textSecondary,
                    fontSize: 14,
                  ),
                  defaultTextStyle: TextStyle(
                    color: DarkModernTheme.textPrimary,
                    fontSize: 14,
                  ),
                  outsideTextStyle: TextStyle(
                    color: DarkModernTheme.textTertiary.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  todayTextStyle: TextStyle(
                    color: DarkModernTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  titleTextStyle: TextStyle(
                    color: DarkModernTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  formatButtonTextStyle: TextStyle(
                    color: DarkModernTheme.textPrimary,
                    fontSize: 13,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: DarkModernTheme.textSecondary,
                    size: 20,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: DarkModernTheme.textSecondary,
                    size: 20,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: DarkModernTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  weekendStyle: TextStyle(
                    color: DarkModernTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Selected date header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassContainer(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Text(
                      _selectedDay != null
                          ? DateFormat('EEEE, MMM d').format(_selectedDay!)
                          : 'Select a date',
                      style: DarkModernTheme.titleMedium,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: DarkModernTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${selectedDayEvents.length}',
                        style: TextStyle(
                          color: DarkModernTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Events/Tasks list
            Expanded(
              child: selectedDayEvents.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: selectedDayEvents.length,
                      itemBuilder: (context, index) {
                        final item = selectedDayEvents[index];
                        if (item is Event) {
                          return _buildEventItem(item);
                        } else if (item is Todo) {
                          return _buildTodoItem(item);
                        }
                        return const SizedBox();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: DarkModernTheme.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No events or tasks',
            style: DarkModernTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Add an event for this day',
            style: DarkModernTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(Event event) {
    final isMultiDay = !_isSameDay(event.startTime, event.endTime);
    final dateFormat = DateFormat('MMM d');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
          color: event.eventColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: event.eventColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.event,
                    color: event.eventColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    event.title,
                    style: DarkModernTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            if (event.description != null) ...[
              const SizedBox(height: 4),
              Text(
                event.description!,
                style: DarkModernTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time, color: DarkModernTheme.textTertiary, size: 12),
                const SizedBox(width: 4),
                if (isMultiDay) ...[
                  Text(
                    '${dateFormat.format(event.startTime)} - ${dateFormat.format(event.endTime)}',
                    style: DarkModernTheme.bodySmall.copyWith(
                      color: DarkModernTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else ...[
                  Text(
                    '${DateFormat('hh:mm a').format(event.startTime)} - ${DateFormat('hh:mm a').format(event.endTime)}',
                    style: DarkModernTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoItem(Todo todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
          color: todo.isCompleted
              ? DarkModernTheme.accentGreen.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: todo.isCompleted
                      ? DarkModernTheme.accentGreen
                      : DarkModernTheme.textTertiary,
                  width: 2,
                ),
                color: todo.isCompleted
                    ? DarkModernTheme.accentGreen.withOpacity(0.3)
                    : null,
              ),
              child: todo.isCompleted
                  ? const Icon(Icons.check, color: DarkModernTheme.accentGreen, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                todo.title,
                style: DarkModernTheme.bodyLarge.copyWith(
                  decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                  color: todo.isCompleted ? DarkModernTheme.textTertiary : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createEvent() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DarkCreateEventScreen(
          initialDate: _selectedDay,
        ),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }
}
