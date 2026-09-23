import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Uses the already-resolved plugin test boundary, not a production dependency.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:level_up_your_faith/models/user_model.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/providers/settings_provider.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:level_up_your_faith/services/user_service.dart';

class HeldPreferences extends InMemorySharedPreferencesStore {
  HeldPreferences(Map<String, Object> data) : super.withData(data);
  final entered = Completer<void>();
  final ready = Completer<void>();
  int loads = 0;
  final writes = <String>[];
  @override
  Future<Map<String, Object>> getAll() async {
    loads++;
    if (!entered.isCompleted) entered.complete();
    await ready.future;
    return super.getAll();
  }
  @override
  Future<bool> setValue(String type, String key, Object value) {
    writes.add(key);
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Deliberately cold isolate: do not preinitialize StorageService in setUp.
  test('concurrent settings and app startup cannot access current_user before preferences are ready', () async {
    SharedPreferences.setMockInitialValues({});
    final date=DateTime.now();
    final saved=UserModel(id:'existing-user',username:'Existing',email:'',
      currentLevel:3,currentXP:17,totalXP:317,rewardReceipts:['kept-receipt'],
      createdAt:date,updatedAt:date);
    final store=HeldPreferences({'flutter.current_user':jsonEncode(saved.toJson()),
      'flutter.private-history-sentinel':'keep this history'});
    SharedPreferencesStorePlatform.instance=store;
    final settings=SettingsProvider();
    final app=AppProvider();
    final errors=<Object>[];
    final settingsStart=settings.initialize().catchError((Object e){errors.add(e);});
    await store.entered.future;
    bool consumerReachedUser=false;
    final consumer=StorageService.getInstance().then((storage) async {
      consumerReachedUser=true;
      return (await UserService(storage).getCurrentUser()).id;
    }).catchError((Object e){errors.add(e);return 'failed';});
    final appStart=app.initialize().catchError((Object e){errors.add(e);});
    // Flush async continuations while the platform load remains explicitly held.
    await Future<void>.delayed(Duration.zero);
    final reachedBeforeReady=consumerReachedUser;
    final writesBeforeReady=[...store.writes];
    store.ready.complete();
    await Future.wait([settingsStart,appStart]);
    final id=await consumer;
    try {
      expect(reachedBeforeReady,isFalse,reason:'No service may obtain unfinished storage, including a current_user reader.');
      expect(writesBeforeReady,isEmpty);
      expect(errors,isEmpty);
      expect(id,saved.id);
      expect(app.isInitialized,isTrue);
      expect(app.isLoading,isFalse);
      expect(settings.isLoaded,isTrue);
      expect(app.currentUser!.id,saved.id);
      expect(app.currentUser!.totalXP,saved.totalXP);
      expect(app.currentUser!.rewardReceipts,contains('kept-receipt'));
      final storage=await StorageService.getInstance();
      expect(storage.getString('private-history-sentinel'),'keep this history');
      expect(identical(storage,await StorageService.getInstance()),isTrue);
      expect(store.loads,1);
    } finally {app.dispose();settings.dispose();}
  });
}
