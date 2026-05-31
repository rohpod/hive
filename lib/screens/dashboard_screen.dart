import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/events_provider.dart';
import '../providers/saved_events_provider.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/saved_event_model.dart';
import '../widgets/event_card.dart';
import '../widgets/glass_container.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generateAndDownloadCertificate(UserModel user, EventModel event) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(40),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 5, color: PdfColors.blueAccent),
              ),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('CERTIFICATE OF PARTICIPATION', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.SizedBox(height: 20),
                  pw.Text('This is to certify that', style: const pw.TextStyle(fontSize: 20)),
                  pw.SizedBox(height: 10),
                  pw.Text(user.name, style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                  pw.SizedBox(height: 10),
                  pw.Text('has successfully participated in', style: const pw.TextStyle(fontSize: 20)),
                  pw.SizedBox(height: 10),
                  pw.Text(event.title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  if (event.clubName != null) ...[
                    pw.SizedBox(height: 8),
                    pw.Text('Organized by ${event.clubName}', style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
                  ],
                  pw.SizedBox(height: 30),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Date: ${event.date?.toString().split(" ")[0] ?? "N/A"}', style: const pw.TextStyle(fontSize: 16)),
                      pw.Text('Activity Points Awarded: ${event.activityPoints}', style: const pw.TextStyle(fontSize: 16)),
                    ]
                  )
                ],
              ),
            ),
          );
        },
      ),
    );

    try {
      final Uint8List bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: '${event.title.replaceAll(" ", "_")}_Certificate.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate certificate: $e')));
    } finally {
      if (mounted) Navigator.pop(context); // close dialog
    }
  }

  Future<void> _generateAndDownloadFoodCoupon(UserModel user, EventModel event) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final pdf = pw.Document();
    
    final couponId = 'FC-${DateTime.now().year}-${(user.id + event.id).hashCode.abs().toString().padLeft(6, '0')}';
    final dateGenerated = DateTime.now().toString().split(" ")[0];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5.landscape,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 3, color: PdfColors.orange),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('FOOD COUPON', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                  pw.SizedBox(height: 10),
                  if (event.clubName != null && event.clubName!.isNotEmpty) ...[
                    pw.Text(event.clubName!, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                    pw.SizedBox(height: 10),
                  ],
                  pw.Text('This coupon entitles the attendee to receive complimentary food provided as part of the event.', 
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 15),
                  pw.Divider(color: PdfColors.grey400),
                  pw.SizedBox(height: 10),
                  
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Attendee Details', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                            pw.SizedBox(height: 5),
                            pw.Text('Name: ${user.name}', style: const pw.TextStyle(fontSize: 12)),
                            if (user.usn != null && user.usn!.isNotEmpty) pw.Text('USN: ${user.usn}', style: const pw.TextStyle(fontSize: 12)),
                            pw.SizedBox(height: 15),
                            pw.Text('Event Details', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                            pw.SizedBox(height: 5),
                            pw.Text('Event: ${event.title}', style: const pw.TextStyle(fontSize: 12)),
                            pw.Text('Date: ${event.date?.toString().split(" ")[0] ?? "N/A"}', style: const pw.TextStyle(fontSize: 12)),
                            if (event.time.isNotEmpty) pw.Text('Time: ${event.time}', style: const pw.TextStyle(fontSize: 12)),
                            if (event.venue.isNotEmpty) pw.Text('Venue: ${event.venue}', style: const pw.TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.BarcodeWidget(
                              barcode: pw.Barcode.qrCode(),
                              data: 'UserID:${user.id}|EventID:${event.id}|CouponID:$couponId',
                              width: 80,
                              height: 80,
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text('ID: $couponId', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Date: $dateGenerated', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                    ]
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    try {
      final Uint8List bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: '${event.title.replaceAll(" ", "_")}_FoodCoupon.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate food coupon: $e')));
    } finally {
      if (mounted) Navigator.pop(context); // close dialog
    }
  }

  void _editProfile(UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final usnCtrl = TextEditingController(text: user.usn ?? '');
    final yearCtrl = TextEditingController(text: user.year ?? '');
    final branchCtrl = TextEditingController(text: user.branch ?? '');
    final deptCtrl = TextEditingController(text: user.department ?? '');
    final clubCtrl = TextEditingController(text: user.clubName ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              if (user.role == 'student') ...[
                const SizedBox(height: 8),
                TextField(controller: usnCtrl, decoration: const InputDecoration(labelText: 'USN')),
                const SizedBox(height: 8),
                TextField(controller: branchCtrl, decoration: const InputDecoration(labelText: 'Branch')),
                const SizedBox(height: 8),
                TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: 'Year')),
                const SizedBox(height: 8),
                TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Department')),
              ] else if (user.role == 'coordinator') ...[
                const SizedBox(height: 8),
                TextField(controller: clubCtrl, decoration: const InputDecoration(labelText: 'Club Name')),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final updatedUser = UserModel(
                id: user.id,
                email: user.email,
                role: user.role,
                name: nameCtrl.text.trim(),
                usn: user.role == 'student' ? usnCtrl.text.trim() : user.usn,
                branch: user.role == 'student' ? branchCtrl.text.trim() : user.branch,
                year: user.role == 'student' ? yearCtrl.text.trim() : user.year,
                department: user.role == 'student' ? deptCtrl.text.trim() : user.department,
                clubName: user.role == 'coordinator' ? clubCtrl.text.trim() : user.clubName,
                totalActivityPoints: user.totalActivityPoints,
              );
              await ref.read(databaseServiceProvider).updateUser(updatedUser);
              if (mounted) {
                ref.invalidate(currentUserModelProvider);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserModelProvider);
    final eventsAsync = ref.watch(eventsStreamProvider);
    final savedAsync = ref.watch(savedEventsStreamProvider);
    
    return Scaffold(
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));

          int displayPoints = user.totalActivityPoints;
          if (user.role == 'student' && savedAsync.hasValue && eventsAsync.hasValue) {
            final savedEvents = savedAsync.value!;
            final allEvents = eventsAsync.value!;
            final eventMap = {for (var e in allEvents) e.id: e};
            
            int calculatedPoints = 0;
            for (var s in savedEvents) {
              if (s.isPresent && eventMap.containsKey(s.eventId)) {
                calculatedPoints += eventMap[s.eventId]!.activityPoints;
              }
            }
            displayPoints = calculatedPoints;

            if (displayPoints != user.totalActivityPoints) {
              Future.microtask(() {
                ref.read(databaseServiceProvider).recalculateUserPoints(user.id);
              });
            }
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  title: const Text('Dashboard'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () => ref.read(authServiceProvider).logout(),
                    )
                  ],
                  floating: false,
                  pinned: false,
                ),
                SliverToBoxAdapter(
                  child: GlassContainer(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(user.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.edit, color: Colors.white70), onPressed: () => _editProfile(user)),
                          ],
                        ),
                        Text(user.email, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 12),
                        if (user.role == 'student') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('USN: ${user.usn ?? "N/A"}', style: const TextStyle(color: Colors.white)),
                                  Text('Branch: ${user.branch ?? "N/A"}', style: const TextStyle(color: Colors.white)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Theme.of(context).colorScheme.primary),
                                  boxShadow: [
                                    BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)
                                  ]
                                ),
                                child: Column(
                                  children: [
                                    Text('$displayPoints', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                    const Text('Total Points', style: TextStyle(fontSize: 10, color: Colors.white70)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ] else if (user.role == 'coordinator') ...[
                          Text('Club: ${user.clubName ?? "N/A"}', style: const TextStyle(color: Colors.white)),
                        ]
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Colors.white54,
                      tabs: const [
                        Tab(text: 'Upcoming'),
                        Tab(text: 'History'),
                      ],
                    ),
                    Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                user.role == 'student' 
                  ? _buildStudentEvents(user, eventsAsync, false)
                  : _buildCoordinatorEvents(user, eventsAsync, false),
                user.role == 'student' 
                  ? _buildStudentEvents(user, eventsAsync, true)
                  : _buildCoordinatorEvents(user, eventsAsync, true),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStudentEvents(UserModel user, AsyncValue<List<EventModel>> eventsAsync, bool isHistory) {
    final savedAsync = ref.watch(savedEventsStreamProvider);
    
    return savedAsync.when(
      data: (savedEvents) {
        if (savedEvents.isEmpty) return const Center(child: Text('No registered events.'));
        
        return eventsAsync.when(
          data: (allEvents) {
            final now = DateTime.now();
            final savedEventMap = {for (var s in savedEvents) s.eventId: s};
            
            final myEvents = allEvents.where((e) {
              if (!savedEventMap.containsKey(e.id)) return false;
              final isPast = e.date != null && e.date!.isBefore(now);
              return isHistory ? isPast : !isPast;
            }).toList();
            
            myEvents.sort((a, b) {
              final da = a.date ?? DateTime.now();
              final db = b.date ?? DateTime.now();
              return isHistory ? db.compareTo(da) : da.compareTo(db);
            });

            if (myEvents.isEmpty) {
               return Center(child: Text(isHistory ? 'No past events.' : 'No upcoming events.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 16),
              itemCount: myEvents.length,
              itemBuilder: (ctx, idx) {
                final event = myEvents[idx];
                final savedRecord = savedEventMap[event.id]!;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0, left: 16, right: 16),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EventCard(
                          event: event,
                          onTap: () => context.push('/event/${event.id}', extra: event),
                        ),
                        if (event.isFreeFoodProvided && (event.date == null || !DateTime(event.date!.year, event.date!.month, event.date!.day).isAfter(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))))
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 4),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () => _generateAndDownloadFoodCoupon(user, event),
                              icon: const Icon(Icons.fastfood, size: 16),
                              label: const Text('Download Food Coupon', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        if (isHistory)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: savedRecord.isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(savedRecord.isPresent ? Icons.check_circle : Icons.cancel, color: savedRecord.isPresent ? Colors.greenAccent : Colors.redAccent),
                                    const SizedBox(width: 8),
                                    Text(savedRecord.isPresent ? 'Attended (+${event.activityPoints} pts)' : 'Missed', style: TextStyle(color: savedRecord.isPresent ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                if (savedRecord.isPresent) ...[
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: () => _generateAndDownloadCertificate(user, event),
                                    icon: const Icon(Icons.download, size: 16),
                                    label: const Text('Download Certificate', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ],
                            ),
                          )
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e,s) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e,s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildCoordinatorEvents(UserModel user, AsyncValue<List<EventModel>> eventsAsync, bool isArchived) {
    final myEventsAsync = ref.watch(myEventsStreamProvider);

    return myEventsAsync.when(
      data: (events) {
        final now = DateTime.now();
        final myEvents = events.where((e) {
          final isPast = e.date != null && e.date!.isBefore(now);
          return isArchived ? isPast : !isPast;
        }).toList();

        myEvents.sort((a, b) {
          final da = a.date ?? DateTime.now();
          final db = b.date ?? DateTime.now();
          return isArchived ? db.compareTo(da) : da.compareTo(db);
        });

        if (myEvents.isEmpty) {
          return Center(child: Text(isArchived ? 'No archived events.' : 'No upcoming events.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16),
          itemCount: myEvents.length,
          itemBuilder: (ctx, idx) {
            final ev = myEvents[idx];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              clipBehavior: Clip.antiAlias,
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
              ),
              child: InkWell(
                onTap: () => context.push('/event/${ev.id}', extra: ev),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ev.imageUrl.isNotEmpty)
                      Image.network(ev.imageUrl, height: 120, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___)=>Container(height:120, color:Colors.grey[800]))
                    else
                      Container(height: 120, color: Colors.grey[800], child: const Icon(Icons.image)),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ev.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!isArchived)
                                OutlinedButton.icon(
                                  onPressed: () => context.push('/edit_event', extra: ev),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => context.push('/view_participants', extra: ev),
                                icon: const Icon(Icons.people, size: 16, color: Colors.black),
                                label: const Text('Participants', style: TextStyle(color: Colors.black)),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e,s) => Center(child: Text('Error: $e')),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _StickyTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || backgroundColor != oldDelegate.backgroundColor;
  }
}
