import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:jpush_flutter/jpush_flutter.dart';

import 'events.dart';

class JPushUtil {
  static final JPush jpush = JPush();

  static bool jPushInitEd = false;

  static String jpushAppKey = '';

  static String ipushChannelName = '';

  // 极光的注册设备id
  static String jpushRegistrationID = '';

  static String jPushTags = '';



  static initPlatformState(String appKey, String channelName) async {
    if (jPushInitEd) {
      debugPrint('极光已经初始化');
      return;
    }

    jpushAppKey = appKey;

    ipushChannelName = channelName;

    jpush.addEventHandler(
      onReceiveNotification: (Map<String, dynamic> message) async {
        debugPrint("flutter onReceiveNotification: $message");
        eventBus.fire(JPushReceiveMessage(jsonDecode(jsonEncode(message))));
      },
      onOpenNotification: (Map<String, dynamic> message) async {
        debugPrint("flutter onOpenNotification: $message");
      },
      onReceiveMessage: (Map<String, dynamic> message) async {
        debugPrint("flutter onReceiveMessage: $message");
        eventBus.fire(JPushReceiveMessage(jsonDecode(jsonEncode(message))));
      },
      onReceiveNotificationAuthorization: (Map<String, dynamic> message) async {
        debugPrint("flutter onReceiveNotificationAuthorization: $message");
      },
      onNotifyMessageUnShow: (Map<String, dynamic> message) async {
        debugPrint("flutter onNotifyMessageUnShow: $message");
      },
    );

    jpush.setAuth(enable: true);
    jpush.setup(
      appKey: appKey, //你自己应用的 AppKey
      channel: channelName,
      production: false,
      debug: true,
    );
    jpush.applyPushAuthority(const NotificationSettingsIOS(sound: true, alert: true, badge: true));

    jPushInitEd = true;

    // Platform messages may fail, so we use a try/catch PlatformException.
    String rid = await jpush.getRegistrationID();
    debugPrint("flutter get registration id : $rid");
    jpushRegistrationID = rid;
    return rid;

  }

  static Future<bool> notificationEnabled() async {
    return await jpush.isNotificationEnabled();
  }

  static openNotificationSetting() async {
    jpush.openSettingsForNotification();
  }

  static stop() async {
    if (!jPushInitEd) return;
    await jpush.cleanTags();
    jPushTags = '';
    await jpush.stopPush();
  }



  static resume() async {
    await jpush.resumePush();
    debugPrint('resumePush end');
  }

  /// 清空通知栏上的所有通知
  static clearAllNotifications() async {
    await jpush.clearAllNotifications();
  }

  static setBadge(badge) async {
    if (!jPushInitEd) return;
    try {
      await jpush.setBadge(badge);
    } catch (e, stack) {
      debugPrint(e.toString());
      debugPrint(stack.toString());
    }
  }

  static checkTagsIsEqual(String strFirst, String strSecond) {
    List<String> tagsFirst = strFirst.split(',');
    tagsFirst.sort();
    List<String> tagsSecond = strSecond.split(',');
    tagsSecond.sort();
    return tagsFirst.join(',') == tagsSecond.join(',');
  }

  static setTags(String tagsStr) async {
    if (tagsStr.isEmpty) return;
    if (checkTagsIsEqual(jPushTags, tagsStr)) {
      debugPrint('tag 和缓存中一致 直接跳过set---$jpushRegistrationID');
      return {
        'tags': jPushTags.split(',')
      };
    }
    try {
      Map allTagsMap = await jpush.getAllTags();
      debugPrint('当前极光订阅的tag $allTagsMap  set tag $tagsStr');
      List tags = allTagsMap['tags'] ?? [];
      jPushTags = tags.join(',');
      if (checkTagsIsEqual(jPushTags, tagsStr)) {
        debugPrint('tag 相同 直接跳过set');
        return allTagsMap;
      }
      debugPrint('allTagsMap $allTagsMap');
    } on PlatformException catch (e, stack) {
      debugPrint('PlatformException ${e.code}');
      if (e.code == '6012') {
        // 极光没有启动
        debugPrint('getTags fail 重新启动极光');
        await resume();
      } else if (e.code == '6021') {
        return;
      }

      debugPrint(e.toString());
      debugPrint(stack.toString());
    } catch(e, stack) {
      debugPrint(e.toString());
      debugPrint(stack.toString());
    }

    try {
      Map respMap = await jpush.setTags(tagsStr.split(','));
      jPushTags = tagsStr;
      return respMap;
    } on PlatformException catch (e, stack) {
      debugPrint('PlatformException ${e.code}');
      if (e.code == '6012') {
        // 极光没有启动
        debugPrint('setTags fail 重新启动极光');
        await resume();
      }

      debugPrint(e.toString());
      debugPrint(stack.toString());
    }

    Map respMap = await jpush.setTags(tagsStr.split(','));
    return respMap;

  }

  static getAllTags() async {
    if (!jPushInitEd) {
      return {
        'tags': []
      };
    }
    try {
      // 首次调用在没有设置过tags的情况下会出现报错的情况 这里要捕获一下 报错直接返回空数组tag
      Map respMap = await jpush.getAllTags();
      return respMap;
    } on PlatformException catch (e, stack) {
      debugPrint(e.toString());
      debugPrint(stack.toString());
      if (e.code == '6012') {
        // 极光没有启动
        debugPrint('setTags fail 重新启动极光');
        await resume();
      }
    } catch (e, stack) {
      debugPrint(e.toString());
      debugPrint(stack.toString());
    }
    return {
      'tags': []
    };
  }
}


/**

1005	AppKey 不存在	请到官网检查 Appkey 对应的应用是否已被删除
1008	AppKey 非法	请到官网检查此应用详情中的 Appkey，确认无误
1009
当前的 Appkey 下没有创建 iOS 应用
你所使用的 SDK 版本低于 2.1.0
请到官网检查此应用的应用详情
更新应用中集成的极光 SDK 至最新
6001	无效的设置，tag/alias/property 不应参数都为 null	设置非空参数
6002	设置超时	建议重试，一般出现在网络不佳、初始化尚未完成时
6003	alias 字符串不合法	有效的别名、标签组成：字母（区分大小写）、数字、下划线、汉字、特殊字符（2.1.9 支持）@!#$&*+=.|
6004	alias 超长，最多 40 个字节	中文 UTF-8 是 3 个字节
6005	某一个 tag 字符串不合法	有效的别名、标签组成：字母（区分大小写）、数字、下划线、汉字、特殊字符（2.1.9 支持）@!#$&*+=.|
6006	某一个 tag 超长，一个 tag 最多 40 个字节	中文 UTF-8 是 3 个字节
6007	tags 数量超出限制，最多 1000 个	这是一台设备的限制，一个应用全局的标签数量无限制
6008	tag 超出总长度限制	总长度最多 7 K 字节
6009	未知错误	SDK 发生了意料之外的异常，客户端日志中将有详细的报错信息，可据此排查
6011	短时间内操作过于频繁	10s 内设置 tag/alias/property 大于 10 次，或 10s 内设置手机号码大于 3 次，或 10s 内设置 property 大于 10 次
6012	在 JPush 服务 stop 状态下设置了 tag 或 alias 或手机号码	开发者可根据这个错误码的信息做相关处理或者提示
6013	用户设备时间轴异常	设备本地时间轴异常变化影响了设置手机号码
6014	网络繁忙	网络繁忙，本次请求失败，请重新发起请求
6015	黑名单	用户被拉入黑名单，请联系 support 解除
6016	该用户无效	失效用户请求失败
6017	该请求无效
本次请求出现异常参数，请求无效
2020/03/10 日新增：别名绑定的设备数超过限制，最高允许绑定 10 个，更多请联系商务
6018	Tags 过多	该用户 tags 已设置超过 1000 个，不能再设置
6019	获取 Tags 失败	在获取全部 tags 时发生异常
6020	请求失败	发生了特殊问题导致请求失败
6021	上一次的 tags 请求还在等待响应，暂时不能执行下一次请求	多次调用 tag 相关的 API，请在获取到上一次调用回调后再做下一次操作；在未取到回调的情况下，等待 20 秒后可做下一次操作
6022	上一次的 alias 请求还在等待响应，暂时不能执行下一次请求	多次调用 alias 相关的 API，请在获取到上一次调用回调后再做下一次操作；在未取到回调的情况下，等待 20 秒后可做下一次操作
6023	手机号码不合法	只能以 “+” 或者数字开头，后面的内容只能包含 “-” 和数字
6024	服务器内部错误	服务器内部错误，过一段时间再重试
6025	手机号码太长	手机号码过长，目前极光检测手机号码的最大长度为 20
6027	别名绑定的设备数超过限制	3.3.2 版本新增的错误码；极光于 2020/03/10 对「别名设置」的上限进行限制，最多允许绑定 10 个设备，如需更高上限，请联系商务
6036	属性操作权限限制	4.8.0 版本新增的错误码；该 appkey 未开通用户属性功能，如需要，请联系商务
6037	属性操作参数错误	请检查属性参数类型格式是否正确；属性名应为 NSString 类型，属性值只支持 NSString、NSNumber、NSDate 类型
6038	上一次的 property 请求还在等待响应，暂时不能执行下一次请求	多次调用 property 相关的 API，请在获取到上一次调用回调后再做下一次操作；在未取到回调的情况下，等待 20 秒后可做下一次操作
7000	地理围栏过期	当前时间超过设置的过期时间
7001	地理围栏不存在	逻辑是触发地理围栏的时候，本地缓存列表没有查找到对应的 geofenceid



 */