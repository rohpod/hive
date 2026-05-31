import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/events_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/saved_events_provider.dart';
import '../widgets/glass_container.dart';
import '../utils/date_formatter.dart';
import '../models/event_model.dart';

class ScrollModeScreen extends ConsumerStatefulWidget {
  const ScrollModeScreen({super.key});

  @override
  ConsumerState<ScrollModeScreen> createState() => _ScrollModeScreenState();
}

class _ScrollModeScreenState extends ConsumerState<ScrollModeScreen> {
  final PageController _pageController = PageController();
  int _showCheckmarkForIndex = -1;

  void _onDoubleTap(BuildContext context, WidgetRef ref, EventModel event, int index) async {
    final user = ref.read(currentUserModelProvider).value;
    if (user == null || user.role != 'student') return;

    if (event.date != null && event.date!.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration is closed for past events.')),
        );
      }
      return;
    }

    final isSaved = ref.read(isEventSavedProvider(event.id));

    await ref.read(databaseServiceProvider).toggleSaveEvent(user.id, event.id, isSaved);

    if (!isSaved) {
      setState(() {
        _showCheckmarkForIndex = index;
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showCheckmarkForIndex = -1;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsStreamProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30, shadows: [Shadow(color: Colors.black, blurRadius: 10)]),
          onPressed: () => context.pop(),
        ),
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('No events available.', style: TextStyle(color: Colors.white)));
          }

          return NotificationListener<ScrollUpdateNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.vertical && 
                  notification.metrics.pixels > notification.metrics.maxScrollExtent + 100) {
                if (mounted && GoRouter.of(context).canPop()) {
                  context.pop();
                }
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return _buildEventPage(context, ref, event, index);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildEventPage(BuildContext context, WidgetRef ref, EventModel event, int index) {
    final isSaved = ref.watch(isEventSavedProvider(event.id));

    return GestureDetector(
      onTap: () => context.push('/event/${event.id}', extra: event),
      onDoubleTap: () => _onDoubleTap(context, ref, event, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          if (event.imageUrl.isNotEmpty)
            Image.network(event.imageUrl, fit: BoxFit.cover)
          else
            Container(color: Colors.grey[900]),

          // Gradient overlay for better text readability at the bottom
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.5, 1.0],
              ),
            ),
          ),

          // Event Details in Glass Container
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSaved)
                        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 30)
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${DateFormatter.format(event.date)} • ${event.venue}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  if (event.clubName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('By ${event.clubName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      if (event.activityPoints > 0)
                        _buildSmallTag('Points: ${event.activityPoints}', Colors.lightBlueAccent),
                      if (event.isFreeFoodProvided)
                        _buildSmallTag('Free Food', Colors.orangeAccent),
                      if (event.isAttendanceProvided)
                        _buildSmallTag('Attendance', Colors.greenAccent),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Double-tap to register/unregister', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic, fontSize: 12)),
                ],
              ),
            ),
          ),

          // Double Tap Animation Overlay
          if (_showCheckmarkForIndex == index)
            Center(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                tween: Tween<double>(begin: 0.5, end: 1.5),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 40, spreadRadius: 10)
                        ],
                      ),
                      child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 100),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSmallTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
