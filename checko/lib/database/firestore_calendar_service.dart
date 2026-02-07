import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_calendar.dart';
import '../models/event.dart';
import 'firestore_service.dart';

/// Firestore service for calendar operations
///
/// Handles:
/// - Calendar CRUD operations
/// - Event filtering by calendar
/// - Calendar sharing
/// - External calendar sync (iCal/ICS)
class FirestoreCalendarService {
  static final FirestoreCalendarService _instance = FirestoreCalendarService._internal();
  factory FirestoreCalendarService() => _instance;
  FirestoreCalendarService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _calendarsCollection => _firestore.collection('user_calendars');

  /// Get current user ID from FirestoreService
  String? get _userId => FirestoreService.instance.userId;

  // ==================== CALENDAR CRUD ====================

  /// Create a new calendar
  Future<UserCalendar> createCalendar(UserCalendar calendar) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    // If this is set as primary, unset primary flag on other calendars
    if (calendar.isPrimary) {
      await _unsetPrimaryCalendar();
    }

    final docRef = await _calendarsCollection.add({
      ...calendar.toFirestore(),
      'userId': _userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Fetch and return the created calendar
    final createdDoc = await docRef.get();
    return UserCalendar.fromFirestore(createdDoc);
  }

  /// Read all calendars for current user
  Future<List<UserCalendar>> readUserCalendars() async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    // Always ensure primary calendar exists
    await _ensurePrimaryCalendarExists();

    final snapshot = await _calendarsCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('order')
        .get();

    return snapshot.docs
        .map((doc) => UserCalendar.fromFirestore(doc))
        .toList();
  }

  /// Stream of user's calendars
  Stream<List<UserCalendar>> watchUserCalendars() {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _calendarsCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserCalendar.fromFirestore(doc))
            .toList());
  }

  /// Read a single calendar by ID
  Future<UserCalendar?> readCalendar(String calendarId) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _calendarsCollection.doc(calendarId).get();
    if (!doc.exists) return null;

    final calendar = UserCalendar.fromFirestore(doc);

    // Verify user has access
    if (calendar.ownerId == _userId || calendar.sharedWith.contains(_userId)) {
      return calendar;
    }

    return null;
  }

  /// Update an existing calendar
  Future<void> updateCalendar(UserCalendar calendar) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    // Check permission
    final existing = await readCalendar(calendar.id);
    if (existing == null) {
      throw Exception('Calendar not found');
    }

    if (!existing.canEdit) {
      throw Exception('No permission to edit this calendar');
    }

    // If setting as primary, unset other primaries
    if (calendar.isPrimary) {
      await _unsetPrimaryCalendar(exceptId: calendar.id);
    }

    await _calendarsCollection.doc(calendar.id).update({
      ...calendar.toFirestore(),
      'modifiedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a calendar
  Future<void> deleteCalendar(String calendarId) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    // Check permission
    final calendar = await readCalendar(calendarId);
    if (calendar == null) {
      throw Exception('Calendar not found');
    }

    if (!calendar.isOwned) {
      throw Exception('Cannot delete shared calendar. Unshare instead.');
    }

    // Don't allow deleting primary calendar
    if (calendar.isPrimary) {
      throw Exception('Cannot delete primary calendar');
    }

    // Delete all events in this calendar
    await _deleteCalendarEvents(calendarId);

    // Delete the calendar
    await _calendarsCollection.doc(calendarId).delete();
  }

  /// Toggle calendar visibility
  Future<void> toggleCalendarVisibility(String calendarId) async {
    final calendar = await readCalendar(calendarId);
    if (calendar == null) {
      throw Exception('Calendar not found');
    }

    await updateCalendar(calendar.copyWith(
      isVisible: !calendar.isVisible,
    ));
  }

  // ==================== CALENDAR SHARING ====================

  /// Share a calendar with another user
  Future<void> shareCalendar(
    String calendarId,
    String userId,
    CalendarAccessLevel level,
  ) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    final calendar = await readCalendar(calendarId);
    if (calendar == null) {
      throw Exception('Calendar not found');
    }

    if (!calendar.isOwned) {
      throw Exception('Only calendar owner can share');
    }

    if (calendar.sharedWith.contains(userId)) {
      throw Exception('Calendar already shared with this user');
    }

    await updateCalendar(calendar.copyWith(
      sharedWith: [...calendar.sharedWith, userId],
    ));

    // Grant access to the target user
    await _firestore.collection('user_calendars').add({
      'userId': userId,
      'calendarId': calendarId,
      'ownerId': _userId,
      'accessLevel': level.name,
      'sharedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Unshare a calendar from a user
  Future<void> unshareCalendar(String calendarId, String userId) async {
    final calendar = await readCalendar(calendarId);
    if (calendar == null) {
      throw Exception('Calendar not found');
    }

    if (!calendar.isOwned) {
      throw Exception('Only calendar owner can unshare');
    }

    final updatedSharedWith = List<String>.from(calendar.sharedWith)
      ..remove(userId);

    await updateCalendar(calendar.copyWith(
      sharedWith: updatedSharedWith,
    ));

    // Remove access from the target user
    final sharedAccessSnapshot = await _firestore
        .collection('user_calendars')
        .where('userId', isEqualTo: userId)
        .where('calendarId', isEqualTo: calendarId)
        .get();

    for (final doc in sharedAccessSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Update access level for a shared calendar
  Future<void> updateCalendarAccess(
    String calendarId,
    String userId,
    CalendarAccessLevel level,
  ) async {
    final calendar = await readCalendar(calendarId);
    if (calendar == null) {
      throw Exception('Calendar not found');
    }

    if (!calendar.isOwned) {
      throw Exception('Only calendar owner can modify access');
    }

    // Update the access level
    final sharedAccessSnapshot = await _firestore
        .collection('user_calendars')
        .where('userId', isEqualTo: userId)
        .where('calendarId', isEqualTo: calendarId)
        .get();

    for (final doc in sharedAccessSnapshot.docs) {
      await doc.reference.update({
        'accessLevel': level.name,
        'modifiedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get all calendars shared with current user
  Future<List<UserCalendar>> getSharedWithMeCalendars() async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    final snapshot = await _firestore
        .collection('user_calendars')
        .where('userId', isEqualTo: _userId)
        .where('ownerId', isNotEqualTo: _userId) // Not owned by current user
        .get();

    final calendarIds = snapshot.docs.map((doc) => doc['calendarId'] as String).toList();

    // Fetch the actual calendar documents
    final calendars = <UserCalendar>[];
    for (final calendarId in calendarIds) {
      final calendar = await readCalendar(calendarId);
      if (calendar != null) {
        calendars.add(calendar);
      }
    }

    return calendars;
  }

  // ==================== EVENT FILTERING ====================

  /// Read events for a specific calendar
  Future<List<Event>> readEventsForCalendar(String calendarId) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    final eventsCollection = _firestore.collection('events');
    final snapshot = await eventsCollection
        .where('userId', isEqualTo: _userId)
        .where('calendarId', isEqualTo: calendarId)
        .orderBy('startTime')
        .get();

    return snapshot.docs
        .map((doc) => Event.fromFirestore(doc))
        .toList();
  }

  /// Stream events for a specific calendar
  Stream<List<Event>> watchEventsForCalendar(String calendarId) {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('events')
        .where('userId', isEqualTo: _userId)
        .where('calendarId', isEqualTo: calendarId)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromFirestore(doc))
            .toList());
  }

  /// Read events for multiple calendars
  Future<List<Event>> readEventsForCalendars(List<String> calendarIds) async {
    if (_userId == null || calendarIds.isEmpty) {
      return [];
    }

    // Firestore limits 'in' queries to 10 items
    final batches = <List<String>>[];
    for (int i = 0; i < calendarIds.length; i += 10) {
      batches.add(calendarIds.sublist(
        i,
        i + 10 < calendarIds.length ? i + 10 : calendarIds.length,
      ));
    }

    final events = <Event>[];
    for (final batch in batches) {
      final snapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: _userId)
          .where('calendarId', whereIn: batch)
          .orderBy('startTime')
          .get();

      events.addAll(snapshot.docs.map((doc) => Event.fromFirestore(doc)));
    }

    return events;
  }

  /// Stream events for multiple calendars
  Stream<List<Event>> watchEventsForCalendars(List<String> calendarIds) {
    if (_userId == null || calendarIds.isEmpty) {
      return Stream.value([]);
    }

    // Firestore limits 'in' queries to 10 items
    final batches = <List<String>>[];
    for (int i = 0; i < calendarIds.length; i += 10) {
      batches.add(calendarIds.sublist(
        i,
        i + 10 < calendarIds.length ? i + 10 : calendarIds.length,
      ));
    }

    // Create streams for each batch and combine
    final streams = batches.map((batch) {
      return _firestore
          .collection('events')
          .where('userId', isEqualTo: _userId)
          .where('calendarId', whereIn: batch)
          .orderBy('startTime')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Event.fromFirestore(doc))
              .toList());
    });

    // Combine multiple streams (simplified - in production use rxdart)
    return streams.first;
  }

  // ==================== EXTERNAL CALENDAR SYNC ====================

  /// Sync an external calendar (iCal/ICS)
  Future<void> syncExternalCalendar(String calendarId, String icalUrl) async {
    final calendar = await readCalendar(calendarId);
    if (calendar == null) {
      throw Exception('Calendar not found');
    }

    if (!calendar.canEdit) {
      throw Exception('No permission to sync this calendar');
    }

    // Update the iCal URL
    await updateCalendar(calendar.copyWith(
      icalUrl: icalUrl,
      syncedAt: DateTime.now(),
    ));

    // In a real implementation, you would:
    // 1. Fetch the iCal file from the URL
    // 2. Parse it to extract events
    // 3. Create/update events in the calendar
    // This requires HTTP client and iCal parsing library

    // For now, just mark as synced
    await updateCalendar(calendar.copyWith(
      syncedAt: DateTime.now(),
    ));
  }

  /// Parse iCal/ICS data to extract events
  Future<List<Event>> parseICal(String icalData) async {
    // This is a simplified implementation
    // In production, use a proper iCal parsing library
    final events = <Event>[];

    final lines = icalData.split('\n');
    Event? currentEvent;
    String? eventId;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.startsWith('BEGIN:VEVENT')) {
        eventId = DateTime.now().millisecondsSinceEpoch.toString();
        currentEvent = Event(
          id: eventId,
          title: '',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          calendarId: 'external',
        );
      } else if (trimmed.startsWith('END:VEVENT')) {
        if (currentEvent != null) {
          events.add(currentEvent);
          currentEvent = null;
        }
      } else if (currentEvent != null) {
        if (trimmed.startsWith('SUMMARY:')) {
          currentEvent = currentEvent.copyWith(
            title: trimmed.substring(8),
          );
        } else if (trimmed.startsWith('DTSTART:')) {
          try {
            final startTime = _parseICalDate(trimmed.substring(8));
            final duration = currentEvent.duration;
            currentEvent = currentEvent.copyWith(
              startTime: startTime,
              endTime: startTime.add(duration),
            );
          } catch (e) {
            // Keep default time
          }
        } else if (trimmed.startsWith('DTEND:')) {
          try {
            final endTime = _parseICalDate(trimmed.substring(6));
            currentEvent = currentEvent.copyWith(
              endTime: endTime,
            );
          } catch (e) {
            // Keep default time
          }
        } else if (trimmed.startsWith('LOCATION:')) {
          // Store in location field
          currentEvent = currentEvent.copyWith(
            location: EventLocation(address: trimmed.substring(9)),
          );
        } else if (trimmed.startsWith('DESCRIPTION:')) {
          currentEvent = currentEvent.copyWith(
            description: trimmed.substring(12),
          );
        }
      }
    }

    return events;
  }

  DateTime _parseICalDate(String dateStr) {
    // iCal format: 20241231T143000Z or 20241231T143000
    final cleanStr = dateStr.replaceAll('T', '').replaceAll('Z', '').replaceAll(':', '');

    final year = int.parse(cleanStr.substring(0, 4));
    final month = int.parse(cleanStr.substring(4, 6));
    final day = int.parse(cleanStr.substring(6, 8));

    int hour = 0;
    int minute = 0;
    int second = 0;

    if (cleanStr.length >= 14) {
      hour = int.parse(cleanStr.substring(8, 10));
      minute = int.parse(cleanStr.substring(10, 12));
      second = int.parse(cleanStr.substring(12, 14));
    }

    return DateTime(year, month, day, hour, minute, second);
  }

  // ==================== PRIVATE HELPERS ====================

  /// Ensure primary calendar exists for user
  Future<void> _ensurePrimaryCalendarExists() async {
    if (_userId == null) return;

    final snapshot = await _calendarsCollection
        .where('userId', isEqualTo: _userId)
        .where('isPrimary', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      // Create primary calendar
      await createCalendar(UserCalendar.primary(userId: _userId));
    }
  }

  /// Unset primary flag on all calendars
  Future<void> _unsetPrimaryCalendar({String? exceptId}) async {
    if (_userId == null) return;

    final query = _calendarsCollection.where('userId', isEqualTo: _userId);
    if (exceptId != null) {
      query.where('id', isNotEqualTo: exceptId);
    }

    final snapshot = await query.where('isPrimary', isEqualTo: true).get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({'isPrimary': false});
    }
  }

  /// Delete all events in a calendar
  Future<void> _deleteCalendarEvents(String calendarId) async {
    final eventsCollection = _firestore.collection('events');

    // Delete in batches (Firestore limits batch operations to 500)
    final batchSize = 400;
    bool hasMore = true;

    while (hasMore) {
      final snapshot = await eventsCollection
          .where('userId', isEqualTo: _userId)
          .where('calendarId', isEqualTo: calendarId)
          .limit(batchSize)
          .get();

      if (snapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      hasMore = snapshot.docs.length >= batchSize;
    }
  }
}
