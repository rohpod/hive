import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../providers/auth_provider.dart';
import '../providers/events_provider.dart';
import '../providers/storage_provider.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  final EventModel event;
  const EditEventScreen({super.key, required this.event});

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _venueController;
  late TextEditingController _descriptionController;
  late TextEditingController _maxRegController;
  late TextEditingController _activityPointsController;
  
  late bool _isFreeFoodProvided;
  late bool _isAttendanceProvided;
  late List<Sponsor> _sponsors;

  String? _selectedCategory;
  String? _selectedSubCategory;

  final Map<String, List<String>> _subcategories = {
    'Technical': ['Hackathon', 'Workshop', 'Seminar'],
    'Cultural': ['Art', 'Music', 'Dance', 'Misc'],
  };

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _venueController = TextEditingController(text: widget.event.venue);
    _descriptionController = TextEditingController(text: widget.event.description);
    _maxRegController = TextEditingController(text: widget.event.maxRegistrations > 0 ? widget.event.maxRegistrations.toString() : '');
    _activityPointsController = TextEditingController(text: widget.event.activityPoints > 0 ? widget.event.activityPoints.toString() : '');
    _isFreeFoodProvided = widget.event.isFreeFoodProvided;
    _isAttendanceProvided = widget.event.isAttendanceProvided;
    _sponsors = List.from(widget.event.sponsors);
    
    _selectedCategory = _subcategories.containsKey(widget.event.category) 
        ? widget.event.category 
        : null;

    if (_selectedCategory != null && widget.event.subCategory != null) {
      _selectedSubCategory = _subcategories[_selectedCategory]!.contains(widget.event.subCategory)
          ? widget.event.subCategory
          : null;
    } else {
      _selectedSubCategory = null;
    }
    
    _selectedDate = widget.event.date ?? DateTime.now();
    _selectedTime = const TimeOfDay(hour: 12, minute: 0); 
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _showAddSponsorDialog() {
    final nameCtrl = TextEditingController();
    final logoCtrl = TextEditingController();
    final webCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Sponsor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: logoCtrl, decoration: const InputDecoration(labelText: 'Logo URL', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: webCtrl, decoration: const InputDecoration(labelText: 'Website URL', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  _sponsors.add(Sponsor(name: nameCtrl.text.trim(), logoUrl: logoCtrl.text.trim(), websiteUrl: webCtrl.text.trim()));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String imageUrl = widget.event.imageUrl;
      if (_imageFile != null) {
        final newUrl = await ref.read(storageServiceProvider).uploadEventImage(_imageFile!);
        if (newUrl != null) imageUrl = newUrl;
      }

      if (_selectedCategory == null || _selectedSubCategory == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
        return;
      }

      final updatedEvent = EventModel(
        id: widget.event.id,
        title: _titleController.text.trim(),
        imageUrl: imageUrl,
        date: _selectedDate,
        time: _selectedTime.format(context),
        venue: _venueController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        subCategory: _selectedSubCategory,
        clubName: widget.event.clubName,
        createdByUserId: widget.event.createdByUserId,
        timestamp: widget.event.timestamp,
        maxRegistrations: int.tryParse(_maxRegController.text) ?? 0,
        activityPoints: int.tryParse(_activityPointsController.text) ?? 0,
        isFreeFoodProvided: _isFreeFoodProvided,
        isAttendanceProvided: _isAttendanceProvided,
        sponsors: _sponsors,
      );

      await ref.read(databaseServiceProvider).updateEvent(updatedEvent);

      if (mounted) {
        context.pop(); // pop edit screen
        context.pop(); // optionally pop details screen to go back to my_events/home
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Event'),
                  content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirm == true) {
                setState(() => _isLoading = true);
                try {
                  await ref.read(databaseServiceProvider).deleteEvent(widget.event.id);
                  if (mounted) {
                    context.pop(); // pop edit screen
                    context.pop(); // pop details screen
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  if (mounted) setState(() => _isLoading = false);
                }
              }
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        color: Theme.of(context).colorScheme.surface,
                        child: _imageFile != null
                            ? Image.file(_imageFile!, fit: BoxFit.cover)
                            : (widget.event.imageUrl.isNotEmpty
                                ? Image.network(widget.event.imageUrl, fit: BoxFit.cover)
                                : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(
                          onPressed: () async {
                            final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                            if (date != null) setState(() => _selectedDate = date);
                          },
                          child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: OutlinedButton(
                          onPressed: () async {
                            final time = await showTimePicker(context: context, initialTime: _selectedTime);
                            if (time != null) setState(() => _selectedTime = time);
                          },
                           child: Text(_selectedTime.format(context)),
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _venueController,
                      decoration: const InputDecoration(labelText: 'Venue', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      value: _selectedCategory,
                      items: _subcategories.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                          _selectedSubCategory = null; // Reset subcategory when category changes
                        });
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_selectedCategory != null) ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Subcategory', border: OutlineInputBorder()),
                        value: _selectedSubCategory,
                        items: _subcategories[_selectedCategory]!.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _selectedSubCategory = val),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 3,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _maxRegController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max Registrations', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _activityPointsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Activity Points', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Free Food Provided'),
                      value: _isFreeFoodProvided,
                      onChanged: (val) => setState(() => _isFreeFoodProvided = val),
                    ),
                    SwitchListTile(
                      title: const Text('Attendance Provided'),
                      value: _isAttendanceProvided,
                      onChanged: (val) => setState(() => _isAttendanceProvided = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sponsors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _showAddSponsorDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        )
                      ],
                    ),
                    if (_sponsors.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _sponsors.length,
                        itemBuilder: (ctx, idx) {
                          final sponsor = _sponsors[idx];
                          return ListTile(
                            leading: sponsor.logoUrl.isNotEmpty ? CircleAvatar(backgroundImage: NetworkImage(sponsor.logoUrl)) : const CircleAvatar(child: Icon(Icons.business)),
                            title: Text(sponsor.name),
                            subtitle: Text(sponsor.websiteUrl),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => setState(() => _sponsors.removeAt(idx)),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Update Event'),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
