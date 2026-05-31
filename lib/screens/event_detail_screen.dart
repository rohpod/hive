import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_model.dart';
import '../providers/auth_provider.dart';
import '../providers/saved_events_provider.dart';
import '../providers/events_provider.dart';
import '../utils/date_formatter.dart';

class EventDetailScreen extends ConsumerWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  void _handleRegistration(BuildContext context, WidgetRef ref, String userId, bool isSaved, int currentCount) async {
    final db = ref.read(databaseServiceProvider);
    
    if (!isSaved) {
      if (event.maxRegistrations > 0 && currentCount >= event.maxRegistrations) {
        return; // Full
      }

      bool hasClash = await db.checkClash(userId, event);
      if (hasClash && context.mounted) {
        bool? proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Schedule Clash Warning'),
            content: const Text('This event overlaps with another event you have already registered for. Do you still want to register?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Proceed')),
            ],
          )
        );
        if (proceed != true) return;
      }
    }

    await db.toggleSaveEvent(userId, event.id, isSaved);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider);
    final userRecord = ref.watch(currentUserModelProvider).value;
    final isSaved = ref.watch(isEventSavedProvider(event.id));
    final regCountAsync = ref.watch(registrationCountProvider(event.id));

    final isCreator = userRecord?.id == event.createdByUserId;
    
    // Only set currentCount if data is present
    int? currentCount = regCountAsync.value;
    bool isFull = false;
    if (currentCount != null) {
      isFull = event.maxRegistrations > 0 && currentCount >= event.maxRegistrations;
    }

    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (event.imageUrl.isNotEmpty)
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: EdgeInsets.zero,
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 4,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Image.network(
                            event.imageUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Image.network(
                  event.imageUrl,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 250, color: Colors.grey[800], child: const Icon(Icons.image_not_supported, size: 50)),
                ),
              )
            else
              Container(height: 250, color: Colors.grey[800], child: const Icon(Icons.image, size: 50)),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(event.category, style: TextStyle(color: Theme.of(context).colorScheme.background, fontWeight: FontWeight.bold)),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      if (event.clubName != null) 
                        Text('By ${event.clubName}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  Text(event.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Glowing Tags
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      if (event.activityPoints > 0)
                        _buildGlowingTag(context, 'Activity Points: ${event.activityPoints}', Colors.lightBlueAccent),
                      if (event.isFreeFoodProvided)
                        _buildGlowingTag(context, 'Free Food', Colors.orangeAccent),
                      if (event.isAttendanceProvided)
                        _buildGlowingTag(context, 'Attendance Provided', Colors.greenAccent),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Capacity Counter
                  if (event.maxRegistrations > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isFull ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isFull ? Colors.red : Colors.green),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people, color: isFull ? Colors.red : Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            currentCount == null ? 'Loading Capacity...' : 'Capacity: $currentCount / ${event.maxRegistrations}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: isFull ? Colors.red : Colors.green),
                          )
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people),
                          const SizedBox(width: 8),
                          Text(
                            currentCount == null ? 'Loading Registrations...' : 'Registrations: $currentCount',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month),
                    title: Text('${DateFormatter.format(event.date)} at ${event.time}'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on),
                    title: Text(event.venue),
                  ),
                  const SizedBox(height: 16),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(event.description, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  if (userRole == 'student') ...[
                    _AnimatedRegisterButton(
                      isSaved: isSaved,
                      isFull: isFull,
                      isPast: event.date != null && event.date!.isBefore(DateTime.now()),
                      currentCount: currentCount,
                      onPressed: () {
                        if (userRecord != null) {
                          _handleRegistration(context, ref, userRecord.id, isSaved, currentCount ?? 0);
                        }
                      },
                    )
                  ] else if (userRole == 'coordinator' && isCreator) ...[
                     SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => context.push('/edit_event', extra: event),
                        icon: const Icon(Icons.edit, color: Colors.black),
                        label: const Text('Edit Event', style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            
            // Sponsors Section
            if (event.sponsors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sponsors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: event.sponsors.length,
                      itemBuilder: (context, index) {
                        final sponsor = event.sponsors[index];
                        return GestureDetector(
                          onTap: () {
                            if (sponsor.websiteUrl.isNotEmpty) {
                              _launchUrl(sponsor.websiteUrl);
                            }
                          },
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                                    image: sponsor.logoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(sponsor.logoUrl), fit: BoxFit.cover) : null,
                                  ),
                                  child: sponsor.logoUrl.isEmpty ? const Icon(Icons.business, size: 30) : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(sponsor.name, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowingTag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}

class _AnimatedRegisterButton extends StatefulWidget {
  final bool isSaved;
  final bool isFull;
  final bool isPast;
  final int? currentCount;
  final VoidCallback onPressed;

  const _AnimatedRegisterButton({
    required this.isSaved,
    required this.isFull,
    required this.isPast,
    required this.currentCount,
    required this.onPressed,
  });

  @override
  State<_AnimatedRegisterButton> createState() => _AnimatedRegisterButtonState();
}

class _AnimatedRegisterButtonState extends State<_AnimatedRegisterButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.isPast || (widget.isFull && !widget.isSaved) || widget.currentCount == null;
    
    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => _controller.forward(),
      onTapUp: isDisabled ? null : (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: isDisabled ? null : () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.isSaved 
                ? Colors.green 
                : (isDisabled ? Colors.grey : Theme.of(context).colorScheme.primary),
            borderRadius: BorderRadius.circular(24),
            boxShadow: widget.isSaved
                ? [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)]
                : (isDisabled ? [] : [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)]),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isSaved ? Icons.check : (widget.isPast ? Icons.block : Icons.app_registration),
                color: widget.isSaved || isDisabled ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isPast 
                  ? (widget.isSaved ? 'Registered (Event Ended)' : 'Event Ended')
                  : (widget.isSaved ? 'Registered' : (widget.isFull ? 'Event Full' : 'Register Now')),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.isSaved || isDisabled ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
