import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../providers/auth_provider.dart';
import '../providers/events_provider.dart';
import '../providers/storage_provider.dart';

class AddEventScreen extends ConsumerStatefulWidget {
  const AddEventScreen({super.key});

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _venueController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxRegController = TextEditingController();
  final _activityPointsController = TextEditingController();
  
  bool _isFreeFoodProvided = false;
  bool _isAttendanceProvided = false;
  final List<Sponsor> _sponsors = [];
  
  String? _selectedCategory;
  String? _selectedSubCategory;

  final Map<String, List<String>> _subcategories = {
    'Technical': ['Hackathon', 'Workshop', 'Seminar'],
    'Cultural': ['Art', 'Music', 'Dance', 'Misc'],
  };

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  File? _imageFile;
  bool _isLoading = false;
  bool _dateError = false;
  bool _timeError = false;

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
    bool showNameError = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Add Sponsor'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: const OutlineInputBorder(),
                      errorText: showNameError ? 'Sponsor name is required.' : null,
                    ),
                  ),
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
                  if (nameCtrl.text.trim().isEmpty) {
                    setStateDialog(() => showNameError = true);
                  } else {
                    setState(() {
                      _sponsors.add(Sponsor(name: nameCtrl.text.trim(), logoUrl: logoCtrl.text.trim(), websiteUrl: webCtrl.text.trim()));
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Add'),
              )
            ],
          );
        }
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _dateError = _selectedDate == null;
      _timeError = _selectedTime == null;
    });

    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null || _selectedCategory == null || _selectedSubCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserModelProvider).value;
      if (user == null) throw Exception('User not logged in');

      String imageUrl = '';
      if (_imageFile != null) {
        final uploadedUrl = await ref.read(storageServiceProvider).uploadEventImage(_imageFile!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          throw Exception('Image upload failed');
        }
      }


      final timeStr = _selectedTime!.format(context);

      final newEvent = EventModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        imageUrl: imageUrl,
        date: _selectedDate,
        time: timeStr,
        venue: _venueController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        subCategory: _selectedSubCategory,
        clubName: user.clubName,
        createdByUserId: user.id,
        timestamp: DateTime.now(),
        maxRegistrations: int.tryParse(_maxRegController.text) ?? 0,
        activityPoints: int.tryParse(_activityPointsController.text) ?? 0,
        isFreeFoodProvided: _isFreeFoodProvided,
        isAttendanceProvided: _isAttendanceProvided,
        sponsors: _sponsors,
      );

      await ref.read(databaseServiceProvider).createEvent(newEvent);

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Event')),
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
                            : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  style: _dateError ? OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)) : null,
                                  onPressed: () async {
                                    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                                    if (date != null) setState(() { _selectedDate = date; _dateError = false; });
                                  },
                                  child: Text(_selectedDate == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                                ),
                              ),
                              if (_dateError)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8.0, left: 12.0),
                                  child: Text('Please select an event date.', style: TextStyle(color: Colors.red, fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  style: _timeError ? OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)) : null,
                                  onPressed: () async {
                                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                    if (time != null) setState(() { _selectedTime = time; _timeError = false; });
                                  },
                                  child: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                                ),
                              ),
                              if (_timeError)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8.0, left: 12.0),
                                  child: Text('Please select an event time.', style: TextStyle(color: Colors.red, fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
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
                        child: const Text('Create Event'),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
