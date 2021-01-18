import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';

class NowPlayingFile{
  File music, image;
  static String title;
  static Duration position;
  static Duration musicLength;
  static AudioPlayer player;
  static AudioCache cache;
  static bool isPlaying=false;
  static Uint8List listaBitow;
}