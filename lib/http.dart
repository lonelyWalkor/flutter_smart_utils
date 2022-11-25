import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:smart_utils/JPushUtil.dart';

Dio getHttpInstance () {
  var dio = Dio();
  (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate  = (client) {
    client.badCertificateCallback=(X509Certificate cert, String host, int port){
      return true;
    };
  };
  return dio;
}

getJpushHeader() {
  return Options(headers: {
    'jpush_id': JPushUtil.jpushRegistrationID ?? '',
  });
}


getHttp(String url, {
  Map<String, dynamic>? queryParameters,
  Options? options,
}) async {
  await getHttpInstance().get(url, queryParameters: queryParameters, options: options);
}

postHttp(String url, {
  Map<String, dynamic>? queryParameters,
  data,
  Options? options,
}) async {
  await getHttpInstance().post(url, data: data, queryParameters: queryParameters, options: options);
}