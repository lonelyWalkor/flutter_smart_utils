// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'SmartJsChannel.dart';


class SmartBusinessWebview extends StatefulWidget {
  const SmartBusinessWebview({Key? key, this.cookieManager}) : super(key: key);

  final CookieManager? cookieManager;

  @override
  State<SmartBusinessWebview> createState() => _SmartBusinessWebviewState();
}

class _SmartBusinessWebviewState extends State<SmartBusinessWebview> {
  final Completer<WebViewController> _controller = Completer<WebViewController>();

  WebViewController? webViewControllerIns;


  String pageTitle = '';

  String pageUrl = '';

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
    dynamic obj = ModalRoute.of(context)?.settings.arguments;
    if (obj == null) {
      debugPrint('页面参数为空 返回上一个页面');
      Navigator.of(context).pop();
    }
    pageTitle = obj["title"] ?? '';
    pageUrl = obj['url'] ?? '';
    if (pageUrl.isEmpty) {
      debugPrint('页面地址为空 返回上一个页面');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        WebViewController controller = await _controller.future;
        bool canGoBack = await controller.canGoBack();
        if (canGoBack) {
          controller.goBack();
          return false;
        }
        return true;

        // if (null == webViewControllerIns) return false;
        // var canBack = await webViewControllerIns!.canGoBack();
        // print('能否返回: $canBack');
        // if (canBack) {
        //   webViewControllerIns!.goBack();
        // } else {
        //   return true;
        // }
        // return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(pageTitle),
          // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
          actions: <Widget>[
            NavigationControls(_controller.future),
          ],
        ),
        body: WebView(
          initialUrl: pageUrl,
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
            webViewControllerIns = webViewController;
          },
          onProgress: (int progress) {
            print('WebView is loading (progress : $progress%)');
          },
          javascriptChannels: <JavascriptChannel>{
            _toasterJavascriptChannel(context),
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
          gestureNavigationEnabled: true,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls(this._webViewControllerFuture, {Key? key}): super(key: key);

  final Future<WebViewController> _webViewControllerFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: _webViewControllerFuture,
      builder: (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
        final bool webViewReady = snapshot.connectionState == ConnectionState.done;
        final WebViewController? controller = snapshot.data;
        return Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: !webViewReady ? null : () async {
                if (await controller!.canGoBack()) {
                  await controller.goBack();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('没有上一个页面了')),
                  );
                  return;
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: !webViewReady ? null : () async {
                if (await controller!.canGoForward()) {
                  await controller.goForward();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('没有下一个页面了')),
                  );
                  return;
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: !webViewReady ? null : () {
                controller!.reload();
              },
            ),
          ],
        );
      },
    );
  }
}