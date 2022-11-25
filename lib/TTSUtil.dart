

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'LocalStore.dart';

class TTSUtil {
  static late FlutterTts flutterTts;

  static bool ttsPluginInited = false;

  static String ttsState = 'stopped';

  static initTts() async {
    if (ttsPluginInited) return;
    flutterTts = FlutterTts();

    await flutterTts.awaitSpeakCompletion(true);

    if (Platform.isAndroid) {
      var engine = await flutterTts.getDefaultEngine;
      if (engine != null) {
        debugPrint(engine.toString());
      }
    }

    flutterTts.setStartHandler(() {
      ttsState = 'playing';
    });

    flutterTts.setCompletionHandler(() {
      ttsState = 'stopped';
    });

    flutterTts.setCancelHandler(() {
      ttsState = 'stopped';
    });

    if (kIsWeb || Platform.isIOS || Platform.isWindows) {
      flutterTts.setPauseHandler(() {
        ttsState = 'paused';
      });

      flutterTts.setContinueHandler(() {
        ttsState = 'continued';
      });
    }

    flutterTts.setErrorHandler((msg) {
      ttsState = 'stopped';
    });

    ttsPluginInited = true;
  }


  static speakText(String voiceText) async {
    if (voiceText.isEmpty) throw Exception('文字内容不能为空');
    await initTts();
    // if (Platform.isAndroid) {
    //   final isInstalled = await flutterTts.isLanguageAvailable('zh-CN');
    //   if (!isInstalled) return Future.error('您的手机暂不支持语音播放');
    // }
    double ttsSpeechRate = await LocalStore.getItemToDouble('TTSSpeechRate', 1);
    await flutterTts.setLanguage('zh-CN');
    await flutterTts.setVolume(1);
    await flutterTts.setSpeechRate(ttsSpeechRate);
    await flutterTts.setPitch(1);
    await flutterTts.speak(voiceText);
  }

}