import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Calendar type enum
enum CalendarType {
  personal,
  work,
  holiday,
  birthday,
  other;

  static CalendarType fromString(String value) {
    return CalendarType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CalendarType.other,
    );
  }

  String get displayName {
    switch (this) {
      case CalendarType.personal:
        return 'Personal';
      case CalendarType.work:
        return 'Work';
      case CalendarType.holiday:
        return 'Holiday';
      case CalendarType.birthday:
        return 'Birthday';
      case CalendarType.other:
        return 'Other';
    }
  }

  /// Get default color for calendar type
  Color get defaultColor {
    switch (this) {
      case CalendarType.personal:
        return const Color(0xFF7C5DFA); // Purple
      case CalendarType.work:
        return const Color(0xFF3B82F6); // Blue
      case CalendarType.holiday:
        return const Color(0xFFEF4444); // Red
      case CalendarType.birthday:
        return const Color(0xFFFFB84D); // Orange
      case CalendarType.other:
        return const Color(0xFF22C55E); // Green
    }
  }

  /// Get icon for calendar type
  String get icon {
    switch (this) {
      case CalendarType.personal:
        return 'person';
      case CalendarType.work:
        return 'work';
      case CalendarType.holiday:
        return 'celebration';
      case CalendarType.birthday:
        return 'cake';
      case CalendarType.other:
        return 'calendar_today';
    }
  }
}

/// Access level for shared calendars
enum CalendarAccessLevel {
  owner,       // Full control
  editor,      // Can add/edit/delete events
  viewer,      // Can only view events
  freeBusy,    // Can only see free/busy status
}

// Extension for CalendarAccessLevel functionality
extension CalendarAccessLevelExtension on CalendarAccessLevel {
  String get displayName {
    switch (this) {
      case CalendarAccessLevel.owner:
        return 'Owner';
      case CalendarAccessLevel.editor:
        return 'Editor';
      case CalendarAccessLevel.viewer:
        return 'Viewer';
      case CalendarAccessLevel.freeBusy:
        return 'Free/Busy';
    }
  }

  bool get canEdit => this == CalendarAccessLevel.owner || this == CalendarAccessLevel.editor;
  bool get canView => this != CalendarAccessLevel.freeBusy;
}

// Helper functions
class CalendarAccessLevelHelper {
  static CalendarAccessLevel fromString(String value) {
    return CalendarAccessLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CalendarAccessLevel.viewer,
    );
  }
}

/// User Calendar model for multiple calendar support
class UserCalendar {
  final String id;
  final String name;
  final Color color;
  final CalendarType type;
  final bool isVisible;
  final bool isReadOnly;
  final int order; // Display order
  final String? description;
  final String? ownerId; // For shared calendars
  final List<String> sharedWith; // User IDs with access
  final CalendarAccessLevel accessLevel; // Current user's access level
  final DateTime createdAt;
  final DateTime? syncedAt; // Last sync time
  final String? icalUrl; // For syncing external calendars
  final bool isPrimary; // Default calendar for events

  UserCalendar({
    required this.id,
    required this.name,
    required this.color,
    required this.type,
    this.isVisible = true,
    this.isReadOnly = false,
    this.order = 0,
    this.description,
    this.ownerId,
    List<String>? sharedWith,
    this.accessLevel = CalendarAccessLevel.owner,
    DateTime? createdAt,
    this.syncedAt,
    this.icalUrl,
    this.isPrimary = false,
  })  : sharedWith = sharedWith ?? const [],
        createdAt = createdAt ?? DateTime.now();

  /// Check if this calendar can be edited
  bool get canEdit => !isReadOnly && accessLevel.canEdit;

  /// Check if this calendar is shared
  bool get isShared => sharedWith.isNotEmpty || ownerId != null;

  /// Check if this is an external calendar (iCal/ICS)
  bool get isExternal => icalUrl != null && icalUrl!.isNotEmpty;

  /// Check if this is the user's own calendar
  bool get isOwned => accessLevel == CalendarAccessLevel.owner;

  /// Get calendar icon
  String get icon => type.icon;

  /// Get formatted color hex string
  String get colorHex => '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'color': color.value,
      'type': type.name,
      'isVisible': isVisible,
      'isReadOnly': isReadOnly,
      'order': order,
      'description': description,
      'ownerId': ownerId,
      'sharedWith': sharedWith,
      'accessLevel': accessLevel.name,
      'createdAt': FieldValue.serverTimestamp(),
      if (syncedAt != null) 'syncedAt': Timestamp.fromDate(syncedAt!),
      'icalUrl': icalUrl,
      'isPrimary': isPrimary,
    };
  }

  /// Create from Firestore document
  factory UserCalendar.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse color
    Color color = const Color(0xFF7C5DFA);
    if (data['color'] is int) {
      color = Color(data['color'] as int);
    } else if (data['color'] is String) {
      color = Color(
        int.parse(data['color'] as String, radix: 16),
      );
    }

    // Parse timestamps
    DateTime? createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    DateTime? syncedAt;
    if (data['syncedAt'] is Timestamp) {
      syncedAt = (data['syncedAt'] as Timestamp).toDate();
    }

    return UserCalendar(
      id: doc.id,
      name: data['name'] as String,
      color: color,
      type: CalendarType.fromString(data['type'] as String? ?? 'other'),
      isVisible: data['isVisible'] as bool? ?? true,
      isReadOnly: data['isReadOnly'] as bool? ?? false,
      order: data['order'] as int? ?? 0,
      description: data['description'] as String?,
      ownerId: data['ownerId'] as String?,
      sharedWith: (data['sharedWith'] as List<dynamic>?)?.cast<String>() ?? const [],
      accessLevel: CalendarAccessLevelHelper.fromString(
        data['accessLevel'] as String? ?? 'owner',
      ),
      createdAt: createdAt,
      syncedAt: syncedAt,
      icalUrl: data['icalUrl'] as String?,
      isPrimary: data['isPrimary'] as bool? ?? false,
    );
  }

  /// Create a copy with updated fields
  UserCalendar copyWith({
    String? id,
    String? name,
    Color? color,
    CalendarType? type,
    bool? isVisible,
    bool? isReadOnly,
    int? order,
    String? description,
    String? ownerId,
    List<String>? sharedWith,
    CalendarAccessLevel? accessLevel,
    DateTime? syncedAt,
    String? icalUrl,
    bool? isPrimary,
    bool clearSharedWith = false,
    bool clearIcalUrl = false,
  }) {
    return UserCalendar(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      type: type ?? this.type,
      isVisible: isVisible ?? this.isVisible,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      order: order ?? this.order,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      sharedWith: clearSharedWith ? const [] : (sharedWith ?? this.sharedWith),
      accessLevel: accessLevel ?? this.accessLevel,
      createdAt: createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      icalUrl: clearIcalUrl ? null : (icalUrl ?? this.icalUrl),
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  /// Create default primary calendar
  factory UserCalendar.primary({String? userId}) {
    return UserCalendar(
      id: userId ?? 'primary',
      name: 'My Calendar',
      color: const Color(0xFF7C5DFA),
      type: CalendarType.personal,
      isPrimary: true,
      isVisible: true,
      isReadOnly: false,
      order: 0,
      accessLevel: CalendarAccessLevel.owner,
    );
  }

  /// Create work calendar
  factory UserCalendar.work() {
    return UserCalendar(
      id: 'work',
      name: 'Work',
      color: const Color(0xFF3B82F6),
      type: CalendarType.work,
      isPrimary: false,
      isVisible: true,
      isReadOnly: false,
      order: 1,
      accessLevel: CalendarAccessLevel.owner,
    );
  }

  /// Create holiday calendar
  factory UserCalendar.holidays() {
    return UserCalendar(
      id: 'holidays',
      name: 'Holidays',
      color: const Color(0xFFEF4444),
      type: CalendarType.holiday,
      isPrimary: false,
      isVisible: true,
      isReadOnly: true,
      order: 2,
      accessLevel: CalendarAccessLevel.viewer,
      description: 'Public holidays and observances',
    );
  }

  /// Create birthday calendar
  factory UserCalendar.birthdays() {
    return UserCalendar(
      id: 'birthdays',
      name: 'Birthdays',
      color: const Color(0xFFFFB84D),
      type: CalendarType.birthday,
      isPrimary: false,
      isVisible: true,
      isReadOnly: true,
      order: 3,
      accessLevel: CalendarAccessLevel.viewer,
      description: 'Birthdays of contacts',
    );
  }

  @override
  String toString() {
    return 'UserCalendar(id: $id, name: $name, type: $type, color: $colorHex)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserCalendar && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Helper class for calendar operations
class UserCalendarHelper {
  /// Get calendar color for display
  static Color getDisplayColor(UserCalendar calendar) {
    return calendar.color;
  }

  /// Check if calendar is visible
  static bool isCalendarVisible(UserCalendar calendar, Set<String> hiddenCalendarIds) {
    return calendar.isVisible && !hiddenCalendarIds.contains(calendar.id);
  }

  /// Sort calendars by order
  static List<UserCalendar> sortByOrder(List<UserCalendar> calendars) {
    final sorted = List<UserCalendar>.from(calendars);
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }

  /// Get visible calendars
  static List<UserCalendar> getVisibleCalendars(
    List<UserCalendar> calendars,
    Set<String> hiddenCalendarIds,
  ) {
    return calendars
        .where((c) => isCalendarVisible(c, hiddenCalendarIds))
        .toList();
  }

  /// Get editable calendars
  static List<UserCalendar> getEditableCalendars(List<UserCalendar> calendars) {
    return calendars.where((c) => c.canEdit).toList();
  }

  /// Get primary calendar
  static UserCalendar? getPrimaryCalendar(List<UserCalendar> calendars) {
    for (final calendar in calendars) {
      if (calendar.isPrimary) return calendar;
    }
    // Fallback to first calendar
    return calendars.isNotEmpty ? calendars.first : null;
  }

  /// Generate a default color for new calendars
  static Color generateUniqueColor(List<UserCalendar> existingCalendars) {
    final usedColors = existingCalendars.map((c) => c.color.value).toSet();

    const availableColors = [
      0xFF7C5DFA, // Purple
      0xFF3B82F6, // Blue
      0xFF22C55E, // Green
      0xFFFFB84D, // Orange
      0xFFEF4444, // Red
      0xFFEC4899, // Pink
      0xFF8B5CF6, // Violet
      0xFF14B8A6, // Teal
      0xFFF59E0B, // Amber
      0xFF6366F1, // Indigo
    ];

    for (final color in availableColors) {
      if (!usedColors.contains(color)) {
        return Color(color);
      }
    }

    return Color(availableColors.first);
  }

  /// Get calendar by ID
  static UserCalendar? getCalendarById(
    List<UserCalendar> calendars,
    String calendarId,
  ) {
    for (final calendar in calendars) {
      if (calendar.id == calendarId) return calendar;
    }
    return null;
  }

  /// Filter calendars by type
  static List<UserCalendar> filterByType(
    List<UserCalendar> calendars,
    CalendarType type,
  ) {
    return calendars.where((c) => c.type == type).toList();
  }

  /// Get shared calendars
  static List<UserCalendar> getSharedCalendars(List<UserCalendar> calendars) {
    return calendars.where((c) => c.isShared).toList();
  }

  /// Get external calendars
  static List<UserCalendar> getExternalCalendars(List<UserCalendar> calendars) {
    return calendars.where((c) => c.isExternal).toList();
  }
}
