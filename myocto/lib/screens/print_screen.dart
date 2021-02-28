import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../statefulwrapper.dart';
import 'settings_screen.dart';
import '../globals.dart' as globals;

class PrintBox extends StatelessWidget {
  final String _fileName;
  PrintBox(this._fileName) : super();
  @override
  Widget build(BuildContext context) {
    double logicWidth = WidgetsBinding.instance.window.physicalSize.width;
    double logicHeight = WidgetsBinding.instance.window.physicalSize.height;
    return SizedBox.expand(
        child: Container(
            color: Colors.blueGrey,
            child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: SizedBox(
                  width: logicWidth,
                  height: logicHeight,
                  child: PrintScreen(_fileName),
                ))));
  }
}

class PrintScreen extends StatefulWidget {
  final String _fileName;
  PrintScreen(this._fileName) : super();

  @override
  _PrintScreenState createState() => _PrintScreenState(_fileName);
}

class _PrintScreenState extends State<PrintScreen> {
  final String _fileName;
  Socket _s;
  String _secureResponse;
  int _bedTemp;
  int _heaterTemp;
  int _printProgress;
  bool _pause;
  _PrintScreenState(this._fileName) : super();

  @override
  void initState() {
    super.initState();
    _bedTemp = 0;
    _heaterTemp = 0;
    _printProgress = 0;
    _pause = false;
    createConnectionToPI();
  }

  @override
  void deactivate() {
    super.deactivate();
    closeConnectionToPI();
  }

  // Parse response from printer.
  // status:{ok B:57.0 /60.0 T0:200.0/220.0},{ok SD printing byte 6199/23818682}
  void gotResponse(String res) {
    double bedTemp, heaterTemp, printProgress;
    RegExp exp = new RegExp(r"\s(.{1,2}:\d+\.\d+)");
    RegExp exp1 = new RegExp(r"\d+");

    //res = "status:{ok B:57.0 /60.0 T0:200.0/220.0},{ok SD printing byte 6199/23818}";

    List<String> k = res.split('},{');
    if (k.length != 2) return;
    Iterable<String> matches = exp.allMatches(k[0]).map((m) => m[0]);
    Iterable<String> matches1 = exp1.allMatches(k[1]).map((m) => m[0]);
    print(matches);
    print(matches1);
    matches.forEach((s) {
      List<String> l = s.split(':');
      if (l.length == 2) {
        String k = l[0].trim();
        String v = l[1].trim();
        if (k == "B") {
          bedTemp = double.tryParse(v);
          print("Got bed temperature $bedTemp");
        } else if (k == "T0") {
          heaterTemp = double.tryParse(v);
          print("Got heater temperature $heaterTemp");
        }
      }
    });
    if (matches1.length == 2) {
      // Calculate print progress
      printProgress =
          (100 * int.parse(matches1.first)) / int.parse(matches1.last);
    } else {
      printProgress = 0.0;
    }
    setState(() {
      _bedTemp = bedTemp.round();
      _heaterTemp = heaterTemp.round();
      _printProgress = printProgress.round();
    });
  }

  // Create a connection to PI and ask for printer state.
  void createConnectionToPI() async {
    print("Open connection to PI\n");
    try {
      _s = await Socket.connect(globals.api_url, 55555);
      //_s = await Socket.connect('192.168.1.121', 55555);
      _s.listen((data) {
        _secureResponse = new String.fromCharCodes(data).trim();
        print('(1) $_secureResponse');
        if (_secureResponse.startsWith("status:")) {
          gotResponse(_secureResponse);
        }
        Timer(Duration(seconds: 3), () {
          this._s.write("status\n");
        });
      }, onError: ((error, StackTrace trace) {
        _secureResponse = error.toString();
        print("(2) $_secureResponse");
      }), onDone: (() {
        print("(3):Done");
        _s.destroy();
      }), cancelOnError: false);
      this._s.write("status\n");
      await _s.flush();
    } catch (e) {
      print("(4): Exeption $e");
    }
  }

  // Close connection to PI.
  void closeConnectionToPI() async {
    print("Close connection to PI\n");
    try {
      this._s.write("exit\n");
      await _s.flush();
      _s.destroy();
    } catch (e) {
      print("(5): Exeption $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: 600.0,
          height: 1280.0,
          child: Column(
            children: <Widget>[
              Spacer(flex: 60),
              SizedBox(
                width: 600.0,
                height: 280.0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        alignment: Alignment.topCenter,
                        width: 280.0,
                        height: 240.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.0),
                          color: const Color(0xFF1E1E1E),
                        ),
                        child: SizedBox(
                          width: 218.0,
                          height: 240.0,
                          child: Column(
                            children: <Widget>[
                              Spacer(flex: 51),
                              Align(
                                alignment: Alignment(-0.09, 0.0),
                                child: Text(
                                  'Head',
                                  style: TextStyle(
                                    fontFamily: 'HK Grotesk',
                                    fontSize: 30.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    height: 1.13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              //Spacer(flex: 2),
                              SizedBox(width: 10.0, height: 15.0),
                              Text(
                                '$_heaterTemp°C',
                                style: TextStyle(
                                  fontFamily: 'HK Grotesk',
                                  fontSize: 75.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  height: 0.91,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Spacer(flex: 50),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Spacer(flex: 95),
                    Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 280.0,
                        height: 760.0,
                        child: Column(
                          children: <Widget>[
                            Container(
                              alignment: Alignment.topCenter,
                              width: 280.0,
                              height: 240.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30.0),
                                color: const Color(0xFF1E1E1E),
                              ),
                              child: SizedBox(
                                width: 174.0,
                                height: 240.0,
                                child: Column(
                                  children: <Widget>[
                                    Spacer(flex: 51),
                                    Align(
                                      alignment: Alignment(-0.11, 0.0),
                                      child: Text(
                                        'Bed',
                                        style: TextStyle(
                                          fontFamily: 'HK Grotesk',
                                          fontSize: 30.0,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          height: 1.13,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(width: 10.0, height: 15.0),
                                    Text(
                                      '$_bedTemp°C',
                                      style: TextStyle(
                                        fontFamily: 'HK Grotesk',
                                        fontSize: 75.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        height: 0.91,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Spacer(flex: 50),
                                  ],
                                ),
                              ),
                            ),
                            Spacer(flex: 476),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.center,
                width: 600.0,
                height: 240.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  color: const Color(0xFF1E1E1E),
                ),
                child: SizedBox(
                  width: 600.0,
                  height: 142.0,
                  child: Row(
                    children: <Widget>[
                      Spacer(flex: 40),
                      SizedBox(
                        width: 284.0,
                        height: 142.0,
                        child: Column(
                          children: <Widget>[
                            Spacer(flex: 25),
                            Text(
                              'Print progress',
                              style: TextStyle(
                                fontFamily: 'HK Grotesk',
                                fontSize: 40.0,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.23,
                              ),
                            ),
                            Spacer(flex: 1),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '',
                                style: TextStyle(
                                  fontFamily: 'HK Grotesk',
                                  fontSize: 30.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  height: 1.13,
                                ),
                              ),
                            ),
                            Spacer(flex: 25),
                          ],
                        ),
                      ),
                      Spacer(flex: 33),
                      Column(children: <Widget>[
                        SizedBox(width: 10.0, height: 55.0),
                        Text(
                          '$_printProgress%',
                          style: TextStyle(
                            fontFamily: 'HK Grotesk',
                            fontSize: 109.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 0.62,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ]),
                      Spacer(flex: 39),
                    ],
                  ),
                ),
              ),
              Spacer(flex: 100),
              Align(
                alignment: Alignment(0.88, 0.0),
                child: InkWell(
                  onTap: () {
                    //closeConnectionToPI();
                    Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => new SettingsBox()));
                    print('onTap Ustawienia drukarki');
                  },
                  child:
// Group: Group 15

// Group: Group 14
                      Container(
                    alignment: Alignment(0.0, 0.02),
                    width: 280.0,
                    height: 101.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.0),
                      color: Colors.blue,
                    ),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontFamily: 'HK Grotesk',
                        fontSize: 35.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 0.97,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Spacer(flex: 100),
              Container(
                alignment: Alignment(-0.49, -0.04),
                width: 600.0,
                height: 200.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  color: const Color(0xFF1E1E1E),
                ),
                child: SizedBox(
                  width: 520.0,
                  height: 100.0,
                  child: Row(
                    children: <Widget>[
                      Spacer(flex: 30),
                      Align(
                          alignment: Alignment.center,
                          child: Image(image: AssetImage('images/file.png'))),
                      Spacer(flex: 30),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 318.0,
                          child: Column(
                            children: <Widget>[
                              Spacer(flex: 10),
                              Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  _fileName,
                                  style: TextStyle(
                                    fontFamily: 'HK Grotesk',
                                    fontSize: 30.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    height: 0.97,
                                  ),
                                ),
                              ),
                              //Spacer(flex: 10),
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  'GCODE',
                                  style: TextStyle(
                                    fontFamily: 'HK Grotesk',
                                    fontSize: 30.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    height: 1.13,
                                  ),
                                ),
                              ),
                              Spacer(flex: 10),
                            ],
                          ),
                        ),
                      ),
                      Spacer(flex: 30),
                    ],
                  ),
                ),
              ),
              Spacer(flex: 39),
              SizedBox(
                width: 600.0,
                height: 101.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
// Group: Group 12
                    InkWell(
                      onTap: () {
                        print('onTap Pauza');
                        if (_pause) {
                          _pause = false;
                          this._s.write("gcode:M24\n");
                          //this._s.write("gcode:RESUME\n");
                        } else {
                          _pause = true;
                          this._s.write("gcode:M25\n");
                          //this._s.write("gcode:PAUSE\n");
                        }
                      },
                      child: Container(
                        alignment: Alignment(0.0, 0.02),
                        width: 280.0,
                        height: 101.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.0),
                          color: const Color(0xFFF39A21),
                        ),
                        child: Text(
                          'Pause',
                          style: TextStyle(
                            fontFamily: 'HK Grotesk',
                            fontSize: 35.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 0.97,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
// Group: Group 13
                    InkWell(
                      onTap: () {
                        print('onTap Anuluj');
                        Navigator.pop(context);
                      },
                      child: Container(
                        alignment: Alignment(0.0, 0.02),
                        width: 280.0,
                        height: 101.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.0),
                          color: const Color(0xFFF32121),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'HK Grotesk',
                            fontSize: 35.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 0.97,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(flex: 60),
            ],
          ),
        ),
      ),
    );
  }
}
