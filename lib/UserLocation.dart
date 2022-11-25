import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'events.dart';

initAMapPlugin(String androidKey, String iosKey) {
  debugPrint('$androidKey $iosKey');
  /// 设置是否已经包含高德隐私政策并弹窗展示显示用户查看，如果未包含或者没有弹窗展示，高德定位SDK将不会工作
  ///
  /// 高德SDK合规使用方案请参考官网地址：https://lbs.amap.com/news/sdkhgsy
  /// <b>必须保证在调用定位功能之前调用， 建议首次启动App时弹出《隐私政策》并取得用户同意</b>
  ///
  /// 高德SDK合规使用方案请参考官网地址：https://lbs.amap.com/news/sdkhgsy
  ///
  /// [hasContains] 隐私声明中是否包含高德隐私政策说明
  ///
  /// [hasShow] 隐私权政策是否弹窗展示告知用户
  AMapFlutterLocation.updatePrivacyShow(true, true);

  /// 设置是否已经取得用户同意，如果未取得用户同意，高德定位SDK将不会工作
  ///
  /// 高德SDK合规使用方案请参考官网地址：https://lbs.amap.com/news/sdkhgsy
  ///
  /// <b>必须保证在调用定位功能之前调用, 建议首次启动App时弹出《隐私政策》并取得用户同意</b>
  ///
  /// [hasAgree] 隐私权政策是否已经取得用户同意
  AMapFlutterLocation.updatePrivacyAgree(true);

  AMapFlutterLocation.setApiKey(androidKey, iosKey);
}


class UserLocation {
  static UserLocation? instance;

  AMapLocationOption locationOption = AMapLocationOption();

  bool getLocationDoing = false;

  static getInstance() {
    instance ??= UserLocation();
    return instance;
  }

  Map<String, Object>? _locationResult;

  StreamSubscription<Map<String, Object>>? _locationListener;

  final AMapFlutterLocation _locationPlugin = AMapFlutterLocation();

  var startedListener = false;


  getLastLocation() {
    return _locationResult;
  }


  ///开始定位
  void _startLocation({ required int interval }) {
    ///是否单次定位
    locationOption.onceLocation = false;

    ///是否需要返回逆地理信息
    locationOption.needAddress = true;

    ///逆地理信息的语言类型
    locationOption.geoLanguage = GeoLanguage.DEFAULT;

    locationOption.desiredLocationAccuracyAuthorizationMode =
        AMapLocationAccuracyAuthorizationMode.ReduceAccuracy;

    locationOption.fullAccuracyPurposeKey = "AMapLocationScene";

    ///设置Android端连续定位的定位间隔
    locationOption.locationInterval = interval;

    ///设置Android端的定位模式<br>
    ///可选值：<br>
    ///<li>[AMapLocationMode.Battery_Saving]</li>
    ///<li>[AMapLocationMode.Device_Sensors]</li>
    ///<li>[AMapLocationMode.Hight_Accuracy]</li>
    locationOption.locationMode = AMapLocationMode.Hight_Accuracy;

    ///设置iOS端的定位最小更新距离<br>
    locationOption.distanceFilter = -1;

    /// 设置iOS端期望的定位精度
    /// 可选值：<br>
    /// <li>[DesiredAccuracy.Best] 最高精度</li>
    /// <li>[DesiredAccuracy.BestForNavigation] 适用于导航场景的高精度 </li>
    /// <li>[DesiredAccuracy.NearestTenMeters] 10米 </li>
    /// <li>[DesiredAccuracy.Kilometer] 1000米</li>
    /// <li>[DesiredAccuracy.ThreeKilometers] 3000米</li>
    locationOption.desiredAccuracy = DesiredAccuracy.Best;

    ///设置iOS端是否允许系统暂停定位
    locationOption.pausesLocationUpdatesAutomatically = false;

    ///将定位参数设置给定位插件
    _locationPlugin.setLocationOption(locationOption);

    _locationPlugin.startLocation();
  }

  ///停止定位
  void _stopLocation() {
    _locationPlugin.stopLocation();
  }


  /// 动态申请定位权限
  requestPermission() async {
    // 申请权限
    bool hasLocationPermission = await requestLocationPermission();
    if (hasLocationPermission) {
      print("定位权限申请通过");
    } else {
      print("定位权限申请不通过");
      return Future.error('未赋予定位权限');
    }
  }

  /// 申请定位权限
  /// 授予定位权限返回true， 否则返回false
  Future<bool> requestLocationPermission() async {
    //获取当前的权限
    var status = await Permission.locationAlways.status;
    if (status == PermissionStatus.granted) {
      //已经授权
      return true;
    }

    //未授权则发起一次申请
    status = await Permission.locationAlways.request();
    if (status == PermissionStatus.granted) {
      return true;
    }

    status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      return true;
    }

    status = await Permission.locationAlways.request();
    return status == PermissionStatus.granted;
  }

  ///获取iOS native的accuracyAuthorization类型
  void requestAccuracyAuthorization() async {
    AMapAccuracyAuthorization currentAccuracyAuthorization =
    await _locationPlugin.getSystemAccuracyAuthorization();
    if (currentAccuracyAuthorization ==
        AMapAccuracyAuthorization.AMapAccuracyAuthorizationFullAccuracy) {
      print("精确定位类型");
    } else if (currentAccuracyAuthorization ==
        AMapAccuracyAuthorization.AMapAccuracyAuthorizationReducedAccuracy) {
      print("模糊定位类型");
    } else {
      print("未知定位类型");
    }
  }

  getLocation() async {

    if (getLocationDoing) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return _locationResult == null; // 返回true 将继续while 循环
      });
      return _locationResult;
    }

    int targetInterval = locationOption.locationInterval;
    _locationResult = null;

    bool isInit = !startedListener;

    getLocationDoing = true;

    if (isInit) {
      await startLocationListener(interval: 1000);
    } else {
      debugPrint('set locationInterval 1000');
      _stopLocation();
      _startLocation(interval: 1000);
    }



    // 等待有定位结果

    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      return _locationResult == null; // 返回true 将继续while 循环
    });

    if (isInit) {
      disposeListener();
    } else {
      _stopLocation();
      _startLocation(interval: targetInterval);
    }

    getLocationDoing = false;

    return _locationResult;
  }

  Future startLocationListener({ int interval = 20000 }) async {
    if (startedListener) return;
    startedListener = true;

    try {
      /// 动态申请定位权限
      await requestPermission();
    } catch (e) {
      startedListener = false;
      rethrow;
    }


    ///iOS 获取native精度类型
    if (Platform.isIOS) {
      requestAccuracyAuthorization();
    }

    ///注册定位结果监听
    _locationListener = _locationPlugin.onLocationChanged().listen((Map<String, Object> result) {
      _locationResult = result;
      print(jsonEncode(result));
      eventBus.fire(UserLocationChange(result));
    });

    _startLocation(interval: interval);
  }



  void disposeListener() {

    _stopLocation();

    ///移除定位监听
    _locationListener?.cancel();

    ///销毁定位
    _locationPlugin.destroy();

    startedListener = false;
  }
}