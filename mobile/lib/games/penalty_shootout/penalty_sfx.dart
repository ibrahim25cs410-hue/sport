import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// مؤثرات صوتية مولّدة محلياً — بدون ملفات خارجية.
abstract final class PenaltySfx {
  static final AudioPlayer _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  static Future<void> playKick() => _playTone(freq: 180, ms: 90, volume: 0.45);
  static Future<void> playGoal() => _playTone(freq: 520, ms: 220, volume: 0.55, rising: true);
  static Future<void> playSave() => _playTone(freq: 140, ms: 160, volume: 0.5);
  static Future<void> playPost() => _playTone(freq: 260, ms: 110, volume: 0.4);

  static Future<void> _playTone({
    required double freq,
    required int ms,
    required double volume,
    bool rising = false,
  }) async {
    try {
      final bytes = _synthesizeWav(
        frequency: freq,
        durationMs: ms,
        volume: volume,
        rising: rising,
      );
      await _player.play(BytesSource(bytes));
      await HapticFeedback.lightImpact();
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  static Uint8List _synthesizeWav({
    required double frequency,
    required int durationMs,
    required double volume,
    bool rising = false,
  }) {
    const sampleRate = 22050;
    final sampleCount = (sampleRate * durationMs / 1000).round();
    final dataSize = sampleCount * 2;
    final buffer = ByteData(44 + dataSize);

    void writeString(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        buffer.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
    writeString(36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final env = min(1.0, i / (sampleRate * 0.02)) * min(1.0, (sampleCount - i) / (sampleRate * 0.05));
      final f = rising ? frequency * (1 + t * 0.8) : frequency;
      final sample = sin(2 * pi * f * t) * volume * env;
      buffer.setInt16(44 + i * 2, (sample * 32767).round().clamp(-32768, 32767), Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}
