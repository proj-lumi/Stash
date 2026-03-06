import 'package:shared_preferences/shared_preferences.dart';

const _keyFontSize = 'fontSize';
const _keyColorMode = 'colorMode';

enum ColorMode { light, dark }

class AppSettings {
  const AppSettings({
    this.fontSize = 16.0,
    this.colorMode = ColorMode.light,
  });

  final double fontSize;
  final ColorMode colorMode;

  AppSettings copyWith({double? fontSize, ColorMode? colorMode}) {
    return AppSettings(
      fontSize: fontSize ?? this.fontSize,
      colorMode: colorMode ?? this.colorMode,
    );
  }
}

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  // adjust defaults to avoid overly large text that spills off small screens
  static const double defaultFontSize = 16.0;
  static const double minFontSize = 14.0;
  static const double maxFontSize = 18.0;

  AppSettings load() {
    final fontSize = _prefs.getDouble(_keyFontSize) ?? defaultFontSize;
    final modeIndex = _prefs.getInt(_keyColorMode);
    final colorMode = modeIndex == 1 ? ColorMode.dark : ColorMode.light;
    return AppSettings(fontSize: fontSize, colorMode: colorMode);
  }

  Future<void> saveFontSize(double value) async {
    await _prefs.setDouble(_keyFontSize, value.clamp(minFontSize, maxFontSize));
  }

  Future<void> saveColorMode(ColorMode value) async {
    await _prefs.setInt(_keyColorMode, value == ColorMode.dark ? 1 : 0);
  }

  /// Clear data does NOT clear settings; this is only for explicit reset if needed.
  Future<void> clear() async {
    await _prefs.remove(_keyFontSize);
    await _prefs.remove(_keyColorMode);
  }
}
