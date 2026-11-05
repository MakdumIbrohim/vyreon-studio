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

enum AudioReverbPreset {
  none('None', 'Dry natural sound', null),
  studio('Studio', 'Tightly controlled room reflections', 'aecho=0.8:0.88:40:0.4'),
  room('Room', 'Small room intimate reverberation', 'aecho=0.8:0.88:60:0.3'),
  concertHall('Concert Hall', 'Expansive musical hall space', 'aecho=0.8:0.9:1000|1800:0.3|0.2'),
  cave('Cave', 'Deep subterranean acoustic bounce', 'aecho=0.8:0.7:500|1000:0.4|0.3'),
  cathedral('Cathedral', 'Majestic vaulted ceiling resonance', 'aecho=0.8:0.9:800|1600|2400:0.3|0.2|0.1'),
  springReverb('Spring', 'Vintage analog guitar spring bounce', 'aecho=0.8:0.6:20|40:0.6|0.3');

  final String label;
  final String description;
  final String? ffmpegFilter;

  const AudioReverbPreset(this.label, this.description, this.ffmpegFilter);
}

enum AudioDenoisePreset {
  none('Off', 'No noise suppression', null),
  mild('Mild Denoise', 'Subtle background hiss reduction', 'afftdn=nr=10:nf=-25'),
  voiceClarity('Voice Clarity', 'Eliminates room hum & mic rumble', 'highpass=f=80,afftdn=nr=18:nf=-30'),
  aggressive('Aggressive', 'Heavy noise suppression for outdoor/windy audio', 'highpass=f=100,lowpass=f=12000,afftdn=nr=28:nf=-35');

  final String label;
  final String description;
  final String? ffmpegFilter;

  const AudioDenoisePreset(this.label, this.description, this.ffmpegFilter);
}

enum AudioEnhancePreset {
  none('Off', 'Natural unprocessed audio', null),
  warmVocal('Warm Vocal', 'Boost vocal presence & dialogue intelligibility', 'highpass=f=85,equalizer=f=3000:width_type=h:width=1500:g=3.5,compand=.03|.05:1:-60/-60|-24/-12|0/-3:6:0:-90:0.1'),
  studioBroadcast('Studio Broadcast', 'Radio host punch, compression & presence', 'compand=.01|.02:1:-60/-60|-30/-10|0/-1:4:0:-90:0.05,equalizer=f=120:width_type=h:width=80:g=2.5,equalizer=f=4500:width_type=h:width=2000:g=3'),
  smartLeveler('Smart Leveler', 'Even out loud & quiet speaking parts', 'speechnorm=e=4:r=0.0001:l=1');

  final String label;
  final String description;
  final String? ffmpegFilter;

  const AudioEnhancePreset(this.label, this.description, this.ffmpegFilter);
}
