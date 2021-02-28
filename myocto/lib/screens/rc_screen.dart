import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../globals.dart' as globals;

class RCBox extends StatelessWidget {
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
                  child: RCScreen(),
                ))));
  }
}

class RCScreen extends StatefulWidget {
  @override
  _RCScreenState createState() => _RCScreenState();
}

class _RCScreenState extends State<RCScreen> {
  Socket _s;
  int _selectedmm;
  int _selectedexmm;
  String _secureResponse;

  @override
  void initState() {
    super.initState();
    _selectedmm = 2;
    _selectedexmm = 2;
    createConnectionToPI();
  }

  @override
  void deactivate() {
    super.deactivate();
    closeConnectionToPI();
  }

  Future send(String g) async {
    _s.write("gcode:$g\n");
    return _s.flush();
  }

  void move(int axis, int dir) async {
    var arr = ['0.1', '1.0', '10.0', '100.0'];
    var axx = ['X', 'Y', 'Z'];
    String distance = ((dir == -1) ? "-" : "") + arr[_selectedmm];
    await send("G91"); // Relative movements
    await send("G1 ${axx[axis]}$distance");
  }

  void extrude(int dir) async {
    int i;
    await send("M82"); //absolute extrusion mode
    await send("G92 E0"); //Reset Extruder
    await send("G92 E0");
    await send("M220 S100"); // Reset Feedrate
    await send("M221 S100"); // Reset Flowrate
    await send("G1 E${dir * 1}.0 F50");
    if (_selectedexmm == 3) {
      for (i = 1; i <= 5; ++i) {
        await send("G1 E${i * dir * 10}.0 F50");
      }
    } else {
      for (i = 1; i <= _selectedexmm; ++i) {
        await send("G1 E${i * dir * 5}.0 F50");
      }
    }
  }

  Widget mmBox(int id, String txt) {
    Border _b = Border.all(
      width: 2.0,
      color: Colors.white,
    );
    if (id < 4) {
      if (id != _selectedmm) _b = null;
    } else {
      if ((id - 4) != _selectedexmm) _b = null;
    }
    return InkWell(
      onTap: () {
        if (id < 4) {
          setState(() {
            _selectedmm = id;
          });
        } else {
          setState(() {
            _selectedexmm = id - 4;
          });
        }
      },
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          alignment: Alignment.center,
          width: 140.0,
          height: 65.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: const Color(0xFF1E1E1E),
            border: _b,
          ),
          child: Text(
            txt,
            style: TextStyle(
              fontFamily: 'HK Grotesk',
              fontSize: 35.0,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 0.97,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double boxW = 80.0;
    final double boxH = 60.0;
    final double boxP = 10.0;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: 600.0,
          height: 1280.0,
          child: Column(
            children: <Widget>[
              SizedBox(width: 20.0, height: 80.0),
              InkWell(
                onTap: () {
                  send("M140 S${globals.bed_temp}").then((v) {
                    send("M104 T0 S${globals.head_temp}");
                  });
                },
                child: Container(
                  alignment: Alignment(0.0, 0.02),
                  width: 600.0,
                  height: 101.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.0),
                    color: const Color(0xFF1E1E1E),
                  ),
                  child: Text(
                    'Set the temperature',
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
              SizedBox(width: 20.0, height: 40.0),
              // row 1 (UP arrow)
              Row(
                children: [
                  SizedBox(width: boxW + boxP, height: boxH),
                  InkWell(
                    onTap: () {
                      move(1, 1);
                    },
                    child: SizedBox(
                      width: boxW,
                      height: boxH,
                      child: Container(
                        alignment: Alignment.center,
                        width: 80.0,
                        height: 60.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: const Color(0xFF1E1E1E),
                        ),
                        child: SvgPicture.string(
                          // Arrow UP
                          '<svg viewBox="170.0 223.0 40.0 34.0" ><path transform="translate(170.0, 223.0)" d="M 17.4141960144043 4.395864486694336 C 18.57414817810059 2.423945188522339 21.42584800720215 2.423945188522339 22.58580017089844 4.395864486694336 L 37.34055328369141 29.47893905639648 C 38.51696395874023 31.47883987426758 37.07499694824219 34 34.7547492980957 34 L 5.245250701904297 34 C 2.925003051757812 34 1.483035206794739 31.47883987426758 2.659447193145752 29.47893905639648 Z" fill="#ffffff" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                          width: 40.0,
                          height: 34.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: boxW + boxP, height: boxH),
                  Spacer(flex: 500),
                  InkWell(
                    onTap: () {
                      move(2, 1);
                    },
                    child: SizedBox(
                      width: boxW,
                      height: boxH,
                      child: Container(
                        alignment: Alignment.center,
                        width: 80.0,
                        height: 60.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: const Color(0xFF1E1E1E),
                        ),
                        child: SvgPicture.string(
                          // Arrow up
                          '<svg viewBox="170.0 223.0 40.0 34.0" ><path transform="translate(170.0, 223.0)" d="M 17.4141960144043 4.395864486694336 C 18.57414817810059 2.423945188522339 21.42584800720215 2.423945188522339 22.58580017089844 4.395864486694336 L 37.34055328369141 29.47893905639648 C 38.51696395874023 31.47883987426758 37.07499694824219 34 34.7547492980957 34 L 5.245250701904297 34 C 2.925003051757812 34 1.483035206794739 31.47883987426758 2.659447193145752 29.47893905639648 Z" fill="#ffffff" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                          width: 40.0,
                          height: 34.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: boxP, height: boxP),
              // Row 2
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      move(0, -1);
                    },
                    child: SizedBox(
                      width: boxW,
                      height: boxH,
                      child: Container(
                        alignment: Alignment.center,
                        width: 80.0,
                        height: 60.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: const Color(0xFF1E1E1E),
                        ),
                        child: SvgPicture.string(
                          // Arrow left
                          '<svg viewBox="83.0 290.0 34.0 40.0" ><path transform="matrix(0.0, -1.0, 1.0, 0.0, 83.0, 330.0)" d="M 17.4141960144043 4.395864486694336 C 18.57414817810059 2.423945188522339 21.42584800720215 2.423945188522339 22.58580017089844 4.395864486694336 L 37.34055328369141 29.47893905639648 C 38.51696395874023 31.47883987426758 37.07499694824219 34 34.7547492980957 34 L 5.245250701904297 34 C 2.925003051757812 34 1.483035206794739 31.47883987426758 2.659447193145752 29.47893905639648 Z" fill="#ffffff" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                          width: 40.0,
                          height: 34.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: boxP, height: boxH),
                  InkWell(
                    onTap: () {
                      send("G28 X Y");
                    },
                    child: SizedBox(
                      width: boxW,
                      height: boxH,
                      child: Container(
                        width: 80.0,
                        height: 60.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: const Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: boxP, height: boxP),
                  InkWell(
                    onTap: () {
                      move(0, 1);
                    },
                    child: SizedBox(
                      width: boxW,
                      height: boxH,
                      child: Container(
                        alignment: Alignment.center,
                        width: 80.0,
                        height: 60.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: const Color(0xFF1E1E1E),
                        ),
                        child: SvgPicture.string(
                          // Arrow right
                          '<svg viewBox="263.0 290.0 34.0 40.0" ><path transform="matrix(0.0, 1.0, -1.0, 0.0, 297.0, 290.0)" d="M 17.4141960144043 4.395864486694336 C 18.57414817810059 2.423945188522339 21.42584800720215 2.423945188522339 22.58580017089844 4.395864486694336 L 37.34055328369141 29.47893905639648 C 38.51696395874023 31.47883987426758 37.07499694824219 34 34.7547492980957 34 L 5.245250701904297 34 C 2.925003051757812 34 1.483035206794739 31.47883987426758 2.659447193145752 29.47893905639648 Z" fill="#ffffff" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                          width: 40.0,
                          height: 34.0,
                        ),
                      ),
                    ),
                  ),
                  Spacer(flex: 500),
                  InkWell(
                    onTap: () {
                      send("G28 Z");
                    },
                    child: SizedBox(
                      width: boxW,
                      height: boxH,
                      child: Container(
                        width: 80.0,
                        height: 60.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: const Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: boxP, height: boxP),
              // row 3 (Down arrow)
              Row(
                children: [
                  SizedBox(width: boxW + boxP, height: boxH),
                  InkWell(
                    onTap: () {
                      move(1, -1);
                    },
                    child: SizedBox(
                      width: boxW,
                      height: boxH,
                      child: Container(
                        alignment: Alignment.center,
                        width: 80.0,
                        height: 60.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: const Color(0xFF1E1E1E),
                        ),
                        child: SvgPicture.string(
                          // Arrow DOWN
                          '<svg viewBox="170.0 363.0 40.0 34.0" ><path transform="matrix(-1.0, 0.0, 0.0, -1.0, 210.0, 397.0)" d="M 17.4141960144043 4.395864486694336 C 18.57414817810059 2.423945188522339 21.42584800720215 2.423945188522339 22.58580017089844 4.395864486694336 L 37.34055328369141 29.47893905639648 C 38.51696395874023 31.47883987426758 37.07499694824219 34 34.7547492980957 34 L 5.245250701904297 34 C 2.925003051757812 34 1.483035206794739 31.47883987426758 2.659447193145752 29.47893905639648 Z" fill="#ffffff" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                          width: 40.0,
                          height: 34.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: boxW + boxP, height: boxH),
                  Spacer(flex: 500),
                  InkWell(
                    onTap: () {
                      move(2, -1);
                    },
                    child: SizedBox(
                      width: boxW,
                      height: boxH,
                      child: Container(
                        alignment: Alignment.center,
                        width: 80.0,
                        height: 60.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: const Color(0xFF1E1E1E),
                        ),
                        child: SvgPicture.string(
                          // Arrow DOWN
                          '<svg viewBox="170.0 363.0 40.0 34.0" ><path transform="matrix(-1.0, 0.0, 0.0, -1.0, 210.0, 397.0)" d="M 17.4141960144043 4.395864486694336 C 18.57414817810059 2.423945188522339 21.42584800720215 2.423945188522339 22.58580017089844 4.395864486694336 L 37.34055328369141 29.47893905639648 C 38.51696395874023 31.47883987426758 37.07499694824219 34 34.7547492980957 34 L 5.245250701904297 34 C 2.925003051757812 34 1.483035206794739 31.47883987426758 2.659447193145752 29.47893905639648 Z" fill="#ffffff" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                          width: 40.0,
                          height: 34.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 20.0, height: 20.0),
              // row 4
              Row(
                children: [
                  mmBox(0, '0.1mm'),
                  Spacer(flex: 10),
                  mmBox(1, '1mm'),
                  Spacer(flex: 10),
                  mmBox(2, '10mm'),
                  Spacer(flex: 10),
                  mmBox(3, '100mm')
                ],
              ),
              // Row 5
              Row(
                children: [
                  SizedBox(width: 15.0, height: 10.0),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 35.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Extrude',
                        style: TextStyle(
                          fontFamily: 'HK Grotesk',
                          fontSize: 35.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 0.97,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Row 6
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      extrude(-1);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: 293.0,
                      height: 65.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: const Color(0xFF1E1E1E),
                      ),
                      child: Text(
                        'Pull in',
                        style: TextStyle(
                          fontFamily: 'HK Grotesk',
                          fontSize: 35.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 0.97,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Spacer(flex: 10),
                  InkWell(
                    onTap: () {
                      extrude(1);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: 293.0,
                      height: 65.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: const Color(0xFF1E1E1E),
                      ),
                      child: Text(
                        'Pull out',
                        style: TextStyle(
                          fontFamily: 'HK Grotesk',
                          fontSize: 35.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 0.97,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 20.0, height: 20.0),
              // Row 7
              Row(
                children: [
                  mmBox(4, '1mm'),
                  Spacer(flex: 10),
                  mmBox(5, '5mm'),
                  Spacer(flex: 10),
                  mmBox(6, '10mm'),
                  Spacer(flex: 10),
                  mmBox(7, '50mm')
                ],
              ),
              // Row 8
              Row(
                children: [
                  SizedBox(width: 15.0, height: 10.0),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 35.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Fan',
                        style: TextStyle(
                          fontFamily: 'HK Grotesk',
                          fontSize: 35.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 0.97,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Row 9
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      send("M107");
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: 293.0,
                      height: 65.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: const Color(0xFF1E1E1E),
                      ),
                      child: Text(
                        'Turn off',
                        style: TextStyle(
                          fontFamily: 'HK Grotesk',
                          fontSize: 35.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 0.97,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Spacer(flex: 10),
                  InkWell(
                    onTap: () {
                      send("M106 S100");
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: 293.0,
                      height: 65.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: const Color(0xFF1E1E1E),
                      ),
                      child: Text(
                        'Turn on',
                        style: TextStyle(
                          fontFamily: 'HK Grotesk',
                          fontSize: 35.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 0.97,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 20.0, height: 20.0),
              // Row 10
              InkWell(
                onTap: () {
                  send("M18");
                },
                child: Container(
                  alignment: Alignment.center,
                  width: 600.0,
                  height: 65.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: const Color(0xFF1E1E1E),
                  ),
                  child: Text(
                    'Disable motors',
                    style: TextStyle(
                      fontFamily: 'HK Grotesk',
                      fontSize: 35.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 0.97,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Spacer(flex: 13),
              // Row 11 - zamknij
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  alignment: Alignment(0.0, 0.02),
                  width: 600.0,
                  height: 101.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.0),
                    color: Colors.blue,
                  ),
                  child: Text(
                    'Close',
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
              SizedBox(width: 20.0, height: 40.0),
            ],
          ),
        ),
      ),
    );
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
        //if (_secureResponse.startsWith("status:")) {
        //gotResponse(_secureResponse);
        //}
      }, onError: ((error, StackTrace trace) {
        _secureResponse = error.toString();
        print("(2) $_secureResponse");
      }), onDone: (() {
        print("(3):Done");
        _s.destroy();
      }), cancelOnError: false);
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
}
