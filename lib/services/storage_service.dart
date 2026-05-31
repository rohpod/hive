import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class StorageService {
  // TODO: Replace with your actual Cloudinary Cloud Name and Upload Preset
  static const String _cloudName = 'dqvgqesjn';
  static const String _uploadPreset = 'hive_app_up';

  final cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);

  Future<String?> uploadEventImage(File imageFile) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      print("Error uploading image to Cloudinary: $e");
      return null;
    }
  }
}
