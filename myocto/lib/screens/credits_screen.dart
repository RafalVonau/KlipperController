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
     return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: 520.0,
          //height: 1280.0,
          child:Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 520, height: 200),
          Align(
            alignment: Alignment.center,
            child:Text(
              AppLocalizations.of(context).credits,
              style: TextStyle(
                fontFamily: 'HK Grotesk',
                fontSize: 60.0,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Spacer(flex: 40),
          Align(
            alignment: Alignment.center,
            child:Text(
            AppLocalizations.of(context).about,
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
            child:Text(
            AppLocalizations.of(context).cflaticon,
             style: TextStyle(
                fontFamily: 'HK Grotesk',
                fontSize: 40.0,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Spacer(flex: 40),
          Align(
            alignment: Alignment.center,
            child:Text(
            AppLocalizations.of(context).cflutter,
             style: TextStyle(
                fontFamily: 'HK Grotesk',
                fontSize: 40.0,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Spacer(flex: 500),
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Container(
                alignment: Alignment(0.0, 0.02),
                width: 560.0,
                height: 80.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                    color: const Color(0xFFF32121),
                  ),
                  child: Text(
                    AppLocalizations.of(context).cancel,
                    style: TextStyle(
                      fontFamily: 'HK Grotesk',
                      fontSize: 40.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),),);
  }
}
