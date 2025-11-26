import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../models/todo.dart';
import '../database/firestore_service.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final events = await FirestoreService.instance.readAllEvents();
    final todos = await FirestoreService.instance.readAllTodos();
    final todosWithDates = todos.where((t) => t.dueDate != null).toList();

    setState(() {
      _events = events;
      _todosWithDates = todosWithDates;
      _isLoading = false;
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

  Future<void> _addEvent() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    DateTime startTime = _selectedDay ?? DateTime.now();
    DateTime endTime = startTime.add(const Duration(hours: 1));

    final result = await showDialog<Event>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.isDarkMode ? AppColors.panel : AppColors.lightPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Add Event',
            style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Event Title',
                    labelStyle: TextStyle(color: context.textMutedColor),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(color: context.textMutedColor),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Location (Optional)',
                    labelStyle: TextStyle(color: context.textMutedColor),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    'Start Time',
                    style: TextStyle(color: context.textPrimaryColor, fontSize: 14),
                  ),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(startTime),
                    style: const TextStyle(color: AppColors.accent),
                  ),
                  trailing: const Icon(Icons.access_time, color: AppColors.accent),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startTime,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null && context.mounted) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(startTime),
                      );
                      if (time != null) {
                        setDialogState(() {
                          startTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                          if (endTime.isBefore(startTime)) {
                            endTime = startTime.add(const Duration(hours: 1));
                          }
                        });
                      }
                    }
                  },
                ),
                ListTile(
                  title: Text(
                    'End Time',
                    style: TextStyle(color: context.textPrimaryColor, fontSize: 14),
                  ),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(endTime),
                    style: const TextStyle(color: AppColors.accentAlt),
                  ),
                  trailing: const Icon(Icons.access_time, color: AppColors.accentAlt),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endTime,
                      firstDate: startTime,
                      lastDate: DateTime(2030),
                    );
                    if (date != null && context.mounted) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(endTime),
                      );
                      if (time != null) {
                        setDialogState(() {
                          endTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: context.textMutedColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  final newEvent = Event(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    startTime: startTime,
                    endTime: endTime,
                    location: locationController.text.trim().isEmpty
                        ? null
                        : locationController.text.trim(),
                  );
                  Navigator.pop(context, newEvent);
                }
              },
              child: const Text('Add Event'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await FirestoreService.instance.createEvent(result);
      await _loadData();
    }
  }

  Future<void> _deleteEvent(String id) async {
    await FirestoreService.instance.deleteEvent(id);
    await _loadData();
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

    final selectedDayEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

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
                              Icons.calendar_month,
                              color: AppColors.accent,
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
                                'Calendar',
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
                            onPressed: _addEvent,
                            icon: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
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
                        const SizedBox(height: 16),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: context.outlineColor),
                          ),
                          child: TableCalendar(
                            firstDay: DateTime(2020),
                            lastDay: DateTime(2030),
                            focusedDay: _focusedDay,
                            calendarFormat: _calendarFormat,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
                                color: AppColors.accent.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              markerDecoration: const BoxDecoration(
                                color: AppColors.accentAlt,
                                shape: BoxShape.circle,
                              ),
                              weekendTextStyle: const TextStyle(color: Colors.red),
                              defaultTextStyle: TextStyle(color: context.textPrimaryColor),
                              outsideTextStyle: TextStyle(color: context.textMutedColor.withValues(alpha: 0.5)),
                            ),
                            headerStyle: HeaderStyle(
                              formatButtonVisible: true,
                              titleCentered: true,
                              formatButtonShowsNext: false,
                              titleTextStyle: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              formatButtonTextStyle: TextStyle(color: context.textPrimaryColor),
                              leftChevronIcon: Icon(Icons.chevron_left, color: context.textPrimaryColor),
                              rightChevronIcon: Icon(Icons.chevron_right, color: context.textPrimaryColor),
                            ),
                            daysOfWeekStyle: DaysOfWeekStyle(
                              weekdayStyle: TextStyle(color: context.textMutedColor),
                              weekendStyle: TextStyle(color: Colors.red.withValues(alpha: 0.7)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                _selectedDay != null
                                    ? DateFormat('EEEE, MMMM d').format(_selectedDay!)
                                    : 'Select a date',
                                style: TextStyle(
                                  color: context.textPrimaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${selectedDayEvents.length} item${selectedDayEvents.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: context.textMutedColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: selectedDayEvents.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.event_available,
                                        size: 64,
                                        color: context.textMutedColor.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No events or tasks',
                                        style: TextStyle(
                                          color: context.textPrimaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Add an event for this day',
                                        style: TextStyle(
                                          color: context.textMutedColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(Event event) {
    return Dismissible(
      key: Key('event-${event.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _deleteEvent(event.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.outlineColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (event.description != null) ...[
              const SizedBox(height: 8),
              Text(
                event.description!,
                style: TextStyle(
                  color: context.textMutedColor,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, color: context.textMutedColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('hh:mm a').format(event.startTime)} - ${DateFormat('hh:mm a').format(event.endTime)}',
                  style: TextStyle(
                    color: context.textMutedColor,
                    fontSize: 13,
                  ),
                ),
                if (event.location != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, color: context.textMutedColor, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location!,
                      style: TextStyle(
                        color: context.textMutedColor,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceElevatedColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: todo.isCompleted ? AppColors.success : context.outlineColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            todo.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: todo.isCompleted ? AppColors.success : AppColors.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Task',
                      style: TextStyle(
                        color: context.textMutedColor,
                        fontSize: 12,
                      ),
                    ),
                    if (todo.priority == Priority.high) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.priorityHigh.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HIGH',
                          style: TextStyle(
                            color: AppColors.priorityHigh,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
