import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/reward.dart';
import 'package:level_up_your_faith/models/user_model.dart';
import 'package:level_up_your_faith/services/user_service.dart';
import 'package:level_up_your_faith/services/titles_service.dart';
import 'package:level_up_your_faith/services/inventory_service.dart';
import 'package:level_up_your_faith/models/inventory_item.dart';

/// Centralized reward applier used by quests, achievements, and streak milestones.
class RewardService {
  final UserService _userService;
  final TitlesService _titlesService;
  final InventoryService _inventoryService;

  RewardService(
    this._userService,
    this._titlesService,
    this._inventoryService,
  );

  /// Apply the reward to the given profile. Returns the updated UserModel.
  /// For XP rewards, you may pass an optional xpOverride to inject streak bonuses.
  Future<UserModel> applyReward(Reward reward, {int? xpOverride}) async {
    try {
      final profile = await _userService.getCurrentUser();

      switch (reward.type) {
        case RewardTypes.xp:
          final amt = xpOverride ?? (reward.amount ?? 0);
          if (amt > 0) {
            final updated = await _userService.addXP(amt);
            await _userService.updateUser(updated.copyWith());
            await _saveLastRewardSummary(reward.label);
            return updated;
          }
          await _saveLastRewardSummary(reward.label);
          return profile;

        case RewardTypes.streak:
          final inc = reward.amount ?? 0;
          final updated = await _userService.addStreakTokens(inc);
          await _saveLastRewardSummary(reward.label);
          return updated;

        case RewardTypes.token:
          final inc = reward.amount ?? 0;
          final updated = await _userService.addCurrency(inc);
          await _saveLastRewardSummary(reward.label);
          return updated;

        case RewardTypes.title:
          if ((reward.id ?? '').isNotEmpty) {
            await _titlesService.unlockTitle(reward.id!);
          }
          await _saveLastRewardSummary(reward.label);
          return profile;

        case RewardTypes.item:
        case RewardTypes.gear:
        case RewardTypes.cosmetic:
          if ((reward.id ?? '').isNotEmpty) {
            final uid = profile.id;
            final meta = reward.meta ?? const <String, dynamic>{};
            final item = InventoryItem(
              id: reward.id!,
              type: reward.type,
              name: reward.label.isNotEmpty ? reward.label : (reward.id!.replaceAll('_', ' ')),
              description: reward.description ?? '',
              rarity: reward.rarity.isNotEmpty ? reward.rarity : 'common',
              iconKey: meta['iconKey']?.toString(),
              meta: meta,
            );
            final autoEquip = meta['autoEquip'] == true;
            await _inventoryService.addItemToInventory(uid, reward.id!, item, autoEquip: autoEquip);
          }
          await _saveLastRewardSummary(reward.label);
          return profile;

        default:
          debugPrint('Unknown reward type: ${reward.type}');
          await _saveLastRewardSummary(reward.label);
          return profile;
      }
    } catch (e) {
      debugPrint('RewardService.applyReward error: $e');
      return await _userService.getCurrentUser();
    }
  }

  static String formatRewardLabel(Reward reward) {
    switch (reward.type) {
      case RewardTypes.xp:
        return reward.amount != null && reward.amount! > 0
            ? '${reward.amount} XP'
            : (reward.label.isNotEmpty ? reward.label : 'XP');
      case RewardTypes.title:
        return 'Title${reward.id != null ? ': ${reward.id}' : ''}';
      case RewardTypes.streak:
        return reward.amount != null ? '+${reward.amount} Streak Tokens' : 'Streak';
      case RewardTypes.token:
        return reward.amount != null ? '+${reward.amount} Tokens' : 'Token';
      case RewardTypes.item:
      case RewardTypes.gear:
      case RewardTypes.cosmetic:
        final rarity = reward.rarity.isNotEmpty ? '${_capitalize(reward.rarity)} ' : '';
        return '$rarity${_capitalize(rerewardLabel(reward))}';
      default:
        return reward.label.isNotEmpty ? reward.label : 'Reward';
    }
  }

  static String rerewardLabel(Reward r) {
    if ((r.label).trim().isNotEmpty) return r.label.trim();
    if ((r.id ?? '').isNotEmpty) return r.id!.replaceAll('_', ' ');
    return 'Item';
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  // Persist small UI summary for last reward
  Future<void> _saveLastRewardSummary(String label) async {
    try {
      final u = await _userService.getCurrentUser();
      final withSummary = u.copyWith(lastRewardSummary: label);
      await _userService.updateUser(withSummary);
    } catch (e) {
      debugPrint('saveLastRewardSummary error: $e');
    }
  }
}
