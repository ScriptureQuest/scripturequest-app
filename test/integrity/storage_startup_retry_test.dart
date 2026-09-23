import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:level_up_your_faith/services/storage_service.dart';

class FailingOncePreferences extends InMemorySharedPreferencesStore {
  FailingOncePreferences() : super.withData({'flutter.current_user':'preserved bytes'});
  final release=Completer<void>();
  int attempts=0;
  @override Future<Map<String,Object>> getAll() async {
    attempts++;
    if(attempts==1) {await release.future;throw StateError('platform unavailable');}
    return super.getAll();
  }
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('initialization failure reaches all waiters and a later retry preserves stored bytes',() async {
    SharedPreferences.setMockInitialValues({});
    final platform=FailingOncePreferences();
    SharedPreferencesStorePlatform.instance=platform;
    final first=StorageService.getInstance(), second=StorageService.getInstance();
    final checks=Future.wait([
      expectLater(first,throwsStateError),expectLater(second,throwsStateError),
    ]);
    platform.release.complete();
    await checks;
    final restored=await StorageService.getInstance();
    expect(restored.getString('current_user'),'preserved bytes');
    expect(platform.attempts,2);
    expect(identical(restored,await StorageService.getInstance()),isTrue);
    expect(platform.attempts,2);
  });
}
