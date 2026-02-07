import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../providers/data_provider.dart';
import '../theme/dark_modern_theme.dart';

/// Create Event Screen with Multi-Day Support
class DarkCreateEventScreen extends StatefulWidget {
  final DateTime? initialDate;

  const DarkCreateEventScreen({
    super.key,
    this.initialDate,
  });

  @override
  State<DarkCreateEventScreen> createState() => _DarkCreateEventScreenState();
}

class _DarkCreateEventScreenState extends State<DarkCreateEventScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  late bool _isAllDay;

  @override
  void initState() {
    super.initState();
    final now = widget.initialDate ?? DateTime.now();

    _startDate = DateTime(now.year, now.month, now.day);
    _startTime = TimeOfDay.now();
    _endDate = DateTime(now.year, now.month, now.day);
    _endTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: 0);
    _isAllDay = false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();

    return Scaffold(
      backgroundColor: DarkModernTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Event',
          style: DarkModernTheme.titleLarge,
        ),
        actions: [
          TextButton(
            onPressed: _saveEvent,
            child: Text(
              'Save',
              style: TextStyle(
                color: DarkModernTheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title input
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _titleController,
                style: DarkModernTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Event name',
                  hintStyle: TextStyle(color: DarkModernTheme.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                autofocus: true,
              ),
            ),

            const SizedBox(height: 16),

            // All-day toggle
            _buildSectionTitle('Time'),
            GlassContainer(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text(
                    'All-day',
                    style: DarkModernTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Switch(
                    value: _isAllDay,
                    onChanged: (value) => setState(() => _isAllDay = value),
                    activeColor: DarkModernTheme.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Start date/time
            GlassContainer(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start',
                    style: DarkModernTheme.bodySmall.copyWith(
                      color: DarkModernTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectStartDate(),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: DarkModernTheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('MMM d, yyyy').format(_startDate),
                          style: DarkModernTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (!_isAllDay) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectStartTime(),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: DarkModernTheme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _startTime.format(context),
                            style: DarkModernTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            // End date/time
            GlassContainer(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'End',
                    style: DarkModernTheme.bodySmall.copyWith(
                      color: DarkModernTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectEndDate(),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: DarkModernTheme.accentBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('MMM d, yyyy').format(_endDate),
                          style: DarkModernTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (!_isAllDay) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectEndTime(),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: DarkModernTheme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _endTime.format(context),
                            style: DarkModernTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Multi-day indicator
            if (_isMultiDayEvent()) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DarkModernTheme.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DarkModernTheme.radiusSmall),
                  border: Border.all(
                    color: DarkModernTheme.accentBlue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: DarkModernTheme.accentBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Multi-day event: ${_getDayCount()} days',
                        style: DarkModernTheme.bodySmall.copyWith(
                          color: DarkModernTheme.accentBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Description input
            _buildSectionTitle('Description'),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _descriptionController,
                style: DarkModernTheme.bodyMedium,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add description...',
                  hintStyle: TextStyle(color: DarkModernTheme.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: DarkModernTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  bool _isMultiDayEvent() {
    final startDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final endDay = DateTime(_endDate.year, _endDate.month, _endDate.day);
    return startDay.isBefore(endDay);
  }

  int _getDayCount() {
    final startDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final endDay = DateTime(_endDate.year, _endDate.month, _endDate.day);
    return endDay.difference(startDay).inDays + 1;
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DarkModernTheme.primary,
              surface: DarkModernTheme.surface,
              onSurface: DarkModernTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _startDate = date);
      // Ensure end date is not before start date
      if (_endDate.isBefore(_startDate)) {
        _endDate = date;
      }
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DarkModernTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() => _startTime = time);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate, // Can't be before start date
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DarkModernTheme.accentBlue,
              surface: DarkModernTheme.surface,
              onSurface: DarkModernTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DarkModernTheme.accentBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() => _endTime = time);
    }
  }

  Future<void> _saveEvent() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter an event name'),
          backgroundColor: DarkModernTheme.accentRed,
        ),
      );
      return;
    }

    // Combine date and time
    final eventStartTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _isAllDay ? 0 : _startTime.hour,
      _isAllDay ? 0 : _startTime.minute,
    );

    final eventEndTime = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _isAllDay ? 23 : _endTime.hour,
      _isAllDay ? 59 : _endTime.minute,
    );

    // Validate end time is after start time
    if (eventEndTime.isBefore(eventStartTime) || eventEndTime.isAtSameMomentAs(eventStartTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: DarkModernTheme.accentRed,
        ),
      );
      return;
    }

    final dataProvider = context.read<DataProvider>();

    final newEvent = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      startTime: eventStartTime,
      endTime: eventEndTime,
      eventColor: DarkModernTheme.accentPurple,
    );

    await dataProvider.createEvent(newEvent);

    if (mounted) Navigator.pop(context, true);
  }
}
