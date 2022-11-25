

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:wechat_kit/wechat_kit.dart';

import 'http.dart';

class WechatUtil {


  static registerAppWechat(String appid, String universalLink) async {
    await Wechat.instance.registerApp(
      appId: appid,
      universalLink: universalLink,
    );
  }

  static checkEnvSupport() async {
    final installedApp = await Wechat.instance.isInstalled();
    if (!installedApp) return Future.error('微信未安装');
    final supportApi = await Wechat.instance.isSupportApi();
    if (!supportApi) return Future.error('微信不支持此功能');
  }

  static Future<Uint8List> getImgByteData(imgUrl) async {
    Response response = await getHttpInstance().get(imgUrl);
    Uint8List imgData = response.data;
    return imgData;
  }

  // scene 0 1 2 聊天界面 朋友圈 收藏
  static shareMiniapp({
    required int scene,
    required String title,
    required String description,
    required String imgUrl,
    required String webpageUrl,
    required String path,
    required String miniappId,
  }) async {
    await checkEnvSupport();

    Uint8List imgData = await getImgByteData(imgUrl);
    
    Wechat.instance.shareMiniProgram(
      scene: scene,
      webpageUrl: webpageUrl,
      userName: miniappId,
      title: title,
      description: description,
      path: path,
      thumbData: imgData,
    );
  }

  static shareWebpage({
    required int scene,
    required String webpageUrl,
    required String title,
    required String description,
    required String imgUrl,
  }) async {
    await checkEnvSupport();

    Uint8List imgData = await getImgByteData(imgUrl);

    Wechat.instance.shareWebpage(
      scene: scene,
      webpageUrl: webpageUrl,
      title: title,
      description: description,
      thumbData: imgData,
    );
  }
}