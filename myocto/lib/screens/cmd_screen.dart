import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:share/share.dart';
import '../globals.dart' as globals;

class CmdScreen extends StatefulWidget {
  @override
  _CmdScreenState createState() => _CmdScreenState();
}

class _CmdScreenState extends State<CmdScreen> {
  final TextEditingController __textEditingCtl = TextEditingController();
  final TextEditingController editingController = TextEditingController();
  String _secureResponse = "";
  Socket? _s;

  @override
  void initState() {
    super.initState();
    createConnectionToPI();
  }

  @override
  void deactivate() {
    super.deactivate();
    closeConnectionToPI();
  }

  void _showAlert(BuildContext context, String stext) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: Text(stext),
            ));
  }

  @override
  Widget build(BuildContext context) {
    final intl = AppLocalizations.of(context)!;
    return Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 35.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  SizedBox(width: 100, height: 40),
                  Container(
                    alignment: Alignment.center,
                    height: 40.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: const Color(0xFF1E1E1E),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: intl.command,
                        prefixIcon: Icon(Icons.send, color: Colors.white),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10.0),
                      ),
                      style: TextStyle(
                        fontFamily: 'HK Grotesk',
                        fontSize: 20.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        height: 1.13,
                      ),
                      controller: editingController,
                    ),
                  ),
                  SizedBox(width: 100, height: 10),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.multiline,
                      autofocus: false,
                      maxLines: null,
                      readOnly: true,
                      style: TextStyle(
                        fontFamily: 'HK Grotesk',
                        fontSize: 14.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        height: 1.09,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10.0),
                      ),
                      controller: __textEditingCtl,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
// Group: Group 12
                      InkWell(
                        onTap: () async {
                          send(
                              "gcode:SET_VELOCITY_LIMIT SQUARE_CORNER_VELOCITY=1 ACCEL=500:TUNING_TOWER COMMAND=SET_PRESSURE_ADVANCE PARAMETER=ADVANCE START=0 FACTOR=.020\n");
                        },
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Container(
                            alignment: Alignment(0.0, 0.02),
                            width: 120.0,
                            height: 40.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Colors.grey,
                            ),
                            child: Text(
                              intl.padvance,
                              style: TextStyle(
                                fontFamily: 'HK Grotesk',
                                fontSize: 20.0,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 0.97,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
// Group: Group 13
                      InkWell(
                        onTap: () async {
                          send("status\n");
                        },
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Container(
                            alignment: Alignment(0.0, 0.02),
                            width: 120.0,
                            height: 40.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Colors.grey,
                            ),
                            child: Text(
                              intl.state,
                              style: TextStyle(
                                fontFamily: 'HK Grotesk',
                                fontSize: 20.0,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 0.97,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
// Group: Group 12
                      InkWell(
                        onTap: () async {
                          String cmd = editingController.text;
                          send(cmd);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Container(
                            alignment: Alignment(0.0, 0.02),
                            width: 120.0,
                            height: 40.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Colors.blue,
                            ),
                            child: Text(
                              intl.send,
                              style: TextStyle(
                                fontFamily: 'HK Grotesk',
                                fontSize: 20.0,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 0.97,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
// Group: Group 13
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Container(
                            alignment: Alignment(0.0, 0.02),
                            width: 120.0,
                            height: 40.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: const Color(0xFFF32121),
                            ),
                            child: Text(
                              intl.cancel,
                              style: TextStyle(
                                fontFamily: 'HK Grotesk',
                                fontSize: 20.0,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 0.97,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ])));
  }

  Future send(String g) async {
    print('(send) $g\n');
    _s?.write("$g\n");
    return _s?.flush();
  }

  // Create a connection to PI and ask for printer state.
  void createConnectionToPI() async {
    print("Open connection to PI\n");
    try {
      _s = await Socket.connect(globals.api_url, 55555);
      //_s = await Socket.connect('192.168.1.121', 55555);
      _s?.listen((data) {
        _secureResponse = new String.fromCharCodes(data).trim();
        print('(1) $_secureResponse');
        setState(() {
          __textEditingCtl.text = _secureResponse;
        });
      }, onError: ((error, StackTrace trace) {
        _secureResponse = error.toString();
        print("(2) $_secureResponse");
      }), onDone: (() {
        print("(3):Done");
        _s?.destroy();
      }), cancelOnError: false);
    } catch (e) {
      print("(4): Exeption $e");
    }
  }

  // Close connection to PI.
  void closeConnectionToPI() async {
    print("Close connection to PI\n");
    try {
      this._s?.write("exit\n");
      await _s?.flush();
      _s?.destroy();
    } catch (e) {
      print("(5): Exeption $e");
    }
  }
}
