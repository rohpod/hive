import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';
import 'events_provider.dart'; // To get databaseServiceProvider

final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user != null) {
    return ref.read(databaseServiceProvider).getNotifications(user.uid);
  }
  return Stream.value([]);
});
