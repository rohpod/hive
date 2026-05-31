import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/events_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/event_card.dart';
import '../models/event_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _primaryFilter;
  String? _subFilter;
  bool _isNavigatingToScrollMode = false;

  final Map<String, List<String>> _subcategories = {
    'Technical': ['Hackathon', 'Workshop', 'Seminar'],
    'Cultural': ['Art', 'Music', 'Dance', 'Misc'],
  };

  void _togglePrimaryFilter(String category) {
    setState(() {
      if (_primaryFilter == category) {
        _primaryFilter = null;
        _subFilter = null;
      } else {
        _primaryFilter = category;
        _subFilter = null;
      }
    });
  }

  void _toggleSubFilter(String subCategory) {
    setState(() {
      if (_subFilter == subCategory) {
        _subFilter = null;
      } else {
        _subFilter = subCategory;
      }
    });
  }

  Widget _buildFilterPill(String text, bool isSelected, VoidCallback onTap, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(text),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.background : Colors.white,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    final userRole = ref.watch(userRoleProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Image.asset('assets/images/logo.png', height: 40, width: 40, errorBuilder: (_,__,___) => const Icon(Icons.hive, color: Colors.amber, size: 40)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_primaryFilter == null || _primaryFilter == 'Technical')
                            _buildFilterPill('Technical', _primaryFilter == 'Technical', () => _togglePrimaryFilter('Technical'), isPrimary: true),
                          if (_primaryFilter == 'Technical')
                            ..._subcategories['Technical']!.map((sub) => _buildFilterPill(sub, _subFilter == sub, () => _toggleSubFilter(sub))),
                          
                          if (_primaryFilter == null || _primaryFilter == 'Cultural')
                            _buildFilterPill('Cultural', _primaryFilter == 'Cultural', () => _togglePrimaryFilter('Cultural'), isPrimary: true),
                          if (_primaryFilter == 'Cultural')
                            ..._subcategories['Cultural']!.map((sub) => _buildFilterPill(sub, _subFilter == sub, () => _toggleSubFilter(sub))),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.view_carousel, color: Colors.white, size: 28),
                    onPressed: () => context.push('/scroll_mode'),
                    tooltip: 'Scroll Mode',
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: eventsAsync.when(
                data: (events) {
                  List<EventModel> filteredEvents = events.where((e) {
                    final now = DateTime.now();
                    final todayStart = DateTime(now.year, now.month, now.day);
                    if (e.date != null && e.date!.isBefore(todayStart)) {
                      return false;
                    }

                    if (_primaryFilter != null && _subFilter == null) {
                      return e.category == _primaryFilter;
                    } else if (_subFilter != null) {
                      return e.category == _primaryFilter && e.subCategory == _subFilter;
                    }
                    return true;
                  }).toList();

                  // Sort by date approaching
                  filteredEvents.sort((a, b) {
                    final dateA = a.date ?? DateTime.now();
                    final dateB = b.date ?? DateTime.now();
                    return dateA.compareTo(dateB);
                  });

                  Widget content;
                  if (filteredEvents.isEmpty) {
                    content = const Center(child: Text('No events found.'));
                  } else if (_primaryFilter != null) {
                    // Show only vertical list
                    content = ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredEvents.length,
                      itemBuilder: (context, index) {
                        return EventCard(
                          event: filteredEvents[index],
                          onTap: () => context.push('/event/${filteredEvents[index].id}', extra: filteredEvents[index]),
                        );
                      },
                    );
                  } else {
                    // No filters active, split into This Week and Remaining
                    final now = DateTime.now();
                    final thisWeekEvents = filteredEvents.where((e) {
                      final d = e.date;
                      if (d == null) return false;
                      // Upcoming within 7 days
                      return d.isAfter(now.subtract(const Duration(days: 1))) && d.isBefore(now.add(const Duration(days: 7)));
                    }).take(5).toList();

                    final remainingEvents = filteredEvents.where((e) => !thisWeekEvents.contains(e)).toList();

                    content = ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        if (thisWeekEvents.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Text('This Week', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(
                            height: 280,
                            child: PageView.builder(
                              controller: PageController(viewportFraction: 0.85),
                              itemCount: thisWeekEvents.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: EventCard(
                                    event: thisWeekEvents[index],
                                    isThisWeekCard: true,
                                    onTap: () => context.push('/event/${thisWeekEvents[index].id}', extra: thisWeekEvents[index]),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (remainingEvents.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Text('All Events', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          ),
                          ...remainingEvents.map((event) => EventCard(
                            event: event,
                            onTap: () => context.push('/event/${event.id}', extra: event),
                          )).toList(),
                        ]
                      ],
                    );
                  }

                  return NotificationListener<ScrollUpdateNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.axis == Axis.vertical && 
                          notification.metrics.pixels < -100) {
                        if (!_isNavigatingToScrollMode) {
                          _isNavigatingToScrollMode = true;
                          context.push('/scroll_mode').then((_) => _isNavigatingToScrollMode = false);
                        }
                      }
                      return false;
                    },
                    child: content,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: userRole == 'coordinator' ? FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () => context.push('/create_event'),
        child: const Icon(Icons.add, color: Colors.black),
      ) : null,
    );
  }
}
