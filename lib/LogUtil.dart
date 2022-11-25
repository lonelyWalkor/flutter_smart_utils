import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import 'http.dart';

class Logger {

  static String url = 'https://songshu-web.cn-hangzhou.log.aliyuncs.com/logstores/client-log/track?APIVersion=0.6.0';

  static String loggerSource = 'app';


  static reportLogData(tag, level, logList) {
    Map body = buildLogReportBody(tag, 'info', logList);
    debugPrint('body $body');
    postHttp(url,
        data: body,
        options: Options(headers: {
          'x-log-bodyrawsize': jsonEncode(body).length,
        })
    );
  }

  static buildLogReportBody(tag, level, logList) {
    return {
      '__topic__':  '',
      '__source__': loggerSource,
      '__tags__': {
        'level': level,
      },
      '__logs__': logList,
    };
  }

  static info(tag, log1) {
    reportLogData(tag, 'info', [{
      'args_0': log1,
      'uuid': '',
    }]);
  }

  static error(tag, log1, [log2]) {
    final logItem = {
      'args_0': log1,
      'uuid': '',
    };
    if (log2 != null) {
      logItem['args_1'] = log2;
    }
    reportLogData(tag, 'info', [logItem]);
  }
}