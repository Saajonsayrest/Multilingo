import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/domain/state_split.dart';
import 'package:multilingo/state/app_state.dart';

import 'support/full_state.dart';

void main() {
  test('every field is filed under the profile or one language, never both', () {
    // A new AppState field that is not listed in state_split.dart fails here,
    // so it can never be left out of a cloud save by accident.
    final keys = AppState().toJson().keys.toSet();
    expect(profileStateKeys.intersection(courseStateKeys), isEmpty);
    expect(
      keys.difference({...profileStateKeys, ...courseStateKeys}),
      isEmpty,
      reason: 'list these AppState fields in profileStateKeys or courseStateKeys',
    );
    expect(
      {...profileStateKeys, ...courseStateKeys}.difference(keys),
      isEmpty,
      reason: 'these listed keys no longer exist in AppState',
    );
  });

  test('the test state really covers every field', () {
    // Each field is non-default, so none is silently skipped by the check
    // above. Compare against a fresh state key by key.
    final fresh = AppState().toJson();
    final full = everything().toJson();
    expect(full.keys.toSet(), fresh.keys.toSet());
    final unchanged = [
      for (final k in fresh.keys)
        if (jsonEncode(fresh[k]) == jsonEncode(full[k])) k,
    ];
    expect(unchanged, isEmpty, reason: 'fields left at default: $unchanged');
  });

  test('splitting and merging gives the same state back', () {
    final json = everything().toJson();
    final (profile, course) = splitState(json);
    expect(profile.keys.toSet(), profileStateKeys);
    expect(course.keys.toSet(), courseStateKeys);
    expect(jsonEncode(mergeState(profile, course)), jsonEncode({...course, ...profile}));
    expect(mergeState(profile, course), json);
  });

  test('a key nobody filed goes to the profile, so it is still saved', () {
    final (profile, course) = splitState({'brandNew': 1, 'wordBox': <String, int>{}});
    expect(profile, {'brandNew': 1});
    expect(course.keys, ['wordBox']);
  });

  test('sanitizing a valid state changes nothing', () {
    final s = everything();
    expect(jsonEncode(s.sanitized().toJson()), jsonEncode(s.toJson()));
  });
}
