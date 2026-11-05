import 'package:flutter/material.dart';
import '../models/project.dart';

abstract class EditorControllerBase extends ChangeNotifier {
  Project get project;
  set project(Project value);

  int get playheadMs;
  set playheadMs(int value);

  bool get isPlaying;
  set isPlaying(bool value);

  String? get selectedClipId;
  set selectedClipId(String? value);

  double get timelineScale;
  set timelineScale(double value);

  bool get isEyedropperActive;
  set isEyedropperActive(bool value);

  int? get eyedropperColor;
  set eyedropperColor(int? value);

  void pushUndo();
  void autoSave();
  void clampPlayhead();
  void syncAudio();
}
