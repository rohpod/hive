class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'student' or 'coordinator'
  final String? clubName;
  final String? year;
  final String? department;
  final String? usn;
  final String? branch;
  final int totalActivityPoints;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.clubName,
    this.year,
    this.department,
    this.usn,
    this.branch,
    this.totalActivityPoints = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      id: documentId,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      clubName: json['clubName'],
      year: json['year'],
      department: json['department'],
      usn: json['usn'],
      branch: json['branch'],
      totalActivityPoints: json['totalActivityPoints'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      if (clubName != null) 'clubName': clubName,
      if (year != null) 'year': year,
      if (department != null) 'department': department,
      if (usn != null) 'usn': usn,
      if (branch != null) 'branch': branch,
      'totalActivityPoints': totalActivityPoints,
    };
  }
}
