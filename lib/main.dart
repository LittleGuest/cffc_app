import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

final dylib = DynamicLibrary.open(_dylibPath());

/// 动态链接库地址
String _dylibPath() {
  var root = "dylib/";
  if (Platform.isLinux) {
    return root + "linux/libcffc.so";
  } else if (Platform.isWindows) {
    return root + "windows/cffc.dll";
  } else if (Platform.isMacOS) {
    return root + "macos/libcffc.so";
  } else if (Platform.isAndroid) {
    return root + "android/libcffc.so";
  } else if (Platform.isIOS) {
    return root + "ios/libcffc.so";
  } else if (Platform.isFuchsia) {
    return root + "fuchsia/libcffc.so";
  }
  return root;
}

typedef cc = Pointer<Utf8> Function(
    Pointer<Utf8> from, Pointer<Utf8> to, Pointer<Utf8> text);
typedef cd = Pointer<Utf8> Function(
    Pointer<Utf8> from, Pointer<Utf8> to, Pointer<Utf8> text);

/// FFI Rust 转换函数
final convert = dylib.lookupFunction<cc, cd>("convert");

typedef kc = Int32 Function(Pointer<Utf8> from, Pointer<Utf8> text);
typedef kd = int Function(Pointer<Utf8> from, Pointer<Utf8> text);

/// FFI Rust 校验函数
final check = dylib.lookupFunction<kc, kd>("check");

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  String _from = "";
  String _to = "";
  String _fromText = "";
  String _toText = "";

  var ftec = TextEditingController();
  var ttec = TextEditingController();

  static const menuItems = <String>["", "json", "toml", "yaml"];

  final List<DropdownMenuItem<String>> dropDownMenuItems = menuItems
      .map((value) => DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          ))
      .toList();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'cffc',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Row(children: <Widget>[
          Expanded(
              flex: 6,
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                    flex: 1,
                    child: Container(
                      child: DropdownButton(
                        items: dropDownMenuItems,
                        value: _from,
                        hint: Text("请选择"),
                        onChanged: (value) {
                          _from = value.toString();
                        },
                        iconSize: 32,
                      ),
                    )),
                Expanded(
                    flex: 10,
                    child: TextField(
                      controller: ftec,
                      maxLines: 50,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        _fromText = val;
                      },
                    )),
                Expanded(
                    flex: 1,
                    child:
                        ButtonBar(alignment: MainAxisAlignment.end, children: [
                      IconButton(
                        icon: Icon(Icons.check),
                        iconSize: 32,
                        onPressed: () {
                          _check(_from, _fromText);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.copy),
                        iconSize: 32,
                        onPressed: () {
                          _copy(_fromText);
                        },
                      ),
                    ])),
              ])),
          Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                      child: IconButton(
                    icon: Icon(Icons.chevron_right),
                    iconSize: 48,
                    onPressed: () {
                      _convert("right", _from, _to, _fromText);
                    },
                  )),
                  Expanded(
                      child: IconButton(
                    icon: Icon(Icons.chevron_left),
                    iconSize: 48,
                    onPressed: () {
                      _convert("left", _to, _from, _toText);
                    },
                  )),
                ],
              )),
          Expanded(
              flex: 6,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 1,
                        child: DropdownButton(
                          items: dropDownMenuItems,
                          value: _to,
                          hint: Text("请选择"),
                          onChanged: (value) {
                            _to = value.toString();
                          },
                        )),
                    Expanded(
                      flex: 10,
                      child: TextField(
                        controller: ttec,
                        maxLines: 50,
                        textCapitalization: TextCapitalization.sentences,
                        decoration:
                            InputDecoration(border: OutlineInputBorder()),
                        onChanged: (val) {
                          _toText = val;
                        },
                      ),
                    ),
                    Expanded(
                        flex: 1,
                        child: ButtonBar(
                            alignment: MainAxisAlignment.start,
                            children: [
                              IconButton(
                                icon: Icon(Icons.check),
                                iconSize: 32,
                                onPressed: () {
                                  _check(_to, _toText);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.copy),
                                iconSize: 32,
                                onPressed: () {
                                  _copy(_toText);
                                },
                              ),
                            ])),
                  ]))
        ]),
      ),
    );
  }

  /// 转换
  _convert(String dec, String from, String to, String text) {
    var cs =
        convert(from.toNativeUtf8(), to.toNativeUtf8(), text.toNativeUtf8());
    switch (dec) {
      case "right":
        ttec.text = cs.toDartString();
        break;
      case "left":
        ftec.text = cs.toDartString();
        break;
      default:
        break;
    }
  }

  /// 格式校验
  _check(String from, String text) {
    var cs = check(from.toNativeUtf8(), text.toNativeUtf8());
    if (cs == 1) {
      () => Fluttertoast.showToast(msg: "正确的 " + from);
    } else {
      () => Fluttertoast.showToast(msg: "不正确的 " + from);
    }
  }

  /// 复制
  _copy(String text) {
    var data = ClipboardData(text: text);
    Clipboard.setData(data);
    () => Fluttertoast.showToast(msg: "复制成功");
  }
}
