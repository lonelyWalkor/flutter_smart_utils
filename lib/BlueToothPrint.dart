import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_blue_plus/gen/flutterblueplus.pb.dart' as photo;
import 'package:smart_utils/LocalStore.dart';
import 'package:smart_utils/http.dart';
import 'package:smart_utils/test/testData.dart';
import 'package:smart_utils/tools/EscPosByJson.dart';

BluetoothDevice getBluetoothDevice(String name, String address, int type) {
  return BluetoothDevice.fromProto(
    photo.BluetoothDevice(
      name: name,
      remoteId: address,
      type: photo.BluetoothDevice_Type.valueOf(type),
    ),
  );
}



class BlueToothPrint {

  static final FlutterBluePlus _blueTooth = FlutterBluePlus.instance;

  static const String blueLocalStorePrefix = 'BlueTooth';

  static const String blueToothPrintNumStorePrefix = 'BlueToothPrintNum';


  static Future<List> scan(int time) async {
    await _blueTooth.startScan(
      scanMode: const ScanMode(2),
      timeout: Duration(seconds: time),
    );
    final List<BluetoothDevice> resultDevices = [];
    _blueTooth.scanResults.listen((List<ScanResult> scanResults) {
      for (final ScanResult scanResult in scanResults) {
        resultDevices.add(scanResult.device);
      }
    });

    await _blueTooth.stopScan();

    List devices = resultDevices.toSet().toList().map((BluetoothDevice bluetoothDevice) => ({
      'address': bluetoothDevice.id.id,
      'name': bluetoothDevice.name,
      'type': bluetoothDevice.type.index,
    })).toList();
    return devices;
  }

  static checkBlueToothIsConnectedAndTryConnect(String alias) async {
    BluetoothDevice? bluetoothDevice = await getBluetoothDeviceByAlias(alias);
    if (bluetoothDevice == null) return Future.error('未连接蓝牙');
    debugPrint('bluetoothDevice $bluetoothDevice');
    BluetoothDeviceState blueState = await bluetoothDevice.state
        .firstWhere((state) => state == BluetoothDeviceState.connected || state == BluetoothDeviceState.disconnected);
    debugPrint('蓝牙状态 $blueState');

    if (blueState == BluetoothDeviceState.disconnected) {
      // 如果蓝牙未连接 尝试重连一次
      try {
        await connect(bluetoothDevice.name, bluetoothDevice.id.id, bluetoothDevice.type.index, alias);
      } on PlatformException catch (e, stack) {
        debugPrint(e.toString());
        debugPrint(stack.toString());
        return Future.error('蓝牙自动连接未成功，请手动重新连接蓝牙');
      }

    }

    int mtu = await bluetoothDevice.mtu.first;

    debugPrint('设备 ${bluetoothDevice.name} num值为 $mtu');

    return bluetoothDevice;
  }

  // 检查蓝牙是否已经链接
  static Future<BluetoothDevice?> getDevicesConnectedByAddress(String address) async {
    final List<BluetoothDevice> connectedDevices = await _blueTooth.connectedDevices;
    final int deviceConnectedIndex = connectedDevices.indexWhere((BluetoothDevice bluetoothDevice) {
      return bluetoothDevice.id.id == address;
    });
    if (deviceConnectedIndex == -1) return null;
    return connectedDevices[deviceConnectedIndex];
  }

  static Future<BluetoothDevice?> getBluetoothDeviceByAlias(String alias) async {
    String? contentStr = await LocalStore.getItem('${blueLocalStorePrefix}_$alias');
    // debugPrint('contentStr $contentStr');
    if (contentStr == null) return null;
    Map blueMap = jsonDecode(contentStr);
    return getBluetoothDevice(blueMap['name'], blueMap['address'], blueMap['type']);
  }



  static Future connect(String name, String address, int type, String alias) async {
    debugPrint('name: $name');
    debugPrint('address: $address');
    debugPrint('type: $type');
    BluetoothDevice? connectBlueDevice = await getDevicesConnectedByAddress(address);
    if (connectBlueDevice != null) {
      debugPrint('蓝牙已经链接');
      try {
        await LocalStore.setItem('${blueLocalStorePrefix}_$alias', jsonEncode({ 'name': name, 'address': address, 'type': type, 'alias': alias }));
      } catch (e) {
        debugPrint(e.toString());
      }
      return true;
    }
    final bluetoothDevice = getBluetoothDevice(name, address, type);
    debugPrint(bluetoothDevice.toString());
    await bluetoothDevice.connect(timeout: const Duration(seconds: 5), autoConnect: false);

    if (Platform.isAndroid) {
      // 如果是安卓手机 则交换mtu
      debugPrint('交换 mtu 值');
      try {
        await bluetoothDevice.requestMtu(503);
      } catch (e, stack) {
        debugPrint(e.toString());
        debugPrint(stack.toString());
      }
    }

    await LocalStore.setItem('${blueLocalStorePrefix}_$alias', jsonEncode({ 'name': name, 'address': address, 'type': type, 'alias': alias }));
    return true;
  }


  static disconnect(String name, String address, int type, String alias) async {

    BluetoothDevice? connectBlueDevice = await getDevicesConnectedByAddress(address);
    if (connectBlueDevice == null) {
      return true;
    }


    connectBlueDevice.disconnect();

    await LocalStore.removeItem('${blueLocalStorePrefix}_$alias');
    await LocalStore.removeItem(address);

    return true;
  }

  // 根据别名获取 设备 及链接状态
  static Future<Map<String, dynamic>?> getConnectedDeviceByAlias(String alias) async {
    BluetoothDevice? bluetoothDevice = await getBluetoothDeviceByAlias(alias);
    debugPrint('bluetoothDevice $bluetoothDevice');
    if (bluetoothDevice == null) return null;
    try {
      BluetoothDeviceState state = await bluetoothDevice.state.first;
      debugPrint('connect state state: $state');
      return {
        'name': bluetoothDevice.name,
        'address': bluetoothDevice.id.id,
        'type': bluetoothDevice.type.index,
        'alias': alias,
        'connected': state == BluetoothDeviceState.connected,
      };
    } catch (e, stack) {
      debugPrint(e.toString());
      debugPrint(stack.toString());
      return null;
    }
  }

  static getActivityCharacteristic(bluetoothDevice, CharacteristicProperties characteristicProperties) async {
    final List<BluetoothService> bluetoothServices = await bluetoothDevice?.discoverServices() ?? <BluetoothService>[];

    BluetoothCharacteristic? characteristic;

    for (var service in bluetoothServices) {
      if (service.isPrimary) {
        for (var bluetoothCharacteristic in service.characteristics) {
          if (characteristicProperties.write && bluetoothCharacteristic.properties.write) {
            characteristic = bluetoothCharacteristic;
            break;
          }
          if (characteristicProperties.read && bluetoothCharacteristic.properties.read) {
            characteristic = bluetoothCharacteristic;
            break;
          }
          if (characteristicProperties.notify && bluetoothCharacteristic.properties.notify) {
            characteristic = bluetoothCharacteristic;
            break;
          }
        }
      }
    }
    if (null == characteristic) return Future.error('没有找到可用的 characteristic');
    return characteristic;
  }

  static whiteByteByAddress(String address, List<int> byteBuffer) async {
    BluetoothDevice? connectBlueDevice = await getDevicesConnectedByAddress(address);
    if (connectBlueDevice == null) {
      return Future.error('蓝牙未连接');
    }

    BluetoothCharacteristic? characteristic = await getActivityCharacteristic(connectBlueDevice, const CharacteristicProperties(write: true));

    if (null == characteristic) return Future.error('没有找到可用的 characteristic');
    debugPrint('byteBuffer ${byteBuffer.length}');

    int mtu = await connectBlueDevice.mtu.first;

    debugPrint('打印的mtu值 $mtu');

    if (mtu == 0) {
      mtu = 20;
    }
    var stepLen = mtu;
    var len = (byteBuffer.length / stepLen).ceil();
    List<List<int>> list = [];
    for(var ll = 0 ; ll < len; ll ++) {
      var startLen = ll * stepLen;
      var endIndex = startLen + stepLen;
      if (endIndex > byteBuffer.length) {
        endIndex = byteBuffer.length;
      }
      list.add(byteBuffer.sublist(startLen, endIndex));
    }

    debugPrint('print length ${list.length}');

    Future.forEach(list, (List<int> subList) async {
      debugPrint('print');
      return await characteristic.write(subList, withoutResponse: false);
    });
  }


  static print(String url, String alias, int pageSize, { Map<String, dynamic>? queryParameters }) async {
    queryParameters ??= {};
    debugPrint('print $url $alias');
    BluetoothDevice bluetoothDevice = await checkBlueToothIsConnectedAndTryConnect(alias);
    Response response = await getHttpInstance().get(url, queryParameters: queryParameters);
    debugPrint(jsonEncode(response.data['data']));
    // final String content = response.data.toString();
    //  Map<String, dynamic> responseData = jsonDecode(response.data);

    List<Map<String, dynamic>> contentList = List<Map<String, dynamic>>.from(response.data['data']);
    debugPrint(contentList.toString());
    debugPrint('content length contentList ${contentList.length}');
    final escPosByJson = EscPosByJson(pageSize: pageSize);
    List<int> bytes = await escPosByJson.build(contentList);
    int printNum = await LocalStore.getItemToInt('${blueToothPrintNumStorePrefix}_$alias', 1);
    debugPrint('打印张数： $printNum');
    for (int i = 0; i < printNum; i++) {
      debugPrint('print index $i');
      await whiteByteByAddress(bluetoothDevice.id.id, bytes);
    }

  }

  static printTest(String alias) async {
    BluetoothDevice bluetoothDevice = await checkBlueToothIsConnectedAndTryConnect(alias);
    debugPrint('begin pritn test ticket');
    final escPosByJson = EscPosByJson(pageSize: 1);
    List<int> bytes = await escPosByJson.build(testPrintJson);
    debugPrint('bytes $bytes');
    await whiteByteByAddress(bluetoothDevice.id.id, bytes);
  }
}
