import 'package:cloud_firestore/cloud_firestore.dart';

class Sponsor {
  final String name;
  final String logoUrl;
  final String websiteUrl;

  Sponsor({required this.name, required this.logoUrl, required this.websiteUrl});

  factory Sponsor.fromJson(Map<String, dynamic> json) {
    return Sponsor(
      name: json['name'] ?? '',
      logoUrl: json['logoUrl'] ?? '',
      websiteUrl: json['websiteUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'websiteUrl': websiteUrl,
    };
  }
}


class EventModel {
  final String id;
  final String title;
  final String imageUrl;
  final DateTime? date;
  final String time;
  final String venue;
  final String description;
  final String category;
  final String? subCategory;
  final String? clubName;
  final String createdByUserId;
  final DateTime timestamp;
  final int maxRegistrations;
  final int activityPoints;
  final bool isFreeFoodProvided;
  final bool isAttendanceProvided;
  final List<Sponsor> sponsors;

  EventModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.date,
    required this.time,
    required this.venue,
    required this.description,
    required this.category,
    this.subCategory,
    this.clubName,
    required this.createdByUserId,
    required this.timestamp,
    this.maxRegistrations = 0, // 0 means unlimited
    this.activityPoints = 0,
    this.isFreeFoodProvided = false,
    this.isAttendanceProvided = false,
    this.sponsors = const [],
  });

  factory EventModel.fromJson(Map<String, dynamic> json, String documentId) {
    DateTime? parsedDate;
    if (json['date'] is Timestamp) {
      parsedDate = (json['date'] as Timestamp).toDate();
    } else if (json['date'] is String) {
      parsedDate = DateTime.tryParse(json['date']);
    }

    return EventModel(
      id: documentId,
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      date: parsedDate,
      time: json['time'] ?? '',
      venue: json['venue'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['subCategory'],
      clubName: json['clubName'],
      createdByUserId: json['createdByUserId'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxRegistrations: json['maxRegistrations'] ?? 0,
      activityPoints: json['activityPoints'] ?? 0,
      isFreeFoodProvided: json['isFreeFoodProvided'] ?? false,
      isAttendanceProvided: json['isAttendanceProvided'] ?? false,
      sponsors: (json['sponsors'] as List<dynamic>?)
              ?.map((e) => Sponsor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      if (date != null) 'date': Timestamp.fromDate(date!),
      'time': time,
      'venue': venue,
      'description': description,
      'category': category,
      if (subCategory != null) 'subCategory': subCategory,
      if (clubName != null) 'clubName': clubName,
      'createdByUserId': createdByUserId,
      'timestamp': Timestamp.fromDate(timestamp),
      'maxRegistrations': maxRegistrations,
      'activityPoints': activityPoints,
      'isFreeFoodProvided': isFreeFoodProvided,
      'isAttendanceProvided': isAttendanceProvided,
      'sponsors': sponsors.map((s) => s.toJson()).toList(),
    };
  }
}
