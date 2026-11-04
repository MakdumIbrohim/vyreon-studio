class SpeedPoint {
  final double position; // 0.0 to 1.0 relative across the clip
  final double speed; // 0.2x to 4.0x multiplier

  const SpeedPoint({required this.position, required this.speed});

  Map<String, dynamic> toJson() => {
        'position': position,
        'speed': speed,
      };

  factory SpeedPoint.fromJson(Map<String, dynamic> json) {
    return SpeedPoint(
      position: (json['position'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
    );
  }
}

enum SpeedRampPreset {
  constant('Constant'),
  heroMoment('Hero Moment'),
  bulletTime('Bullet Time'),
  montage('Montage Flow'),
  custom('Custom Curve');

  final String label;
  const SpeedRampPreset(this.label);

  static List<SpeedPoint> getPoints(SpeedRampPreset preset) {
    switch (preset) {
      case SpeedRampPreset.constant:
        return const [
          SpeedPoint(position: 0.0, speed: 1.0),
          SpeedPoint(position: 1.0, speed: 1.0),
        ];
      case SpeedRampPreset.heroMoment:
        return const [
          SpeedPoint(position: 0.0, speed: 1.0),
          SpeedPoint(position: 0.35, speed: 1.0),
          SpeedPoint(position: 0.5, speed: 0.3),
          SpeedPoint(position: 0.65, speed: 1.0),
          SpeedPoint(position: 1.0, speed: 1.0),
        ];
      case SpeedRampPreset.bulletTime:
        return const [
          SpeedPoint(position: 0.0, speed: 1.5),
          SpeedPoint(position: 0.3, speed: 0.25),
          SpeedPoint(position: 0.7, speed: 0.25),
          SpeedPoint(position: 1.0, speed: 2.0),
        ];
      case SpeedRampPreset.montage:
        return const [
          SpeedPoint(position: 0.0, speed: 2.0),
          SpeedPoint(position: 0.3, speed: 0.5),
          SpeedPoint(position: 0.6, speed: 2.0),
          SpeedPoint(position: 1.0, speed: 0.8),
        ];
      case SpeedRampPreset.custom:
        return const [
          SpeedPoint(position: 0.0, speed: 1.0),
          SpeedPoint(position: 0.5, speed: 0.5),
          SpeedPoint(position: 1.0, speed: 1.5),
        ];
    }
  }
}
