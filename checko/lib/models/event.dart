import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'recurrence_rule.dart';

// ==================== ENUMS ====================

/// Event privacy level
enum EventPrivacy {
  defaultValue,
  public,
  private;

  String get value => name == 'defaultValue' ? 'default' : name;

  static EventPrivacy fromString(String value) {
    return EventPrivacy.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EventPrivacy.defaultValue,
    );
  }
}

/// Event confirmation status
enum EventStatus {
  tentative,
  confirmed,
  cancelled;

  static EventStatus fromString(String value) {
    return EventStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EventStatus.confirmed,
    );
  }
}

/// Event transparency (blocks time or not)
enum EventTransparency {
  opaque,    // Blocks time on calendar (default)
  transparent; // Shows as free time

  static EventTransparency fromString(String value) {
    return EventTransparency.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EventTransparency.opaque,
    );
  }
}

/// Event availability status
enum EventAvailability {
  busy,     // Shows as busy (default)
  free;     // Shows as free

  static EventAvailability fromString(String value) {
    return EventAvailability.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EventAvailability.busy,
    );
  }
}

// ==================== SUPPORTING MODELS ====================

/// Event reminder notification
class Reminder {
  final int minutesBefore;
  final ReminderMethod method;

  Reminder({
    required this.minutesBefore,
    this.method = ReminderMethod.notification,
  });

  Map<String, dynamic> toMap() {
    return {
      'minutesBefore': minutesBefore,
      'method': method.name,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      minutesBefore: map['minutesBefore'] as int,
      method: ReminderMethod.fromString(map['method'] as String? ?? 'notification'),
    );
  }

  /// Get common reminder presets
  static List<Reminder> get commonPresets => [
    Reminder(minutesBefore: 0),      // At time of event
    Reminder(minutesBefore: 5),      // 5 minutes before
    Reminder(minutesBefore: 15),     // 15 minutes before
    Reminder(minutesBefore: 30),     // 30 minutes before
    Reminder(minutesBefore: 60),     // 1 hour before
    Reminder(minutesBefore: 1440),   // 1 day before
  ];
}

/// Reminder notification method
enum ReminderMethod {
  email,
  notification,
  sms;

  static ReminderMethod fromString(String value) {
    return ReminderMethod.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ReminderMethod.notification,
    );
  }
}

/// Event attendee
class Attendee {
  final String email;
  final String? name;
  final AttendeeStatus status;
  final bool isOrganizer;
  final bool? isOptional;

  Attendee({
    required this.email,
    this.name,
    this.status = AttendeeStatus.needsAction,
    this.isOrganizer = false,
    this.isOptional,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'status': status.name,
      'isOrganizer': isOrganizer,
      'isOptional': isOptional,
    };
  }

  factory Attendee.fromMap(Map<String, dynamic> map) {
    return Attendee(
      email: map['email'] as String,
      name: map['name'] as String?,
      status: AttendeeStatus.fromString(map['status'] as String? ?? 'needsAction'),
      isOrganizer: map['isOrganizer'] as bool? ?? false,
      isOptional: map['isOptional'] as bool?,
    );
  }
}

/// Attendee response status
enum AttendeeStatus {
  needsAction,
  accepted,
  declined,
  tentative;

  static AttendeeStatus fromString(String value) {
    return AttendeeStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AttendeeStatus.needsAction,
    );
  }
}

/// Event location with coordinates
class EventLocation {
  final String? name;
  final String? address;
  final double? latitude;
  final double? longitude;

  EventLocation({
    this.name,
    this.address,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic>? toMap() {
    if (name == null && address == null) return null;
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory EventLocation.fromMap(Map<String, dynamic>? map) {
    if (map == null) return EventLocation();
    return EventLocation(
      name: map['name'] as String?,
      address: map['address'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  /// Check if location has coordinates
  bool get hasCoordinates => latitude != null && longitude != null;
}

// ==================== MAIN EVENT MODEL ====================

/// Enhanced Event model with support for:
/// - Multiple calendars
/// - Color coding
/// - Recurrence
/// - Reminders
/// - Attendees/invitations
/// - Conference URLs
/// - Privacy controls
/// - Availability status
class Event {
  // Core fields
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;

  // Calendar association
  final String calendarId;
  final Color eventColor;

  // Recurrence
  final RecurrenceRule? recurrence;

  // Reminders
  final List<Reminder> reminders;

  // Attendees
  final List<Attendee>? attendees;

  // Location
  final EventLocation? location;

  // Conference
  final String? conferenceUrl;

  // Privacy & Status
  final EventPrivacy privacy;
  final EventStatus status;

  // Availability & Transparency
  final EventAvailability availability;
  final EventTransparency transparency;

  // Metadata
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final String? createdBy;

  // Legacy field for backward compatibility
  @deprecated
  bool? isCompleted;

  Event({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    String? calendarId,
    Color? eventColor,
    this.recurrence,
    List<Reminder>? reminders,
    this.attendees,
    this.location,
    this.conferenceUrl,
    EventPrivacy? privacy,
    EventStatus? status,
    EventAvailability? availability,
    EventTransparency? transparency,
    DateTime? createdAt,
    this.modifiedAt,
    this.createdBy,
    this.isCompleted,
  })  : calendarId = calendarId ?? 'primary',
        eventColor = eventColor ?? const Color(0xFF7C5DFA),
        privacy = privacy ?? EventPrivacy.defaultValue,
        status = status ?? EventStatus.confirmed,
        availability = availability ?? EventAvailability.busy,
        transparency = transparency ?? EventTransparency.opaque,
        reminders = reminders ?? const [],
        createdAt = createdAt ?? DateTime.now();

  /// Duration of the event
  Duration get duration => endTime.difference(startTime);

  /// Check if event is all-day (spans full 24 hours)
  bool get isAllDay =>
      duration.inHours == 24 &&
      startTime.hour == 0 &&
      startTime.minute == 0;

  /// Check if event is recurring
  bool get isRecurring => recurrence != null;

  /// Check if event has attendees
  bool get hasAttendees => attendees != null && attendees!.isNotEmpty;

  /// Check if event is a meeting (has attendees and not from self)
  bool get isMeeting =>
      hasAttendees && attendees!.any((a) => !a.isOrganizer);

  /// Check if event has conference URL
  bool get hasConference => conferenceUrl != null && conferenceUrl!.isNotEmpty;

  /// Check if event is in the past
  bool get isPast => endTime.isBefore(DateTime.now());

  /// Check if event is currently happening
  bool get isNow {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Check if event is upcoming (starts within 30 minutes)
  bool get isUpcoming {
    final now = DateTime.now();
    final thirtyMinutesFromNow = now.add(const Duration(minutes: 30));
    return startTime.isAfter(now) && startTime.isBefore(thirtyMinutesFromNow);
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'calendarId': calendarId,
      'eventColor': eventColor.value,
      if (recurrence != null) 'recurrence': recurrence!.toMap(),
      'reminders': reminders.map((r) => r.toMap()).toList(),
      if (attendees != null) 'attendees': attendees!.map((a) => a.toMap()).toList(),
      if (location != null && location!.toMap() != null) 'location': location!.toMap(),
      if (conferenceUrl != null) 'conferenceUrl': conferenceUrl,
      'privacy': privacy.value,
      'status': status.name,
      'availability': availability.name,
      'transparency': transparency.name,
      'createdAt': FieldValue.serverTimestamp(),
      if (modifiedAt != null) 'modifiedAt': Timestamp.fromDate(modifiedAt!),
      if (createdBy != null) 'createdBy': createdBy,
      if (isCompleted != null) 'isCompleted': isCompleted,
    };
  }

  /// Create Event from Firestore document
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse timestamps
    DateTime startTime;
    DateTime endTime;
    if (data['startTime'] is Timestamp) {
      startTime = (data['startTime'] as Timestamp).toDate();
    } else {
      startTime = DateTime.parse(data['startTime'] as String);
    }

    if (data['endTime'] is Timestamp) {
      endTime = (data['endTime'] as Timestamp).toDate();
    } else {
      endTime = DateTime.parse(data['endTime'] as String);
    }

    // Parse timestamps for metadata
    DateTime? createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    DateTime? modifiedAt;
    if (data['modifiedAt'] is Timestamp) {
      modifiedAt = (data['modifiedAt'] as Timestamp).toDate();
    }

    // Parse color
    Color eventColor = const Color(0xFF7C5DFA);
    if (data['eventColor'] is int) {
      eventColor = Color(data['eventColor'] as int);
    } else if (data['eventColor'] is String) {
      eventColor = Color(
        int.parse(data['eventColor'] as String, radix: 16),
      );
    }

    // Parse recurrence
    RecurrenceRule? recurrence;
    if (data['recurrence'] != null) {
      recurrence = RecurrenceRule.fromMap(
        data['recurrence'] as Map<String, dynamic>,
      );
    }

    // Parse reminders
    List<Reminder> reminders = [];
    if (data['reminders'] != null) {
      reminders = (data['reminders'] as List)
          .map((r) => Reminder.fromMap(r as Map<String, dynamic>))
          .toList();
    }

    // Parse attendees
    List<Attendee>? attendees;
    if (data['attendees'] != null) {
      attendees = (data['attendees'] as List)
          .map((a) => Attendee.fromMap(a as Map<String, dynamic>))
          .toList();
    }

    // Parse location
    EventLocation? location;
    if (data['location'] != null) {
      location = EventLocation.fromMap(
        data['location'] as Map<String, dynamic>,
      );
    } else if (data['latitude'] != null || data['longitude'] != null) {
      // Legacy location fields
      location = EventLocation(
        name: data['location'] as String?,
        latitude: (data['latitude'] as num?)?.toDouble(),
        longitude: (data['longitude'] as num?)?.toDouble(),
      );
    }

    return Event(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String?,
      startTime: startTime,
      endTime: endTime,
      calendarId: data['calendarId'] as String? ?? 'primary',
      eventColor: eventColor,
      recurrence: recurrence,
      reminders: reminders,
      attendees: attendees,
      location: location,
      conferenceUrl: data['conferenceUrl'] as String?,
      privacy: EventPrivacy.fromString(data['privacy'] as String? ?? 'default'),
      status: EventStatus.fromString(data['status'] as String? ?? 'confirmed'),
      availability: EventAvailability.fromString(
        data['availability'] as String? ?? 'busy',
      ),
      transparency: EventTransparency.fromString(
        data['transparency'] as String? ?? 'opaque',
      ),
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      createdBy: data['createdBy'] as String?,
      isCompleted: data['isCompleted'] as bool?,
    );
  }

  /// Create a copy of this event with updated fields
  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? calendarId,
    Color? eventColor,
    RecurrenceRule? recurrence,
    bool clearRecurrence = false,
    List<Reminder>? reminders,
    List<Attendee>? attendees,
    bool clearAttendees = false,
    EventLocation? location,
    bool clearLocation = false,
    String? conferenceUrl,
    bool clearConference = false,
    EventPrivacy? privacy,
    EventStatus? status,
    EventAvailability? availability,
    EventTransparency? transparency,
    DateTime? modifiedAt,
    String? createdBy,
    bool? isCompleted,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: title == null ? description : this.description,
      calendarId: calendarId ?? this.calendarId,
      eventColor: eventColor ?? this.eventColor,
      recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
      reminders: reminders ?? this.reminders,
      attendees: clearAttendees ? null : (attendees ?? this.attendees),
      location: clearLocation ? null : (location ?? this.location),
      conferenceUrl: clearConference ? null : (conferenceUrl ?? this.conferenceUrl),
      privacy: privacy ?? this.privacy,
      status: status ?? this.status,
      availability: availability ?? this.availability,
      transparency: transparency ?? this.transparency,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      createdBy: createdBy ?? this.createdBy,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'calendarId': calendarId,
      'eventColor': eventColor.value,
      if (recurrence != null) 'recurrence': recurrence!.toMap(),
      'reminders': reminders.map((r) => r.toMap()).toList(),
      if (attendees != null) 'attendees': attendees!.map((a) => a.toMap()).toList(),
      if (location != null && location!.toMap() != null) 'location': location!.toMap(),
      if (conferenceUrl != null) 'conferenceUrl': conferenceUrl,
      'privacy': privacy.value,
      'status': status.name,
      'availability': availability.name,
      'transparency': transparency.name,
      'createdAt': createdAt.toIso8601String(),
      if (modifiedAt != null) 'modifiedAt': modifiedAt!.toIso8601String(),
      if (createdBy != null) 'createdBy': createdBy,
      if (isCompleted != null) 'isCompleted': isCompleted,
    };
  }

  /// Create Event from JSON for local storage
  factory Event.fromJson(Map<String, dynamic> json) {
    // Parse timestamps
    DateTime startTime;
    DateTime endTime;
    if (json['startTime'] is String) {
      startTime = DateTime.parse(json['startTime'] as String);
    } else {
      startTime = (json['startTime'] as Timestamp).toDate();
    }

    if (json['endTime'] is String) {
      endTime = DateTime.parse(json['endTime'] as String);
    } else {
      endTime = (json['endTime'] as Timestamp).toDate();
    }

    // Parse timestamps for metadata
    DateTime? createdAt;
    if (json['createdAt'] is String) {
      createdAt = DateTime.parse(json['createdAt'] as String);
    } else if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    }

    DateTime? modifiedAt;
    if (json['modifiedAt'] is String) {
      modifiedAt = DateTime.parse(json['modifiedAt'] as String);
    } else if (json['modifiedAt'] is Timestamp) {
      modifiedAt = (json['modifiedAt'] as Timestamp).toDate();
    }

    // Parse color
    Color eventColor = const Color(0xFF7C5DFA);
    if (json['eventColor'] is int) {
      eventColor = Color(json['eventColor'] as int);
    } else if (json['eventColor'] is String) {
      eventColor = Color(
        int.parse(json['eventColor'] as String, radix: 16),
      );
    }

    // Parse recurrence
    RecurrenceRule? recurrence;
    if (json['recurrence'] != null) {
      recurrence = RecurrenceRule.fromMap(
        json['recurrence'] as Map<String, dynamic>,
      );
    }

    // Parse reminders
    List<Reminder> reminders = [];
    if (json['reminders'] != null) {
      reminders = (json['reminders'] as List)
          .map((r) => Reminder.fromMap(r as Map<String, dynamic>))
          .toList();
    }

    // Parse attendees
    List<Attendee>? attendees;
    if (json['attendees'] != null) {
      attendees = (json['attendees'] as List)
          .map((a) => Attendee.fromMap(a as Map<String, dynamic>))
          .toList();
    }

    // Parse location
    EventLocation? location;
    if (json['location'] != null) {
      location = EventLocation.fromMap(
        json['location'] as Map<String, dynamic>,
      );
    }

    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: startTime,
      endTime: endTime,
      calendarId: json['calendarId'] as String? ?? 'primary',
      eventColor: eventColor,
      recurrence: recurrence,
      reminders: reminders,
      attendees: attendees,
      location: location,
      conferenceUrl: json['conferenceUrl'] as String?,
      privacy: EventPrivacy.fromString(json['privacy'] as String? ?? 'default'),
      status: EventStatus.fromString(json['status'] as String? ?? 'confirmed'),
      availability: EventAvailability.fromString(
        json['availability'] as String? ?? 'busy',
      ),
      transparency: EventTransparency.fromString(
        json['transparency'] as String? ?? 'opaque',
      ),
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      createdBy: json['createdBy'] as String?,
      isCompleted: json['isCompleted'] as bool?,
    );
  }

  @override
  String toString() {
    return 'Event(id: $id, title: $title, startTime: $startTime, endTime: $endTime, calendarId: $calendarId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Helper class for event operations
class EventHelper {
  /// Check if two events overlap in time
  static bool doEventsOverlap(Event a, Event b) {
    // Skip if either event is transparent
    if (a.transparency == EventTransparency.transparent ||
        b.transparency == EventTransparency.transparent) {
      return false;
    }

    return a.startTime.isBefore(b.endTime) && b.startTime.isBefore(a.endTime);
  }

  /// Calculate the overlap duration between two events
  static Duration calculateOverlap(Event a, Event b) {
    if (!doEventsOverlap(a, b)) return Duration.zero;

    final start = a.startTime.isAfter(b.startTime) ? a.startTime : b.startTime;
    final end = a.endTime.isBefore(b.endTime) ? a.endTime : b.endTime;

    return end.difference(start);
  }

  /// Generate a Google Calendar URL for this event
  static String generateGoogleCalendarUrl(Event event) {
    final baseUrl = 'https://calendar.google.com/calendar/render?action=TEMPLATE';
    final dates = '${_formatDateForGoogleCalendar(event.startTime)}'
        '/${_formatDateForGoogleCalendar(event.endTime)}';
    final title = Uri.encodeComponent(event.title);
    final details = event.description != null
        ? '&details=${Uri.encodeComponent(event.description!)}'
        : '';
    final location = event.location?.address != null
        ? '&location=${Uri.encodeComponent(event.location!.address!)}'
        : '';

    return '$baseUrl&text=$title&dates=$dates$details$location';
  }

  static String _formatDateForGoogleCalendar(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}'
        'T${date.hour.toString().padLeft(2, '0')}'
        '${date.minute.toString().padLeft(2, '0')}'
        '${date.second.toString().padLeft(2, '0')}';
  }

  /// Generate event color based on calendar
  static Color getColorForCalendar(String calendarId) {
    const calendarColors = {
      'primary': Color(0xFF7C5DFA),
      'work': Color(0xFF3B82F6),
      'personal': Color(0xFF22C55E),
      'holiday': Color(0xFFEF4444),
      'birthday': Color(0xFFFFB84D),
    };
    return calendarColors[calendarId] ?? const Color(0xFF7C5DFA);
  }
}
