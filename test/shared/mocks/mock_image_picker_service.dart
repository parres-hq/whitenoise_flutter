import 'package:whitenoise/domain/services/image_picker_service.dart';

class MockImagePickerService extends ImagePickerService {
  List<String>? imagesToReturn;
  Exception? errorToThrow;

  @override
  Future<List<String>> pickMultipleImages() async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return imagesToReturn ?? [];
  }
}
