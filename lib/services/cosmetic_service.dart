import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:level_up_your_faith/data/cosmetic_seeds.dart';
import 'package:level_up_your_faith/models/cosmetic_item.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/theme/app_theme.dart';

/// CosmeticService v1.0 (Architecture only)
/// - Purchases are disabled
/// - Preview is ephemeral and resets when leaving the preview screen or on restart
class CosmeticService extends ChangeNotifier {
  final AppProvider app;
  CosmeticService({required this.app});

  // Monetization switch: always disabled in this build.
  bool get purchaseDisabled => true;

  // Ephemeral runtime-only preview state
  ThemeData? _previewTheme; // overrides MaterialApp.theme if set
  String? _previewGlowId; // e.g., 'glow_starlight'
  String? _previewFrameId; // e.g., 'frame_golden'

  ThemeData? get previewTheme => _previewTheme;
  String? get previewGlowId => _previewGlowId;
  String? get previewFrameId => _previewFrameId;

  // Data source (local seeds for now)
  final List<CosmeticItem> _all = CosmeticSeedsV1.list();

  List<CosmeticItem> getAllCosmetics() => List.unmodifiable(_all);
  List<CosmeticItem> getOwnedCosmetics() => _all.where((c) => c.owned).toList(growable: false);

  // Preview a cosmetic item (ephemeral)
  void previewCosmetic(CosmeticItem item) {
    try {
      switch (item.type) {
        case CosmeticType.theme:
          _previewTheme = _themeForItem(item);
          break;
        case CosmeticType.avatar_glow:
          _previewGlowId = item.id;
          break;
        case CosmeticType.frame:
          _previewFrameId = item.id;
          break;
        case CosmeticType.artifact_skin:
          // Not yet implemented; preview could show on artifact detail in future
          break;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('CosmeticService.previewCosmetic error: $e');
    }
  }

  /// Clear all preview state
  void resetPreview() {
    _previewTheme = null;
    _previewGlowId = null;
    _previewFrameId = null;
    notifyListeners();
  }

  /// Apply cosmetic if already owned. In v1.0 we keep it local-only (no persistence changes).
  /// Returns true if applied locally, false otherwise.
  bool applyCosmetic(CosmeticItem item) {
    try {
      if (!item.owned) return false;
      switch (item.type) {
        case CosmeticType.theme:
          // Map to theme mode and set via AppProvider (this does persist theme choice for user)
          final mode = _themeModeForItem(item);
          app.setThemeMode(mode);
          return true;
        case CosmeticType.avatar_glow:
          // Local-only: mark aura in equipped cosmetics map (no persistence in v1.0)
          app.setCosmeticAuraLocal(item.id);
          return true;
        case CosmeticType.frame:
          app.setCosmeticFrameLocal(item.id);
          return true;
        case CosmeticType.artifact_skin:
          // No-op for now
          return false;
      }
    } catch (e) {
      debugPrint('CosmeticService.applyCosmetic error: $e');
    }
    return false;
  }

  /// Purchases disabled: always returns a disabled result.
  CosmeticPurchaseResult purchaseCosmetic(CosmeticItem item) {
    return const CosmeticPurchaseResult.disabled();
  }

  // ---- Helpers ----

  ThemeData? _themeForItem(CosmeticItem item) {
    switch (item.id) {
      case 'theme_dawn':
        return oliveDawnTheme;
      case 'theme_bedtime':
        return bedtimeCalmTheme;
      case 'theme_ocean':
        return oceanDeepTheme;
      default:
        return null;
    }
  }

  AppThemeMode _themeModeForItem(CosmeticItem item) {
    switch (item.id) {
      case 'theme_dawn':
        return AppThemeMode.oliveDawn;
      case 'theme_bedtime':
        return AppThemeMode.bedtimeCalm;
      case 'theme_ocean':
        return AppThemeMode.oceanDeep;
      default:
        return AppThemeMode.sacredDark;
    }
  }
}

class CosmeticPurchaseResult {
  final bool success;
  final String code; // 'disabled'
  final String message;

  const CosmeticPurchaseResult._(this.success, this.code, this.message);
  const CosmeticPurchaseResult.disabled() : this._(false, 'disabled', 'Purchases are disabled in this build.');
}
