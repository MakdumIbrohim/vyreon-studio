enum AudioEqPreset {
  normal('Normal / Flat', 'Original sound profile', [0, 0, 0, 0, 0]),
  bassBooster('Bass Booster', 'Boost low frequencies for punchy beat', [6, 4, 1, 0, 0]),
  bassReducer('Bass Reducer', 'Cut boominess & sub-bass rumble', [-6, -4, -1, 0, 0]),
  trebleBooster('Treble Booster', 'Crisp high frequencies & clarity', [0, 0, 1, 4, 6]),
  trebleReducer('Treble Reducer', 'Tame harsh sibilance & high hiss', [0, 0, -1, -4, -6]),
  vocalBooster('Vocal Booster', 'Enhance speech clarity & dialogue', [-2, 0, 4, 3, 1]),
  amRadio('AM Radio', 'Vintage bandpass filter sound', [-10, -8, 6, 2, -8]),
  rock('Rock & Metal', 'Aggressive V-curve punch', [5, 2, -1, 3, 5]),
  pop('Pop Stage', 'Elevated midrange & vocal presence', [1, 2, 4, 2, 0]),
  hipHop('Hip-Hop', 'Heavy sub-bass & accentuated highs', [5, 3, -1, 2, 4]);

  final String label;
  final String description;
  final List<int> bandGains; // 5-band: 100Hz, 300Hz, 1kHz, 3kHz, 10kHz

  const AudioEqPreset(this.label, this.description, this.bandGains);
}

enum VoiceChangerPreset {
  none('Original Voice', 0, 1.0, 'No vocal pitch modification'),
  chipmunk('Chipmunk', 6, 1.4, 'High pitch cartoon character voice'),
  deep('Deep Monster', -5, 0.75, 'Deep pitched villainous voice'),
  robot('Robot Synth', 2, 1.0, 'Metallic robotic modulation'),
  alien('Alien Space', 4, 1.2, 'Extraterrestrial altered vocal tone'),
  radio('Walkie-Talkie', 0, 1.0, 'Band-limited radio comms transmission'),
  kid('Playful Kid', 4, 1.25, 'Youthful cheerful vocal pitch');

  final String label;
  final int pitchSemitones; // -12 to +12
  final double playbackRate; // 0.5x to 2.0x
  final String description;

  const VoiceChangerPreset(
    this.label,
    this.pitchSemitones,
    this.playbackRate,
    this.description,
  );
}
