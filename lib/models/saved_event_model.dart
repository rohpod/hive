class SavedEventModel {
  final String id;
  final String userId;
  final String eventId;
  final bool isPresent;
  final String? certificateUrl;

  SavedEventModel({
    required this.id,
    required this.userId,
    required this.eventId,
    this.isPresent = false,
    this.certificateUrl,
  });

  factory SavedEventModel.fromJson(Map<String, dynamic> json, String documentId) {
    return SavedEventModel(
      id: documentId,
      userId: json['userId'] ?? '',
      eventId: json['eventId'] ?? '',
      isPresent: json['isPresent'] ?? false,
      certificateUrl: json['certificateUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'eventId': eventId,
      'isPresent': isPresent,
      if (certificateUrl != null) 'certificateUrl': certificateUrl,
    };
  }
}
