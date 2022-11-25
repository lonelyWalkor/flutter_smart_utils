import 'dart:convert';

import 'package:esc_pos_utils_plus/esc_pos_utils.dart';
import 'package:flutter/cupertino.dart';

// final profile = await CapabilityProfile.load(name: 'ZJ-5870');
// final generator = Generator(PaperSize.mm58, profile);
// List<int> bytes = [];
//
// bytes += generator.text('Bold text', styles: const PosStyles(bold: true));
// // debugPrint(bytes);
//
// // ByteData logoBytes = await rootBundle.load(
// //   'assets/logo.jpg',
// // );
// //
// // var image = img.decodeImage(logoBytes.buffer.asUint8List());
// //
// // bytes += generator.image(img.copyResize(image!, width: 100));
//
// // return;
//
// // debugPrint(bytes);
//
// // bytes += generator.text(
// //     'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
// // bytes += generator.text('Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ',
// //     styles: PosStyles(codeTable: 'CP1252'));
// // bytes += generator.text('Special 2: blåbærgrød',
// //     styles: PosStyles(codeTable: 'CP1252'));
//
// bytes += generator.text('Reverse text', styles: PosStyles(reverse: true));
// bytes += generator.text('Underlined text',
// styles: PosStyles(underline: true), linesAfter: 1);
// bytes +=
// generator.text('Align left', styles: PosStyles(align: PosAlign.left));
// bytes +=
// generator.text('Align center', styles: PosStyles(align: PosAlign.center));
// bytes += generator.text('Align right',
// styles: PosStyles(align: PosAlign.right), linesAfter: 1);
//
// bytes += generator.row([
// PosColumn(
// text: 'col3',
// width: 3,
// styles: PosStyles(align: PosAlign.center, underline: true),
// ),
// PosColumn(
// text: 'col6',
// width: 6,
// styles: PosStyles(align: PosAlign.center, underline: true),
// ),
// PosColumn(
// text: 'col3',
// width: 3,
// styles: PosStyles(align: PosAlign.center, underline: true),
// ),
// ]);
//
// bytes += generator.text('Text size 200%',
// styles: const PosStyles(
// height: PosTextSize.size2,
// width: PosTextSize.size2,
// ));
// // final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
// // bytes += generator.barcode(Barcode.upcA(barData));
// bytes += generator.feed(5);
// bytes += generator.cut();


class EscPosByJson {
  int pageSize;

  String name;

  EscPosByJson({ required this.pageSize, this.name = 'default' });

  getPaperSize(pageSize) {
    switch (pageSize) {
      case 1: return PaperSize.mm58;
      case 2: return PaperSize.mm72;
      case 3: return PaperSize.mm80;
      default: return PaperSize.mm58;
    }
  }

  getPosAlign(str) {
    switch (str) {
      case 'left': return PosAlign.left;
      case 'center': return PosAlign.center;
      case 'right': return PosAlign.right;
      default: return PosAlign.left;
    }
  }

  getText(item, { key = 'text' }) {
    String text = (item[key] ?? '').toString();
    if (text.isEmpty) text = ' ';
    return text;
  }



  getPosTextSize(str) {
    switch (str) {
      case 1: return PosTextSize.size1;
      case 2: return PosTextSize.size2;
      case 3: return PosTextSize.size3;
      case 4: return PosTextSize.size4;
      case 5: return PosTextSize.size5;
      case 6: return PosTextSize.size6;
      case 7: return PosTextSize.size7;
      case 8: return PosTextSize.size8;
      default: return PosTextSize.size1;
    }
  }

  getQRSize(str) {
    switch (str) {
      case 1: return QRSize.Size1;
      case 2: return QRSize.Size2;
      case 3: return QRSize.Size3;
      case 4: return QRSize.Size4;
      case 5: return QRSize.Size5;
      case 6: return QRSize.Size6;
      case 7: return QRSize.Size7;
      case 8: return QRSize.Size8;
      default: return QRSize.Size1;
    }
  }

  getPosStyles(Map<String, dynamic> item) {
    int font = item['font'];
    return PosStyles(
      bold: item['bold'] ?? false,
      align: getPosAlign(item['align']),
      height: getPosTextSize(font),
      width: getPosTextSize(font > 1 ? font - 1 : font),
    );
  }

  getPosColumn(Map<String, dynamic> item) {
    return PosColumn(text: getText(item), containsChinese: true, width: item['width'] ?? 2, styles: getPosStyles(item));
  }

  buildText(Map<String, dynamic> item, Generator generator) {
    return generator.text(getText(item), styles: getPosStyles(item), containsChinese: true);
  }

  buildRow(Map<String, dynamic> item, Generator generator) {
    debugPrint(item.toString());
    List<PosColumn> colList = [];
    for (Map<String, dynamic> rowMap in item['rows'] ) {
      colList.add(getPosColumn(rowMap));
    }
    return generator.row(colList);
  }

  buildQrcode(Map<String, dynamic> item, Generator generator) {
    return generator.qrcode(getText(item), align: getPosAlign(item['align']), size: getQRSize(item['size']));
  }

  generatorPrintOneCommand(Map<String, dynamic> item, Generator generator) {
    final methodName = item['method'];
    switch(methodName) {
      case 'text': return buildText(item, generator);
      case 'hr': return generator.hr();
      case 'row': return buildRow(item, generator);
      case 'cut': return generator.cut();
      case 'feed': return generator.feed(item['line'] ?? 1);
      case 'barcode': return generator.barcode(Barcode.upcA(item['data'] ?? []));
      case 'qrcode': return buildQrcode(item, generator);
      default: return [];
    }

  }


  Future<List<int>> build(List<Map<String, dynamic>> contentList) async {
    final profile = await CapabilityProfile.load(name: name);
    final generator = Generator(getPaperSize(pageSize), profile);
    List<int> bytes = [];
    for (Map<String, dynamic> item in contentList) {
      bytes += generatorPrintOneCommand(item, generator);
    }
    return bytes;
  }
}