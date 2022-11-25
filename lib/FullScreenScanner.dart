import 'package:ai_barcode/ai_barcode.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';


///
/// FullScreenScannerPage
class FullScreenScannerPage extends StatefulWidget {
  const FullScreenScannerPage({Key? key}) : super(key: key);

  @override
  _FullScreenScannerPageState createState() => _FullScreenScannerPageState();
}

class _FullScreenScannerPageState extends State<FullScreenScannerPage> {

  @override
  Widget build(BuildContext context) {
    String title = '扫码';
    dynamic obj = ModalRoute.of(context)?.settings.arguments;
    if (obj != null) {
      title = obj["title"];
    }
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: AppBarcodeScannerWidget.defaultStyle(
              resultCallback: (String code) {
                Navigator.of(context).pop({"code": code});
              },
              openManual: false,
              label: title,
            ),
          ),
        ],
      ),
    );
  }
}




late String _label;
late Function(String result) _resultCallback;


class AppBarcodeScannerWidget extends StatefulWidget {
  final bool openManual;

  AppBarcodeScannerWidget.defaultStyle({
    super.key,
    Function(String result)? resultCallback,
    this.openManual = false,
    String label = '',
  }) {
    _resultCallback = resultCallback ?? (String result) {};
    _label = label;
  }

  @override
  _AppBarcodeState createState() => _AppBarcodeState();
}

class _AppBarcodeState extends State<AppBarcodeScannerWidget> {
  bool _isGranted = false;

  bool _useCameraScan = true;

  bool _openManual = false;

  String _inputValue = "";

  @override
  void initState() {
    super.initState();

    _openManual = widget.openManual;

    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) async {
      TargetPlatform platform = Theme.of(context).platform;
      if (!kIsWeb) {
        if (platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS) {
          var perEnd = await _requestMobilePermission();
          setState(() {
            _isGranted = perEnd;
          });
        } else {
          setState(() {
            _isGranted = true;
          });
        }
      } else {
        setState(() {
          _isGranted = true;
        });
      }
    });
  }

  Future<bool> _requestMobilePermission() async {
    //获取当前的权限
    var status = await Permission.camera.status;
    debugPrint('权限: $status');
    if (status == PermissionStatus.granted) {
      //已经授权
      return true;
    } else {
      //未授权则发起一次申请
      status = await Permission.camera.request();
      debugPrint('请求权限结果: $status');
      if (status == PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: _isGranted ?
            _useCameraScan ?
            _BarcodeScannerWidget()
              : _BarcodeInputWidget.defaultStyle(
            changed: (String value) {
              _inputValue = value;
            },
          )
              : Center(
            child: OutlinedButton(
              onPressed: () {
                _requestMobilePermission();
              },
              child: const Text("请求权限"),
            ),
          ),
        ),
        _openManual ? _useCameraScan ? OutlinedButton(
          onPressed: () {
            setState(() {
              _useCameraScan = false;
            });
          },
          child: Text("手动输入$_label"),
        )
            : Row(
          children: [
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _useCameraScan = true;
                });
              },
              child: Text("扫描$_label"),
            ),
            OutlinedButton(
              onPressed: () {
                _resultCallback(_inputValue);
              },
              child: Text("确定"),
            ),
          ],
        )
            : Container(),
      ],
    );
  }
}

class _BarcodeInputWidget extends StatefulWidget {
  late ValueChanged<String> _changed;

  _BarcodeInputWidget.defaultStyle({
    required ValueChanged<String> changed,
  }) {
    _changed = changed;
  }

  @override
  State<StatefulWidget> createState() {
    return _BarcodeInputState();
  }
}

class _BarcodeInputState extends State<_BarcodeInputWidget> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final text = _controller.text.toLowerCase();
      _controller.value = _controller.value.copyWith(
        text: text,
        selection:
        TextSelection(baseOffset: text.length, extentOffset: text.length),
        composing: TextRange.empty,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Padding(padding: EdgeInsets.all(8)),
        Row(
          children: <Widget>[
            const Padding(padding: EdgeInsets.all(8)),
            Text(
              "$_label：",
            ),
            Expanded(
              child: TextFormField(
                controller: _controller,
                onChanged: widget._changed,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            const Padding(padding: EdgeInsets.all(8)),
          ],
        ),
        const Padding(padding: EdgeInsets.all(8)),
      ],
    );
  }
}

///ScannerWidget
class _BarcodeScannerWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AppBarcodeScannerWidgetState();
  }
}

class _AppBarcodeScannerWidgetState extends State<_BarcodeScannerWidget> {
  late ScannerController _scannerController;

  @override
  void initState() {
    super.initState();

    _scannerController = ScannerController(scannerResult: (result) {
      _resultCallback(result);
    }, scannerViewCreated: () {
      TargetPlatform platform = Theme.of(context).platform;
      if (TargetPlatform.iOS == platform) {
        Future.delayed(const Duration(seconds: 2), () {
          _scannerController.startCamera();
          _scannerController.startCameraPreview();
        });
      } else {
        _scannerController.startCamera();
        _scannerController.startCameraPreview();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();

    if (_scannerController.isStartCamera) {
      _scannerController.stopCamera();
    }

    if (_scannerController.isStartCameraPreview) {
      _scannerController.stopCameraPreview();
    }

    if (_scannerController.isOpenFlash) {
      _scannerController.closeFlash();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Expanded(
          child: _getScanWidgetByPlatform(),
        ),
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Center(
            child: TextButton(
              onPressed: () {
                _scannerController.toggleFlash();
              },
              child: const Text("手电筒", style: TextStyle(color: Colors.white)),
            ),
          )
        )
      ],
    );
  }

  Widget _getScanWidgetByPlatform() {
    return PlatformAiBarcodeScannerWidget(
      platformScannerController: _scannerController,
    );
  }
}