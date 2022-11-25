import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart';

class PrintTsplUtil {
  List<int> bytes = [];


  addCommand(String comman) {
    // bytes += gbk.encode('$comman\r\n');
    bytes += utf8.encode('$comman\r\n');
  }


  List<int> buildImgByte (int width, int height, Uint8List data) {
    print('ddd: ${data.length}');
    List<int> bytes = [];
    var x = 0;
    var y = 0;
    var mode = 0;
    var w = width;
    var h = height;
    print('width: $w $h');
    var bitw = ((w + 7) / 8).toInt() * 8;
    print('width: $bitw');
    // var bitw = (parseInt(w) % 8) == 0 ? (parseInt(w) / 8) :( parseInt(w) / 8+1);
    var pitch = (bitw / 8).toInt();
    var bits = Uint8List(h * pitch);
    print("w=" + w.toString() + ", h=" + h.toString() + ", bitw=" + bitw.toString() + ", pitch=" + pitch.toString() + ", bits=" + bits.length.toString());
    var cmd = "BITMAP " + x.toString() + "," + y.toString() + "," + pitch.toString() + "," + h.toString() + "," + mode.toString() + ",";
    print("add cmd: " + cmd);
    bytes += utf8.encode(cmd);

    print('sdf ${data.length}');
    // for (var i=0; i<bits.length; i++) {
    //   bits[i] = 0;
    // }
    var lastlen = 0;
    for (y = 0; y < h; y++) {
      for (x = 0; x < w; x++) {
        var idx = (y * w + x) * 4 + 1;
        if (idx > data.length) break;
        var color = data[idx];
        lastlen = y * w + x;
        // print('data: ${color}');
        if (color <= 128) {
          bits[(y * pitch + x / 8).toInt()] |= (0x80 >> (x % 8));
        }
      }
    }
    print('lastlen $lastlen');
    for (var i = 0; i < bits.length; i++) {
      bytes.add((~bits[i]) & 0xff);
      // bytes.add(0x80);

    }
    print('bytes length ${bytes.length}');
    return bytes;
  }

  image(Image imgObj) {
    bytes += buildImgByte(imgObj.width, imgObj.height, imgObj.getBytes(format: Format.rgba));

    bytes += utf8.encode('\r\n');
  }

  pageSize({ width = 58, height = 30, space = 2 }) {
    addCommand('SIZE $width mm, $height mm');
    addCommand('GAP $space mm, 0 mm');
  }

  setText(x, y, font, rotation,x_, y_, str) {
    var data = "TEXT " + x.toString() + "," + y.toString() + ",\"" + font + "\"," + rotation.toString() + "," + x_.toString() + "," + y_.toString() + "," + "\"" + str;
    addCommand(data);
  }


  cls() {
    addCommand('CLS');
  }



  end() {
    addCommand('PRINT 1');
  }

}