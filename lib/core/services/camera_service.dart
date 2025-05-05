import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class CameraService {
  // Singleton pattern
  CameraService._privateConstructor();
  static final CameraService _instance = CameraService._privateConstructor();
  static CameraService get instance => _instance;
  
  final ImagePicker _imagePicker = ImagePicker();
  List<CameraDescription>? cameras;
  
  Future<void> initializeCameras() async {
    cameras = await availableCameras();
  }
  
  Future<File?> takePhoto() async {
    final XFile? photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 80,
    );
    
    if (photo != null) {
      return File(photo.path);
    }
    return null;
  }
  
  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (image != null) {
      return File(image.path);
    }
    return null;
  }
}