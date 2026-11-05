import '../models/project.dart';
import '../models/timeline_clip.dart';
import 'editor_controller_base.dart';
import 'mixins/editor_clip_ops_mixin.dart';
import 'mixins/editor_history_mixin.dart';
import 'mixins/editor_layer_ops_mixin.dart';
import 'mixins/editor_playback_mixin.dart';

class EditorController extends EditorControllerBase
    with
        EditorHistoryMixin,
        EditorPlaybackMixin,
        EditorClipOpsMixin,
        EditorLayerOpsMixin {
  Project _project;
  int _playheadMs = 0;
  bool _isPlaying = false;
  String? _selectedClipId;
  double _timelineScale = 60.0;

  EditorController(this._project);

  @override
  Project get project => _project;

  @override
  set project(Project value) {
    _project = value;
  }

  @override
  int get playheadMs => _playheadMs;

  @override
  set playheadMs(int value) {
    _playheadMs = value;
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  set isPlaying(bool value) {
    _isPlaying = value;
  }

  @override
  String? get selectedClipId => _selectedClipId;

  @override
  set selectedClipId(String? value) {
    _selectedClipId = value;
  }

  @override
  double get timelineScale => _timelineScale;

  @override
  set timelineScale(double value) {
    _timelineScale = value;
  }

  TimelineClip? get selectedClip {
    if (_selectedClipId == null) return null;
    for (final c in _project.clips) {
      if (c.id == _selectedClipId) return c;
    }
    return null;
  }

  void selectClip(String? id) {
    if (_selectedClipId != id) {
      _selectedClipId = id;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disposePlayback();
    super.dispose();
  }
}
