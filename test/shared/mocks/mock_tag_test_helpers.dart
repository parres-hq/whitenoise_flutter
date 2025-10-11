import 'package:whitenoise/src/rust/api/messages.dart';

class MockTag implements Tag {
  final List<String> tagData;

  MockTag(this.tagData);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<Tag> Function({required List<String> vec}) mockTagFromVec(
  List<List<String>> capturedTags,
) {
  return ({required List<String> vec}) async {
    capturedTags.add(List.from(vec));
    return MockTag(vec);
  };
}
