import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:whitenoise/domain/services/image_picker_service.dart';

import 'image_picker_service_test.mocks.dart';

@GenerateMocks([ImagePicker, XFile])
void main() {
  group('ImagePickerService', () {
    late MockImagePicker mockImagePicker;
    late ImagePickerService service;

    setUp(() {
      mockImagePicker = MockImagePicker();
      service = ImagePickerService(imagePicker: mockImagePicker);
    });

    group('pickProfileImage', () {
      group('when image is picked', () {
        setUp(() {
           final mockXFile = MockXFile();
          when(mockXFile.path).thenReturn('/path/to/image.jpg');
          when(mockImagePicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 512,
            maxHeight: 512,
            imageQuality: 85,
          )).thenAnswer((_) async => mockXFile);
        });

        test('pickProfileImage returns path when image is picked', () async {
          final result = await service.pickProfileImage();
          expect(result, '/path/to/image.jpg');
        });
      });  

      group('when no image is picked', () {
        setUp(() {
          when(mockImagePicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 512,
            maxHeight: 512,
            imageQuality: 85,
          )).thenAnswer((_) async => null);
        });

        test('returns null', () async {
          final result = await service.pickProfileImage();
          expect(result, isNull);
        });
      });

      group('when picker fails', () {
        setUp(() {
          when(mockImagePicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 512,
            maxHeight: 512,
            imageQuality: 85,
          )).thenThrow(Exception('Picker failed'));
        });

        test('rethrows exception', () async {
          expect(() => service.pickProfileImage(), throwsException);
        });
      });
    });
  });
}
