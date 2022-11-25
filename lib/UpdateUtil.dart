import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_xupdate/flutter_xupdate.dart';

checkUpdate(int codeVersion, String configUrl) {
  debugPrint('FlutterXUpdate');
  ///初始化
  if (Platform.isAndroid) {
    debugPrint('FlutterXUpdate');
    FlutterXUpdate.init(
      ///是否输出日志
      debug: true,
      ///是否使用post请求
      isPost: false,
      ///post请求是否是上传json
      isPostJson: false,
      ///请求响应超时时间
      timeout: 25000,
      ///是否开启自动模式
      isWifiOnly: false,
      ///是否开启自动模式
      isAutoMode: false,
      ///需要设置的公共参数
      supportSilentInstall: false,
      ///在下载过程中，如果点击了取消的话，是否弹出切换下载方式的重试提示弹窗
      enableRetry: false
    ).then((value) {
      debugPrint("初始化成功: $value");
      FlutterXUpdate.checkUpdate(url: configUrl, isCustomParse: true);
    }).catchError((error) {
      debugPrint(error);
    });

    FlutterXUpdate.setCustomParseHandler(onUpdateParse: (String? json) async {
      if (null == json) {
        return UpdateEntity(hasUpdate: false, isIgnorable: false, versionCode: 1, versionName: '1.0.0', updateContent: '', downloadUrl: '');
      }
      var appInfo = jsonDecode(json);
      return UpdateEntity(
        hasUpdate: codeVersion < appInfo['VersionCode'],
        isForce: appInfo['UpdateStatus'] == 2, // 强制更新
        isIgnorable: appInfo['UpdateStatus'] == 3, // 跳过更新
        versionCode: appInfo['VersionCode'],
        versionName: appInfo['VersionName'],
        updateContent: appInfo['ModifyContent'],
        downloadUrl: appInfo['DownloadUrl'],
        apkSize: appInfo['ApkSize']
      );
    });

    FlutterXUpdate.setErrorHandler(onUpdateError: (Map<String, dynamic>? message) async {
          debugPrint(message.toString());
        }
    );
  } else {
    debugPrint("ios暂不支持XUpdate更新");
  }
}