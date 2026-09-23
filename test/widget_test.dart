// This file is generated fresh by `flutter create` whenever it doesn't
// already exist in the project (which is what happened here — running
// `flutter create` to scaffold the android/ platform folder, per the
// README's first-time-setup step, also drops in this default counter-app
// template for any "missing" standard file, including this one).
//
// The stock template references a `MyApp` class and asserts on counter-app
// widgets (a "0"/"1" counter, a "+" icon) — none of which exist anywhere in
// this project. This app's actual root widget is `PhotographicMemoryApp`,
// defined in lib/app.dart, so both the referenced class and the entire
// test body needed replacing, not just the class name.
//
// The app's startup sequence (`_StartupGate` in lib/app.dart) reads local
// settings via `path_provider` before deciding whether to show onboarding
// or the dashboard. Widget tests run without real platform channels, so
// `path_provider` is given a fake backed by a real temporary directory —
// everything downstream of that (plain JSON file reads via dart:io, in
// JsonStore) then runs exactly as it does on a real device, just against
// an empty, disposable directory that's fresh for every test.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:photographic_memory/app.dart';

/// A minimal fake for the path_provider platform interface. Extending
/// (rather than implementing) `PathProviderPlatform` routes through its
/// real constructor, which registers the correct verification token — so
/// no `MockPlatformInterfaceMixin` is needed here.
class _FakePathProviderPlatform extends PathProviderPlatform {
  /// Created once when the fake is instantiated (in `setUp`, so once per
  /// test) and reused for every call — mirrors how a real device always
  /// returns the same app-documents path, so all of this app's JsonStore
  /// instances (sessions.json, settings.json, backup.json) resolve to the
  /// same directory instead of each landing in a separate temp folder.
  final String _documentsPath = Directory.systemTemp.createTempSync('photographic_memory_test_').path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _documentsPath;
}

void main() {
  setUp(() {
    PathProviderPlatform.instance = _FakePathProviderPlatform();
  });

  testWidgets('App boots and lands on the first-run onboarding screen', (tester) async {
    await tester.pumpWidget(const PhotographicMemoryApp());
    await tester.pumpAndSettle();

    // A fresh install (empty local storage, via the temp-directory fake
    // above) has not seen onboarding yet, so the app should land on the
    // welcome/baseline screen rather than the dashboard.
    expect(find.text('Welcome to Photographic Memory'), findsOneWidget);
    expect(find.text('Begin Baseline'), findsOneWidget);
  });
}
