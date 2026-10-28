import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/course.dart';
import '../data/languages.dart';
import 'controller.dart';

const activeCourseKey = 'multilingo.activeCourse.v1';

/// Where the progress of every language that is NOT being learned right now
/// is kept. The active language lives in the main app state.
const otherCoursesKey = 'multilingo.otherCourses.v1';

/// Reads the saved progress of the languages that are not active.
Map<String, Map<String, dynamic>> readStash(SharedPreferences prefs) {
  final raw = prefs.getString(otherCoursesKey);
  if (raw == null) return {};
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final e in map.entries) e.key: Map<String, dynamic>.from(e.value as Map),
    };
  } catch (_) {
    return {};
  }
}

void writeStash(SharedPreferences prefs, Map<String, Map<String, dynamic>> stash) {
  if (stash.isEmpty) {
    prefs.remove(otherCoursesKey);
  } else {
    prefs.setString(otherCoursesKey, jsonEncode(stash));
  }
}

/// The id of the language being learned now ('it', 'de').
final activeCourseProvider =
    NotifierProvider<ActiveCourse, String>(ActiveCourse.new);

class ActiveCourse extends Notifier<String> {
  @override
  String build() {
    final saved = ref.read(prefsProvider).getString(activeCourseKey);
    return saved != null && isKnownLanguage(saved) ? saved : defaultLanguageId;
  }

  /// Remembers the choice. Use [AppController.switchCourse] to change it, so
  /// progress is swapped at the same time.
  void set(String id) {
    ref.read(prefsProvider).setString(activeCourseKey, id);
    state = id;
  }
}

/// The course content for the active language.
final courseProvider = Provider<Course>(
  (ref) => Course.of(ref.watch(activeCourseProvider)),
);
