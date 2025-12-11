import 'package:flutter/foundation.dart';

@immutable
class SpiritualStats {
  final int wisdom;
  final int discipline;
  final int compassion;
  final int witness;

  const SpiritualStats({
    this.wisdom = 0,
    this.discipline = 0,
    this.compassion = 0,
    this.witness = 0,
  });

  const SpiritualStats.zero()
      : wisdom = 0,
        discipline = 0,
        compassion = 0,
        witness = 0;

  SpiritualStats operator +(SpiritualStats other) {
    return SpiritualStats(
      wisdom: wisdom + other.wisdom,
      discipline: discipline + other.discipline,
      compassion: compassion + other.compassion,
      witness: witness + other.witness,
    );
  }

  bool get isZero =>
      wisdom == 0 && discipline == 0 && compassion == 0 && witness == 0;
}
