enum InAnimationType {
  none('None'),
  fadeIn('Fade In'),
  pop('Pop'),
  slideRight('Slide Right'),
  slideLeft('Slide Left'),
  slideUp('Slide Up'),
  slideDown('Slide Down'),
  drop('Drop'),
  scaleUp('Scale Up');

  final String label;
  const InAnimationType(this.label);
}

enum OverallAnimationType {
  none('None'),
  blinkSlow('Blink Slow'),
  pulse('Pulse'),
  jitter('Jitter'),
  floating('Floating'),
  drifting('Drifting'),
  squishing('Squishing'),
  clockwiseSpin('Spin CW'),
  counterClockwiseSpin('Spin CCW');

  final String label;
  const OverallAnimationType(this.label);
}

enum OutAnimationType {
  none('None'),
  fadeOut('Fade Out'),
  popDown('Pop Down'),
  slideRight('Slide Right'),
  slideLeft('Slide Left'),
  slideUp('Slide Up'),
  slideDown('Slide Down'),
  scaleDown('Scale Down');

  final String label;
  const OutAnimationType(this.label);
}
