import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/saved_event_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Events
  Stream<List<EventModel>> getEvents() {
    return _firestore
        .collection('events')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              print("Fetched date type: ${doc.data()['date'].runtimeType}");
              return EventModel.fromJson(doc.data(), doc.id);
            })
            .toList());
  }

  Stream<List<EventModel>> getEventsByClubName(String clubName) {
    return _firestore
        .collection('events')
        .where('clubName', isEqualTo: clubName)
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs
          .map((doc) {
            print("Fetched date type: ${doc.data()['date'].runtimeType}");
            return EventModel.fromJson(doc.data(), doc.id);
          })
          .toList();
      events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return events;
    });
  }

  Future<void> createEvent(EventModel event) async {
    await _firestore.collection('events').doc(event.id).set(event.toJson());
  }

  Future<void> updateEvent(EventModel event) async {
    await _firestore.collection('events').doc(event.id).update(event.toJson());
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  // Saved Events
  Stream<List<SavedEventModel>> getSavedEvents(String userId) {
    return _firestore
        .collection('savedEvents')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavedEventModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<void> toggleSaveEvent(String userId, String eventId, bool isSaved) async {
    if (isSaved) {
      // Find and delete
      QuerySnapshot query = await _firestore
          .collection('savedEvents')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.delete();
      }
    } else {
      // Add
      DocumentReference ref = _firestore.collection('savedEvents').doc();
      SavedEventModel model = SavedEventModel(id: ref.id, userId: userId, eventId: eventId);
      await ref.set(model.toJson());
    }
  }

  Stream<int> getEventRegistrationCount(String eventId) {
    return _firestore
        .collection('savedEvents')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<List<UserModel>> getEventParticipants(String eventId) async {
    QuerySnapshot savedEvents = await _firestore.collection('savedEvents').where('eventId', isEqualTo: eventId).get();
    List<String> userIds = savedEvents.docs.map((doc) => doc['userId'] as String).toList();
    
    if (userIds.isEmpty) return [];

    // Firestore 'whereIn' supports max 10 items. We should batch if needed, but for simplicity we'll just get all users and filter, or fetch one by one.
    List<UserModel> participants = [];
    for (String uid in userIds) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        participants.add(UserModel.fromJson(userDoc.data() as Map<String, dynamic>, userDoc.id));
      }
    }
    return participants;
  }

  Future<List<Map<String, dynamic>>> getEventParticipantsWithStatus(String eventId) async {
    QuerySnapshot savedEvents = await _firestore.collection('savedEvents').where('eventId', isEqualTo: eventId).get();
    
    if (savedEvents.docs.isEmpty) return [];

    List<Map<String, dynamic>> participants = [];
    for (var doc in savedEvents.docs) {
      String uid = doc['userId'] as String;
      SavedEventModel savedEvent = SavedEventModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        UserModel user = UserModel.fromJson(userDoc.data() as Map<String, dynamic>, userDoc.id);
        participants.add({
          'user': user,
          'savedEvent': savedEvent,
        });
      }
    }
    return participants;
  }

  Future<void> toggleAttendance(String userId, String eventId, bool isPresent, int activityPoints) async {
    // Find the saved event
    QuerySnapshot query = await _firestore
        .collection('savedEvents')
        .where('userId', isEqualTo: userId)
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();
        
    if (query.docs.isNotEmpty) {
      DocumentReference savedEventRef = query.docs.first.reference;
      
      // We need to check the previous status to know if we should add or subtract points
      bool previousStatus = query.docs.first['isPresent'] ?? false;
      
      if (previousStatus != isPresent) {
        await savedEventRef.update({'isPresent': isPresent});
        await recalculateUserPoints(userId);
      }
    }
  }

  Future<void> recalculateUserPoints(String userId) async {
    QuerySnapshot savedEvents = await _firestore.collection('savedEvents').where('userId', isEqualTo: userId).where('isPresent', isEqualTo: true).get();
    int totalPoints = 0;
    for (var doc in savedEvents.docs) {
      String eventId = doc['eventId'];
      DocumentSnapshot eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (eventDoc.exists) {
        totalPoints += (eventDoc.data() as Map<String, dynamic>)['activityPoints'] as int? ?? 0;
      }
    }
    await _firestore.collection('users').doc(userId).update({'totalActivityPoints': totalPoints});
  }

  Future<bool> checkClash(String userId, EventModel newEvent) async {
    QuerySnapshot savedEvents = await _firestore.collection('savedEvents').where('userId', isEqualTo: userId).get();
    
    for (var doc in savedEvents.docs) {
      String savedEventId = doc['eventId'];
      DocumentSnapshot eventDoc = await _firestore.collection('events').doc(savedEventId).get();
      if (eventDoc.exists) {
        EventModel savedEvent = EventModel.fromJson(eventDoc.data() as Map<String, dynamic>, eventDoc.id);
        if (savedEvent.date == newEvent.date && savedEvent.time == newEvent.time) {
          return true; // Clash detected
        }
      }
    }
    return false;
  }

  // User
  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).update(user.toJson());
  }

  // Notifications
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data(), doc.id))
            .toList());
  }
}
