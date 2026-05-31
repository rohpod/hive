import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_event_model.dart';
import 'auth_provider.dart';
import 'events_provider.dart';

final savedEventsStreamProvider = StreamProvider<List<SavedEventModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user != null) {
    return ref.read(databaseServiceProvider).getSavedEvents(user.uid);
  }
  return Stream.value([]);
});

final isEventSavedProvider = Provider.family<bool, String>((ref, eventId) {
  final savedEvents = ref.watch(savedEventsStreamProvider).value ?? [];
  return savedEvents.any((saved) => saved.eventId == eventId);
});
