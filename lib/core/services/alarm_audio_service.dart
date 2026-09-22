import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmSoundOption {
  final String id;
  final String assetFileName;
  final String rawResName;
  final IconData icon;

  const AlarmSoundOption({
    required this.id,
    required this.assetFileName,
    required this.rawResName,
    required this.icon,
  });
}

class AlarmAudioService {
  AlarmAudioService._();
  static final AlarmAudioService instance = AlarmAudioService._();

  static const String prefSelectedSoundKey = 'selected_alarm_sound';
  static const String defaultSoundId = 'gentle_chime';

  static const List<AlarmSoundOption> availableSounds = [
    AlarmSoundOption(
      id: 'gentle_chime',
      assetFileName: 'gentle_chime.wav',
      rawResName: 'gentle_chime',
      icon: Icons.notifications_active_rounded,
    ),
    AlarmSoundOption(
      id: 'morning_marimba',
      assetFileName: 'morning_marimba.wav',
      rawResName: 'morning_marimba',
      icon: Icons.music_note_rounded,
    ),
    AlarmSoundOption(
      id: 'peaceful_bell',
      assetFileName: 'peaceful_bell.wav',
      rawResName: 'peaceful_bell',
      icon: Icons.wb_sunny_rounded,
    ),
    AlarmSoundOption(
      id: 'digital_alarm',
      assetFileName: 'digital_alarm.wav',
      rawResName: 'digital_alarm',
      icon: Icons.alarm_rounded,
    ),
    AlarmSoundOption(
      id: 'radar_pulse',
      assetFileName: 'radar_pulse.wav',
      rawResName: 'radar_pulse',
      icon: Icons.radar_rounded,
    ),
  ];

  AudioPlayer? _alarmPlayer;
  AudioPlayer? _previewPlayer;
  bool _isAlarmRinging = false;
  String? _currentlyPreviewingId;

  bool get isAlarmRinging => _isAlarmRinging;
  String? get currentlyPreviewingId => _currentlyPreviewingId;

  static AlarmSoundOption getSoundOption(String id) {
    return availableSounds.firstWhere(
      (s) => s.id == id,
      orElse: () => availableSounds.first,
    );
  }

  Future<String> getSelectedSoundId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefSelectedSoundKey) ?? defaultSoundId;
  }

  Future<void> setSelectedSoundId(String soundId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefSelectedSoundKey, soundId);
  }

  Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('reminder_sound_enabled') ?? true;
  }

  /// Starts looping the selected alarm sound continuously until stopped
  Future<void> startAlarm({String? soundId}) async {
    try {
      final soundEnabled = await isSoundEnabled();
      if (!soundEnabled) {
        debugPrint('AlarmAudioService: Sound is disabled in settings. Skipping playback.');
        return;
      }

      await stopAlarm();
      await stopPreview();

      final activeSoundId = soundId ?? await getSelectedSoundId();
      final option = getSoundOption(activeSoundId);

      _alarmPlayer = AudioPlayer();
      await _alarmPlayer!.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientExclusive,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ),
      );

      await _alarmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _alarmPlayer!.setVolume(1.0);
      await _alarmPlayer!.play(AssetSource('sounds/${option.assetFileName}'));
      _isAlarmRinging = true;
      debugPrint('AlarmAudioService: Alarm started looping with tone ${option.id}');
    } catch (e) {
      debugPrint('AlarmAudioService: Failed to play alarm sound: $e');
    }
  }

  /// Stops and releases the active ringing alarm
  Future<void> stopAlarm() async {
    try {
      if (_alarmPlayer != null) {
        await _alarmPlayer!.stop();
        await _alarmPlayer!.dispose();
        _alarmPlayer = null;
      }
      _isAlarmRinging = false;
      debugPrint('AlarmAudioService: Alarm stopped.');
    } catch (e) {
      debugPrint('AlarmAudioService: Error stopping alarm: $e');
    }
  }

  /// Plays a short preview for Settings sound picker
  Future<void> playPreview(String soundId, {VoidCallback? onComplete}) async {
    try {
      await stopPreview();
      final option = getSoundOption(soundId);

      _previewPlayer = AudioPlayer();
      _currentlyPreviewingId = soundId;

      _previewPlayer!.onPlayerComplete.listen((_) {
        _currentlyPreviewingId = null;
        if (onComplete != null) onComplete();
      });

      await _previewPlayer!.setVolume(1.0);
      await _previewPlayer!.setReleaseMode(ReleaseMode.release);
      await _previewPlayer!.play(AssetSource('sounds/${option.assetFileName}'));
    } catch (e) {
      debugPrint('AlarmAudioService: Error playing preview: $e');
      _currentlyPreviewingId = null;
    }
  }

  /// Stops any active sound preview
  Future<void> stopPreview() async {
    try {
      if (_previewPlayer != null) {
        await _previewPlayer!.stop();
        await _previewPlayer!.dispose();
        _previewPlayer = null;
      }
      _currentlyPreviewingId = null;
    } catch (e) {
      debugPrint('AlarmAudioService: Error stopping preview: $e');
    }
  }
}
