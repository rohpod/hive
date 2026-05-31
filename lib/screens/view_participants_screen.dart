import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../models/saved_event_model.dart';
import '../providers/events_provider.dart';

class ViewParticipantsScreen extends ConsumerStatefulWidget {
  final EventModel event;
  const ViewParticipantsScreen({super.key, required this.event});

  @override
  ConsumerState<ViewParticipantsScreen> createState() => _ViewParticipantsScreenState();
}

class _ViewParticipantsScreenState extends ConsumerState<ViewParticipantsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allParticipants = [];
  List<Map<String, dynamic>> _filteredParticipants = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadParticipants();
    _searchController.addListener(_filterParticipants);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadParticipants() async {
    setState(() => _isLoading = true);
    try {
      final participants = await ref.read(databaseServiceProvider).getEventParticipantsWithStatus(widget.event.id);
      if (mounted) {
        setState(() {
          _allParticipants = participants;
          _filteredParticipants = participants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _filterParticipants() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredParticipants = _allParticipants.where((p) {
        final user = p['user'] as UserModel;
        return user.name.toLowerCase().contains(query) || (user.usn?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _toggleAttendance(int index, bool isPresent) async {
    final participant = _filteredParticipants[index];
    final user = participant['user'] as UserModel;
    
    // Optimistic UI update
    setState(() {
      _filteredParticipants[index]['savedEvent'] = SavedEventModel(
        id: participant['savedEvent'].id,
        userId: participant['savedEvent'].userId,
        eventId: participant['savedEvent'].eventId,
        isPresent: isPresent,
        certificateUrl: participant['savedEvent'].certificateUrl,
      );
    });

    try {
      await ref.read(databaseServiceProvider).toggleAttendance(user.id, widget.event.id, isPresent, widget.event.activityPoints);
    } catch (e) {
      // Revert if failed
      if (mounted) {
        setState(() {
          _filteredParticipants[index]['savedEvent'] = SavedEventModel(
            id: participant['savedEvent'].id,
            userId: participant['savedEvent'].userId,
            eventId: participant['savedEvent'].eventId,
            isPresent: !isPresent,
            certificateUrl: participant['savedEvent'].certificateUrl,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update attendance: $e')));
      }
    }
  }

  Future<void> _exportData() async {
    if (_allParticipants.isEmpty) return;

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      sheetObject.appendRow([
        TextCellValue("Student Name"), 
        TextCellValue("USN"), 
        TextCellValue("Email"), 
        TextCellValue("Branch"), 
        TextCellValue("Present")
      ]);
      
      for (var p in _allParticipants) {
        final user = p['user'] as UserModel;
        final savedEvent = p['savedEvent'] as SavedEventModel;
        sheetObject.appendRow([
          TextCellValue(user.name),
          TextCellValue(user.usn ?? "N/A"),
          TextCellValue(user.email),
          TextCellValue(user.branch ?? "N/A"),
          TextCellValue(savedEvent.isPresent ? "Yes" : "No")
        ]);
      }

      var fileBytes = excel.save();
      
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${widget.event.title.replaceAll(' ', '_')}_participants.xlsx';
      final file = File(path);
      await file.writeAsBytes(fileBytes!);
      
      await Share.shareXFiles([XFile(path)], text: 'Participants list for ${widget.event.title}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting data: $e')));
    }
  }

  Widget _buildGlowingCheckbox(bool isChecked, ValueChanged<bool?> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!isChecked),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isChecked ? Colors.greenAccent : Colors.grey,
            width: 2,
          ),
          boxShadow: isChecked ? [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ] : [],
        ),
        child: isChecked ? const Icon(Icons.check, size: 18, color: Colors.greenAccent) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Participants')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.event.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Total Registered: ${_allParticipants.length}${widget.event.maxRegistrations > 0 ? " / ${widget.event.maxRegistrations}" : ""}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by Name or USN...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (_filteredParticipants.isEmpty)
                  const Expanded(child: Center(child: Text('No participants found.')))
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredParticipants.length,
                      itemBuilder: (context, index) {
                        final p = _filteredParticipants[index];
                        final user = p['user'] as UserModel;
                        final savedEvent = p['savedEvent'] as SavedEventModel;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.black)),
                          ),
                          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${user.usn ?? "No USN"} • ${user.branch ?? "No Branch"}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Present: ', style: TextStyle(fontSize: 12)),
                              _buildGlowingCheckbox(savedEvent.isPresent, (val) {
                                if (val != null) _toggleAttendance(index, val);
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  )
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportData,
        icon: const Icon(Icons.download),
        label: const Text('Export Data'),
      ),
    );
  }
}
