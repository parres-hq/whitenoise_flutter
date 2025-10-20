import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

class ImagePickerService {
  static final _logger = Logger('ImagePickerService');
  final ImagePicker _imagePicker;

  ImagePickerService({ImagePicker? imagePicker}) : _imagePicker = imagePicker ?? ImagePicker();

  Future<String?> pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      return image?.path;
    } catch (e) {
      _logger.severe('Failed to pick image: $e');
      rethrow;
    }
  }

  Future<List<String>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      return images.map((image) => image.path).toList();
    } catch (e) {
      _logger.severe('Failed to pick images: $e');
      rethrow;
    }
  }
}
