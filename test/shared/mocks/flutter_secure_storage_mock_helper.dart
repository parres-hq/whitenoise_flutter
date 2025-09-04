import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'flutter_secure_storage_mock_helper.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
class FlutterSecureStorageMockHelper {
  static ({MockFlutterSecureStorage mock, Map<String, String> storage}) createInMemoryMock() {
    final mockStorage = MockFlutterSecureStorage();
    final inMemoryStorage = <String, String>{};

    when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value'))).thenAnswer((
      invocation,
    ) async {
      final key = invocation.namedArguments[#key] as String;
      final value = invocation.namedArguments[#value] as String;
      inMemoryStorage[key] = value;
    });

    when(mockStorage.read(key: anyNamed('key'))).thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      return inMemoryStorage[key];
    });

    when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      inMemoryStorage.remove(key);
    });

    when(mockStorage.readAll()).thenAnswer((_) async => Map<String, String>.from(inMemoryStorage));

    when(mockStorage.deleteAll()).thenAnswer((_) async {
      inMemoryStorage.clear();
    });

    return (mock: mockStorage, storage: inMemoryStorage);
  }
}
