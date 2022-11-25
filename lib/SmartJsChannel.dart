import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_utils/BlueToothPrint.dart';
import 'package:smart_utils/LocalStore.dart';
import 'package:smart_utils/WechatUtil.dart';
import 'package:smart_utils/events.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock/wakelock.dart';

import 'JPushUtil.dart';
import 'TTSUtil.dart';
import 'ToastManager.dart';
import 'UserLocation.dart';
import 'package:image_picker/image_picker.dart';


fireAppIsInitiativeLeaveEvent() {
  eventBus.fire(InitiativeLeave(true));
}

chooseMedia(Map options, { context }) async {
  fireAppIsInitiativeLeaveEvent();
  final ImagePicker _picker = ImagePicker();
  var type = options['type'] ?? 'image'; // image video
  var source = options['source'] ?? 'photo'; // camera photo

  // if (source == 'multi') {
  //   // Pick multiple images
  //   final List<XFile>? images = await _picker.pickMultiImage();
  // }

  XFile? file;

  if (type == 'image') {
    if (source == 'photo') {
      // Pick an image
      file = await _picker.pickImage(source: ImageSource.gallery);
    } else {
      // Capture a photo
      file = await _picker.pickImage(source: ImageSource.camera);
    }
  } else if (type == 'video') {
    if (source == 'photo') {
      // Pick a video
      file = await _picker.pickVideo(source: ImageSource.gallery);
    } else {
      // Capture a photo
      file = await _picker.pickVideo(source: ImageSource.camera);
    }
  }
  if (null == file) {
    return [];
  }
  String fileName = file.name;
  var fileBates = await file.readAsBytes();
  String fileBase64 = base64Encode(fileBates);
  var nameList = fileName.split('.');
  String base64Image = "data:image/${nameList[nameList.length - 1]};base64,$fileBase64";
  return [base64Image];

}

setStatusBarColor(Color color) {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(statusBarColor: color));
}

getValueAndCheck(Map options, String key, { String? errMsg, defVal }) {
  if (!options.containsKey(key)) {
    if (defVal != null) {
      return defVal;
    } else {
      return Future.error(errMsg ?? '$key 必填');
    }
  }
  return options[key];
}

Map _channelHandlerMap = <String, Function> {
  'Toaster': (Map options, { context }) {
    ToastManager.show(options['msg'] ?? '');
  },
  'CloseApp': (Map options, { context }) {
    exit(0);
  },
  'StartPosition': (Map options, { context }) async {
    int interval = await getValueAndCheck(options, 'interval');
    await UserLocation.getInstance().startLocationListener(interval: interval);
  },
  'StopPosition': (Map options, { context }) {
    UserLocation.getInstance().disposeListener();
  },
  'GetPosition': (Map options, { context }) async {
    return await UserLocation.getInstance().getLocation();
  },
  'ChooseMedia': chooseMedia,
  'SetStatusBarColor': (Map options, { context }) async {
    String color = await getValueAndCheck(options, 'color');
    setStatusBarColor(Color(int.parse('0xff$color')));
  },
  'Wakelock': (Map options, { context }) async {
    bool state = await getValueAndCheck(options, 'state');
    bool enabled = await Wakelock.enabled;
    debugPrint('当前的屏幕锁的状态为 $enabled 更改为 $state');
    if (state == enabled) return;
    Wakelock.toggle(enable: state);
  },
  'WakelockState': (Map options, { context }) async {
    bool enabled = await Wakelock.enabled;
    return enabled;
  },
  'GetVolume': (Map options, { context }) async {
    double volume = await PerfectVolumeControl.getVolume();
    return volume;
  },
  'SetVolume': (Map options, { context }) async {
    double volume = await getValueAndCheck(options, 'volume');
    await PerfectVolumeControl.setVolume(volume);
  },
  'Speak': (Map options, { context }) async {
    String speakText = await getValueAndCheck(options, 'text');
    if (speakText.isEmpty) {
      return Future.error('文字内容为空');
    }
    await TTSUtil.speakText(speakText);
  },
  'WechatShare': (Map options, { context }) async {
    int shareType = await getValueAndCheck(options, 'shareType');
    int scene = await getValueAndCheck(options, 'scene');
    String webpageUrl = await getValueAndCheck(options, 'webpageUrl');
    String title = await getValueAndCheck(options, 'title');
    String description = await getValueAndCheck(options, 'description');
    String imgUrl = await getValueAndCheck(options, 'imgUrl');
    fireAppIsInitiativeLeaveEvent();
    if (shareType == 1) {
      WechatUtil.shareWebpage(scene: scene, webpageUrl: webpageUrl, title: title, description: description, imgUrl: imgUrl);
    } else if (shareType == 2) {
      String path = await getValueAndCheck(options, 'path');
      String miniappId = await getValueAndCheck(options, 'miniappId');
      WechatUtil.shareMiniapp(scene: scene, title: title, description: description, imgUrl: imgUrl, webpageUrl: webpageUrl, path: path, miniappId: miniappId);
    }
  },
  'Scanner': (Map options, { context }) async {
    var data = await Navigator.of(context).pushNamed('/scan');
    if (data != null) {
      return data as Map;
    }
    return data;
  },
  'LaunchJPush': (Map options, { context }) async {
    final String appKey = await getValueAndCheck(options, 'appKey');
    final String channel = await getValueAndCheck(options, 'channel');
    await JPushUtil.initPlatformState(appKey, channel);
  },
  'NotificationEnabled': (Map options, { context }) async {
    return await JPushUtil.notificationEnabled();
  },
  'OpenNotificationSetting': (Map options, { context }) async {
    fireAppIsInitiativeLeaveEvent();
    return await JPushUtil.openNotificationSetting();
  },
  'SetJPushTags': (Map options, { context }) async {
    final String tags = await getValueAndCheck(options, 'tags');
    return await JPushUtil.setTags(tags);
  },
  'GetJPushTags': (Map options, { context }) async {
    return await JPushUtil.getAllTags();
  },
  'StopJPush': (Map options, { context }) async {
    return await JPushUtil.stop();
  },
  'ResumeJPush': (Map options, { context }) async {
    if (!JPushUtil.jPushInitEd) {
      debugPrint('极光没有启动 开启');
      final String appKey = await getValueAndCheck(options, 'appKey');
      final String channel = await getValueAndCheck(options, 'channel');
      await JPushUtil.initPlatformState(appKey, channel);
    } else {
      debugPrint('重启极光');
      return await JPushUtil.resume();
    }
  },
  'JPushSetBadge': (Map options, { context }) async {
    final int badge = await getValueAndCheck(options, 'badge');
    return await JPushUtil.setBadge(badge);
  },
  'ScanBlue': (Map options, { context }) async {
    return await BlueToothPrint.scan(options['time'] ?? 2);
  },
  'ConnectBlue': (Map options, { context }) async {
    String name = await getValueAndCheck(options, 'name');
    String address = await getValueAndCheck(options, 'address');
    int type = await getValueAndCheck(options, 'type');
    String alias = await getValueAndCheck(options, 'alias');
    return await BlueToothPrint.connect(name, address, type, alias);
  },
  'DisConnectBlue': (Map options, { context }) async {
    String name = await getValueAndCheck(options, 'name');
    String address = await getValueAndCheck(options, 'address');
    int type = await getValueAndCheck(options, 'type');
    String alias = await getValueAndCheck(options, 'alias');
    return await BlueToothPrint.disconnect(name, address, type, alias);
  },
  'ConnectedItem': (Map options, { context }) async {
    String alias = await getValueAndCheck(options, 'alias');
    return await BlueToothPrint.getConnectedDeviceByAlias(alias);
  },
  'PrintTicket': (Map options, { context }) async {
    String url = await getValueAndCheck(options, 'url');
    String alias = await getValueAndCheck(options, 'alias');
    int pageSize = await getValueAndCheck(options, 'pageSize');
    // return await BlueToothPrint.printTest(alias);
    // String testURl = 'https://api.91joylife.net/printer/takeaway?order_id=1562993886843449344';
    // return await BlueToothPrint.print(testURl, alias, pageSize);
    return await BlueToothPrint.print(url, alias, pageSize);
  },
  'TestPrintTicket': (Map options, { context }) async {
    String alias = await getValueAndCheck(options, 'alias');
    // String testURl = 'https://api.91joylife.net/printer/takeaway?order_id=4849015367630061569';
    // String testURl = 'https://saas-api.sandbox.91joylife.net/printer/takeaway?order_id=4849015367630061569';
    // return await BlueToothPrint.print(testURl, alias, 1);
    return await BlueToothPrint.printTest(alias);
  },
  'SetStore': (Map options, { context }) async {
    String key = await getValueAndCheck(options, 'key');
    String value = await getValueAndCheck(options, 'value');
    await LocalStore.setItem(key, value);
  },
  'GetStore': (Map options, { context }) async {
    String key = await getValueAndCheck(options, 'key');
    return await LocalStore.getItem(key);
  },
  'SaveMedia': (Map options, { context }) async {
    String path = await getValueAndCheck(options, 'path');
    String type = await getValueAndCheck(options, 'type');
    var status = await Permission.storage.status;
    if (status != PermissionStatus.granted) {
      await Permission.storage.request();
    }
    List<String> srcList = path.split(',');
    for (String srcItem in srcList) {
      switch (type) {
        case 'image':
          await GallerySaver.saveImage(srcItem);
          break;
        case 'video': await GallerySaver.saveVideo(srcItem); break;
      }
    }

  },
  'LaunchUrl': (Map options, { context }) async {
    String url = await getValueAndCheck(options, 'url');
    return await launchUrl(Uri.parse(url));
  },
  'GetClipboard': (Map options, { context }) async {
    var clipboardData = await Clipboard.getData(Clipboard.kTextPlain);// 获取粘贴板 中的文本
    if (clipboardData != null) {
      return clipboardData.text;
    }
    return '';
  },
  'SetClipboard': (Map options, { context }) async {
    String text = await getValueAndCheck(options, 'text');
    await Clipboard.setData(ClipboardData(text: text));
  },
};


Function? getChannelFun(methodName) {
  if (!_channelHandlerMap.containsKey(methodName)) return null;
  return _channelHandlerMap[methodName];
}

addChannelHandler(methodName, Function handlerFun) {
  _channelHandlerMap[methodName] = handlerFun;
}