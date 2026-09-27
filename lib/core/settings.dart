import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pets/toon.dart';
import 'pets.dart';

/// Small on-device preferences. Nothing leaves the phone.
class Settings extends ChangeNotifier {
  Settings._(this._p);

  static late Settings instance;
  final SharedPreferences _p;

  static Future<Settings> load() async => instance = Settings._(await SharedPreferences.getInstance());

  bool get introSeen => _p.getBool('introSeen') ?? false;
  set introSeen(bool v) => _set('introSeen', v);

  /// Pets listen and repeat (grown-ups can switch it off).
  bool get micOn => _p.getBool('micOn') ?? true;
  set micOn(bool v) => _set('micOn', v);

  /// 0 = only loud voices, 1 = whispers.
  double get sensitivity => _p.getDouble('sensitivity') ?? 0.6;
  set sensitivity(double v) => _set('sensitivity', v);

  Tone get tone => Tone.values[(_p.getInt('tone') ?? 0).clamp(0, Tone.values.length - 1)];
  set tone(Tone v) => _set('tone', v.index);

  PetKind get pet => PetKind.values[(_p.getInt('pet') ?? 0).clamp(0, PetKind.values.length - 1)];
  set pet(PetKind v) => _set('pet', v.index);

  /// Dress-up hats, unlocked by the gift (rewarded ad).
  bool get dressUpUnlocked => _p.getBool('dressUp') ?? false;
  set dressUpUnlocked(bool v) => _set('dressUp', v);

  Accessory get accessory => Accessory.values[(_p.getInt('accessory') ?? 0).clamp(0, Accessory.values.length - 1)];
  set accessory(Accessory v) => _set('accessory', v.index);

  void _set(String key, Object v) {
    switch (v) {
      case bool b:
        _p.setBool(key, b);
      case int i:
        _p.setInt(key, i);
      case double d:
        _p.setDouble(key, d);
    }
    notifyListeners();
  }
}
