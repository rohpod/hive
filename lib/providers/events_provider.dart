import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());

final eventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  return ref.read(databaseServiceProvider).getEvents();
});

final myEventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  final user = ref.watch(currentUserModelProvider).value;
  if (user != null && user.clubName != null && user.clubName!.isNotEmpty) {
    return ref.read(databaseServiceProvider).getEventsByClubName(user.clubName!);
  }
  return Stream.value([]);
});

final registrationCountProvider = StreamProvider.family<int, String>((ref, eventId) {
  return ref.read(databaseServiceProvider).getEventRegistrationCount(eventId);
});
