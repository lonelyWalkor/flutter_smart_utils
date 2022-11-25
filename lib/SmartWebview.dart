import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';
import 'package:smart_utils/LogUtil.dart';
import 'package:smart_utils/UserLocation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'SmartJsChannel.dart';
import 'ToastManager.dart';
import 'events.dart';

class SmartWebview extends StatefulWidget {
  final String initialUrl;

  final String? userAgent;

  final String channelName;

  final Color processColor;

  final Color safeAreaBg;

  final bool enableJPush;

  //
  final String userAgentDefault = Platform.isAndroid ?
      'Mozilla/5.0 (Linux; Android 7.0; MHA-AL00 Build/HUAWEIMHA-AL00; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/66.0.3359.126 MQQBrowser/6.2 TBS/044904 Mobile Safari/537.36 MMWEBID/7138 MicroMessenger/7.0.4.1420(0x2700043C) Process/tools NetType/4G Language/zh_CN '
      : 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1';

  final Widget? overChild;

  SmartWebview({
    Key? key,
    required this.initialUrl,
    this.userAgent,
    this.channelName = 'NativeFun',
    this.processColor = Colors.green,
    this.safeAreaBg = Colors.black,
    this.enableJPush = false,
    this.overChild,
  }) : super(key: key);

  @override
  _SmartWebviewState createState() => _SmartWebviewState();
}


class _SmartWebviewState extends State<SmartWebview> {
  final Completer<WebViewController> _controller = Completer<WebViewController>();

  WebViewController? webViewControllerIns;

  int webviewPageLoadState = 0; // 0 未加载 1 加载中

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();

    eventBus.on<UserLocationChange>().listen((event) {
      // All events are of type UserLoggedInEvent (or subtypes of it).
      // debugPrint(event.value);
      _runJavascript('positionChanged', data: event.value, success: true);
    });

    eventBus.on<JPushReceiveMessage>().listen((event) {
      Map<String, dynamic> messageMap = event.value;
      debugPrint('jPush message ${messageMap.toString()}');
      _runJavascript('receiveJPushMessage', data: messageMap, success: true);
    });

    PerfectVolumeControl.stream.listen((volume) {
      _runJavascript('volumeChanged', data: volume, flag: '', success: true);
    });

    // Future.delayed(const Duration(seconds: 3), () async {
    //   JPushUtil.initPlatformState('192d387ee2f1ca2dfe91dcdf', 'developer-default');
    // });

    // Future.delayed(const Duration(seconds: 3), () async {
    //   UserLocation.getInstance().startLocationListener();
    // });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (null == webViewControllerIns) return false;
          var canBack = await webViewControllerIns!.canGoBack();
          print('能否返回: $canBack');
          if (canBack) {
            webViewControllerIns!.goBack();
          } else {
            return true;
          }
          return false;
        },
        child: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: IndexedStack(
            index: webviewPageLoadState >= 100 ? 0 : 1,
            children: [
              buildWevView(),
              widget.overChild != null ? widget.overChild! : Container(
                decoration: const BoxDecoration(color: Color(0xffffffff)),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: webviewPageLoadState.toDouble(),
                        valueColor: AlwaysStoppedAnimation(widget.processColor),
                        strokeWidth: 6,
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.only(top: 30),
                      child: const Text(
                          '加载中...',
                          style: TextStyle(
                              color: Color(0xff999999),
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              decoration: TextDecoration.none
                          )
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        )
    );
  }

  String getPlatAgentString() {
    if (Platform.isIOS) {
      return ' iphone ';
    } else if (Platform.isAndroid) {
      return ' android ';
    } else if (Platform.isMacOS) {
      return ' macos ';
    }
    return '';
  }

  buildWevView() {
    var url = Uri.parse(widget.initialUrl);
    var params = jsonDecode(jsonEncode(url.queryParameters));
    params['t'] = DateTime.now().millisecondsSinceEpoch.toString();
    url = url.replace(queryParameters: params);
    return SafeArea(
      child: WebView(
          initialUrl: url.toString(),
          userAgent: widget.userAgentDefault + getPlatAgentString() + (widget.userAgent ?? ''),
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
            webViewControllerIns = webViewController;
          },
          onProgress: (int progress) {
            print("WebView is loading (progress : $progress%)");
            if (webviewPageLoadState == 100) return;
            setState(() {
              webviewPageLoadState = progress;
            });
          },
          javascriptChannels: <JavascriptChannel>{
            _buildWebViewJavascriptChannel(context),
          },
          navigationDelegate: (NavigationRequest request) {
            if (!request.url.startsWith('http://') && !request.url.startsWith('https://')) {
              fireAppIsInitiativeLeaveEvent();
              launchUrl(Uri.parse(request.url)).then((isOpen) {
                print({'是否打开外部地址', isOpen});
              }).catchError((error) {
                print('打开失败');
              });
              return NavigationDecision.prevent;
            }
            print('allowing navigation to $request');
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
            if (webviewPageLoadState == 100) return;
            setState(() {
              webviewPageLoadState = 0;
            });
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
            if (webviewPageLoadState == 100) return;
            setState(() {
              webviewPageLoadState = 100;
            });
          },
          gestureNavigationEnabled: false,
        )
    );
  }


  JavascriptChannel _buildWebViewJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
      name: widget.channelName,
      onMessageReceived: (JavascriptMessage message) {
        debugPrint('web 方法调用: ${message.message}');
        jsChannelCallHandler(jsonDecode(message.message));
      });
  }

  void jsChannelCallHandler(Map options) async {
    if (!options.containsKey('method')) {
      ToastManager.show('method 参数必传');
    }
    String methodName = options['method'];
    String flag = options['flag'] ?? '';
    Object callBackData = '';
    bool execSuccess = true;
    bool showMessage = options['showMessage'] ?? true;
    Function? handlerFun = getChannelFun(methodName);
    if (null != handlerFun) {
      try {
        // throw Exception('dsdfsdf');
        var funResp = await Function.apply(handlerFun, [options], { #context: context });
        if (null != funResp) {
          callBackData = funResp;
        } else {
          callBackData = 'success';
        }
        execSuccess = true;
      } catch (e, stack) {
        debugPrint('$methodName 方法调用失败 ${e.toString()}');
        debugPrint(stack.toString());
        if (showMessage) {
          ToastManager.show(e.toString());
        }
        callBackData = e.toString();
        execSuccess = false;

        Logger.error('channel error', e.toString(), stack.toString());
      }
    } else {
      callBackData = 'method_not_found';
      execSuccess = false;
    }


    _runJavascript(methodName, data: callBackData, success: execSuccess, flag: flag);
  }

  Future<String?> _runJavascript(String methodName, {
    Object data = '',
    String flag = '',
    bool success = true
  }) async {
    if (webViewControllerIns == null) {
      debugPrint('webViewControllerIns 未初始化');
      return null;
    }
    String execJsStr = 'window.externalMsgHandler(${jsonEncode(methodName)}, ${jsonEncode(data)}, ${jsonEncode(flag)}, ${jsonEncode(success)});';
    debugPrint('回调web view $execJsStr');
    String? runResult = await webViewControllerIns!.runJavascriptReturningResult(execJsStr);
    debugPrint('回调 $methodName 执行结果: $runResult');
    return runResult;
  }
}
