import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive_breakpoints.dart';
import '../../utils/animation_system.dart';

/// Schedule view (time grid) for calendar events
///
/// Displays events in a vertical time grid similar to Google Calendar's
/// day/schedule view. Events are positioned based on their start/end times.
class ScheduleView extends StatefulWidget {
  final DateTime selectedDate;
  final List<Event> events;
  final List<String> visibleCalendarIds;
  final Function(Event)? onEventTap;
  final Function(DateTime)? onTimeSlotTap;
  final Function(DateTime, DateTime)? onTimeSlotDrag;
  final TimeOfDay startHour;
  final TimeOfDay endHour;
  final double hourHeight;

  const ScheduleView({
    super.key,
    required this.selectedDate,
    required this.events,
    this.visibleCalendarIds = const [],
    this.onEventTap,
    this.onTimeSlotTap,
    this.onTimeSlotDrag,
    this.startHour = const TimeOfDay(hour: 0, minute: 0),
    this.endHour = const TimeOfDay(hour: 23, minute: 59),
    this.hourHeight = 60,
  });

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  late ScrollController _controller;
  final Map<String, List<Event>> _positionedEvents = {};
  DateTime? _dragStartTime;
  DateTime? _dragCurrentTime;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _calculateEventPositions();
    _scrollToCurrentTime();
  }

  @override
  void didUpdateWidget(ScheduleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events != oldWidget.events ||
        widget.selectedDate != oldWidget.selectedDate) {
      _calculateEventPositions();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _calculateEventPositions() {
    _positionedEvents.clear();

    // Filter events for selected date and visible calendars
    final filteredEvents = widget.events.where((event) {
      final sameDay = event.startTime.year == widget.selectedDate.year &&
          event.startTime.month == widget.selectedDate.month &&
          event.startTime.day == widget.selectedDate.day;

      final visible = widget.visibleCalendarIds.isEmpty ||
          widget.visibleCalendarIds.contains(event.calendarId);

      return sameDay && visible;
    }).toList();

    // Group overlapping events
    for (final event in filteredEvents) {
      final key = _getEventKey(event);
      _positionedEvents[key] = [event];
    }
  }

  String _getEventKey(Event event) {
    // Group events by hour and 15-minute slot
    final hour = event.startTime.hour;
    final slot = (event.startTime.minute / 15).floor();
    return '$hour-$slot';
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final isToday = now.year == widget.selectedDate.year &&
        now.month == widget.selectedDate.month &&
        now.day == widget.selectedDate.day;

    if (isToday) {
      final offset = (now.hour * widget.hourHeight) +
          (now.minute / 60 * widget.hourHeight) -
          (MediaQuery.of(context).size.height / 3);

      Future.delayed(const Duration(milliseconds: 300), () {
        if (_controller.hasClients) {
          _controller.animateTo(
            offset.clamp(0.0, _controller.position.maxScrollExtent),
            duration: AppAnimations.medium,
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  double _getTimeOffset(DateTime time) {
    final hoursFromStart = time.hour - widget.startHour.hour +
        time.minute / 60.0;
    return hoursFromStart * widget.hourHeight;
  }

  double _getEventHeight(Event event) {
    final durationMinutes = event.duration.inMinutes.toDouble();
    return (durationMinutes / 60) * widget.hourHeight;
  }

  void _handleTimeSlotTap(DateTime time) {
    widget.onTimeSlotTap?.call(time);
  }

  void _handleDragStart(DragStartDetails details, DateTime time) {
    setState(() {
      _dragStartTime = time;
      _dragCurrentTime = time;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final hour = widget.startHour.hour + (localPosition.dy / widget.hourHeight);

    setState(() {
      _dragCurrentTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        hour.floor(),
        ((hour - hour.floor()) * 60).round(),
      );
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragStartTime != null && _dragCurrentTime != null) {
      final start = _dragStartTime!;
      var end = _dragCurrentTime!;

      // Ensure end is after start
      if (end.isBefore(start)) {
        end = start;
      }

      widget.onTimeSlotDrag?.call(start, end);
    }

    setState(() {
      _dragStartTime = null;
      _dragCurrentTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalHours = widget.endHour.hour - widget.startHour.hour + 1;
    final totalHeight = totalHours * widget.hourHeight;

    return Stack(
      children: [
        // Time grid
        _buildTimeGrid(totalHeight),

        // Current time indicator
        _buildCurrentTimeLine(),

        // Positioned events
        ..._buildEventChips(),

        // Drag selection overlay
        if (_dragStartTime != null && _dragCurrentTime != null)
          _buildDragSelection(),

        // Gesture detector for creating events
        Positioned.fill(
          child: GestureDetector(
            onVerticalDragStart: (details) {
              final time = _getTimeFromPosition(details.globalPosition);
              if (time != null) _handleDragStart(details, time);
            },
            onVerticalDragUpdate: (details) {
              _handleDragUpdate(details);
            },
            onVerticalDragEnd: (details) {
              _handleDragEnd(details);
            },
            onTapUp: (details) {
              final time = _getTimeFromPosition(details.globalPosition);
              if (time != null) _handleTimeSlotTap(time);
            },
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeGrid(double totalHeight) {
    return ListView.builder(
      controller: _controller,
      itemCount: widget.endHour.hour - widget.startHour.hour + 1,
      itemBuilder: (context, index) {
        final hour = widget.startHour.hour + index;
        return Container(
          height: widget.hourHeight,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.outlineColor.withOpacity(0.3),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time label
              SizedBox(
                width: 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    DateFormat('ha').format(
                      DateTime(2024, 1, 1, hour),
                    ),
                    style: context.captionStyle.copyWith(
                      color: context.textMutedColor,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              // Hour line
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: context.outlineColor.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentTimeLine() {
    final now = DateTime.now();
    final isToday = now.year == widget.selectedDate.year &&
        now.month == widget.selectedDate.month &&
        now.day == widget.selectedDate.day;

    if (!isToday) return const SizedBox.shrink();

    final offset = _getTimeOffset(now);

    return Positioned(
      top: offset,
      left: 0,
      right: 0,
      child: Container(
        height: 2,
        color: AppColors.accent,
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEventChips() {
    final chips = <Widget>[];

    for (final entry in _positionedEvents.entries) {
      for (final event in entry.value) {
        final top = _getTimeOffset(event.startTime);
        final height = _getEventHeight(event);

        chips.add(
          Positioned(
            top: top,
            left: 60,
            right: 8,
            height: height.clamp(30, double.infinity),
            child: _EventChip(
              event: event,
              onTap: () => widget.onEventTap?.call(event),
            ),
          ),
        );
      }
    }

    return chips;
  }

  Widget _buildDragSelection() {
    if (_dragStartTime == null || _dragCurrentTime == null) {
      return const SizedBox.shrink();
    }

    final startOffset = _getTimeOffset(_dragStartTime!);
    final endOffset = _getTimeOffset(_dragCurrentTime!);

    final top = startOffset < endOffset ? startOffset : endOffset;
    final height = (endOffset - startOffset).abs();

    return Positioned(
      top: top,
      left: 60,
      right: 8,
      height: height.clamp(30, double.infinity),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.2),
          border: Border.all(
            color: AppColors.accent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  DateTime? _getTimeFromPosition(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final localPosition = renderBox.globalToLocal(globalPosition);
    final hour = widget.startHour.hour + (localPosition.dy / widget.hourHeight);

    return DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      hour.floor(),
      ((hour - hour.floor()) * 60).round(),
    );
  }
}

/// Event chip widget for schedule view
class _EventChip extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const _EventChip({
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: event.eventColor.withOpacity(isDark ? 0.3 : 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: event.eventColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              event.title,
              style: TextStyle(
                color: event.eventColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (event.duration.inHours < 12) ...[
              const SizedBox(height: 2),
              Text(
                DateFormat('hh:mm a').format(event.startTime),
                style: TextStyle(
                  color: context.textMutedColor,
                  fontSize: 10,
                ),
              ),
            ],
            if (event.location?.address != null && event.duration.inHours >= 1)
              Text(
                event.location!.address!,
                style: TextStyle(
                  color: context.textMutedColor,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

/// Schedule view with day columns (week view)
class MultiDayScheduleView extends StatefulWidget {
  final DateTime startDate;
  final int daysToShow;
  final List<Event> events;
  final List<String> visibleCalendarIds;
  final Function(Event)? onEventTap;
  final Function(DateTime, DateTime)? onTimeSlotTap;
  final TimeOfDay startHour;
  final TimeOfDay endHour;
  final double hourHeight;

  const MultiDayScheduleView({
    super.key,
    required this.startDate,
    this.daysToShow = 7,
    required this.events,
    this.visibleCalendarIds = const [],
    this.onEventTap,
    this.onTimeSlotTap,
    this.startHour = const TimeOfDay(hour: 6, minute: 0),
    this.endHour = const TimeOfDay(hour: 22, minute: 0),
    this.hourHeight = 60,
  });

  @override
  State<MultiDayScheduleView> createState() => _MultiDayScheduleViewState();
}

class _MultiDayScheduleViewState extends State<MultiDayScheduleView> {
  late PageController _pageController;
  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDayIndex = now.difference(widget.startDate).inDays.clamp(0, widget.daysToShow - 1);
    _pageController = PageController(initialPage: _selectedDayIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<DateTime> _getDays() {
    return List.generate(
      widget.daysToShow,
      (index) => widget.startDate.add(Duration(days: index)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDays();

    return Column(
      children: [
        // Day headers
        _buildDayHeaders(days),

        // Schedule view
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _selectedDayIndex = index);
            },
            itemCount: days.length,
            itemBuilder: (context, index) {
              return ScheduleView(
                selectedDate: days[index],
                events: widget.events,
                visibleCalendarIds: widget.visibleCalendarIds,
                onEventTap: widget.onEventTap,
                onTimeSlotTap: (time) {
                  widget.onTimeSlotTap?.call(
                    time,
                    time.add(const Duration(minutes: 30)),
                  );
                },
                onTimeSlotDrag: widget.onTimeSlotTap,
                startHour: widget.startHour,
                endHour: widget.endHour,
                hourHeight: widget.hourHeight,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayHeaders(List<DateTime> days) {
    final now = DateTime.now();

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: context.outlineColor,
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isToday = day.year == now.year &&
              day.month == now.month &&
              day.day == now.day;
          final isSelected = index == _selectedDayIndex;

          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: AppAnimations.fast,
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withOpacity(0.15)
                    : Colors.transparent,
                border: isSelected
                    ? Border(
                        bottom: BorderSide(
                          color: AppColors.accent,
                          width: 3,
                        ),
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day).substring(0, 1),
                    style: context.captionStyle.copyWith(
                      color: context.textMutedColor,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isToday
                          ? AppColors.accent
                          : context.textPrimaryColor,
                      fontWeight: isToday || isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
