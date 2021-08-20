import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../globals.dart' as globals;

class CreditsBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
        child: Container(
            color: Colors.blueGrey,
            child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: SizedBox(
                  width: globals.logicWidth,
                  height: globals.logicHeight,
                  child: CreditsScreen(),
                ))));
  }
}

class CreditsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final intl = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: 520.0,
          //height: 1280.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(width: 520, height: 100),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 520.0,
                  height: 59.0,
                  child: Row(
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          intl.close,
                          style: TextStyle(
                            fontFamily: 'HK Grotesk',
                            fontSize: 30.0,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                            height: 1.13,
                          ),
                        ),
                      ),
                      Spacer(flex: 219),
                      Text(
                        intl.credits,
                        style: TextStyle(
                          fontFamily: 'HK Grotesk',
                          fontSize: 45.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.09,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
              Spacer(flex: 40),
              Align(
                alignment: Alignment.center,
                child: Text(
                  intl.about,
                  style: TextStyle(
                    fontFamily: 'HK Grotesk',
                    fontSize: 40.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Spacer(flex: 40),
              Align(
                alignment: Alignment.center,
                child: Text(
                  intl.cflaticon,
                  style: TextStyle(
                    fontFamily: 'HK Grotesk',
                    fontSize: 40.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Spacer(flex: 40),
              Align(
                alignment: Alignment.center,
                child: Text(
                  intl.cflutter,
                  style: TextStyle(
                    fontFamily: 'HK Grotesk',
                    fontSize: 40.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Spacer(flex: 500),
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
                    intl.close,
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
}
