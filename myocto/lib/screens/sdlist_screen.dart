import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import "package:collection/collection.dart";
import 'file_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../globals.dart' as globals;

extension StringExtensions on String {
  bool containsIgnoreCase(String secondString) =>
      this.toLowerCase().contains(secondString.toLowerCase());
  //bool isNotBlank() => this != null && this.isNotEmpty;
}

class SDListScreen extends StatefulWidget {
  @override
  _SDListScreenState createState() => _SDListScreenState();
}

class _SDListScreenState extends State<SDListScreen> {
  String _response = "";
  Socket? _s;
  List<String> _itemsAll = [];
  List<String> _items = [];
  bool _loading = true;
  TextEditingController editingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loading = true;
    fetchData().then((v) {
      var itemsJ = jsonDecode(v)['list'] as List;
      setState(() {
        _itemsAll = List.from(itemsJ);
        if (_itemsAll != null) {
          _itemsAll.sort((a, b) {
            return compareAsciiUpperCase(a, b);
          });
        }
        _items = [];
        _items.addAll(_itemsAll);
        _loading = false;
      });
    });
  }

  // Filter list.
  void filterSearchResults(String query) {
    List<String> dummySearchList = [];
    dummySearchList.addAll(_itemsAll);
    if (query.isNotEmpty) {
      List<String> dummyListData = [];
      dummySearchList.forEach((item) {
        if (item.containsIgnoreCase(query)) {
          dummyListData.add(item);
        }
      });
      setState(() {
        _items.clear();
        _items.addAll(dummyListData);
      });
      return;
    } else {
      setState(() {
        _items.clear();
        _items.addAll(_itemsAll);
      });
    }
  }

  Widget slideLeftBackground() {
    final intl = AppLocalizations.of(context)!;
    return Container(
      color: Colors.red,
      child: Align(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Icon(
              Icons.delete,
              color: Colors.white,
            ),
            Text(
              intl.delete,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
            ),
            SizedBox(
              width: 20,
            ),
          ],
        ),
        alignment: Alignment.centerRight,
      ),
    );
  }

  Widget slideRightBackground() {
    final intl = AppLocalizations.of(context)!;
    return Container(
      color: Colors.blue,
      child: Align(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 20,
            ),
            Icon(
              Icons.done,
              color: Colors.white,
            ),
            Text(
              intl.select,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  // Create sinle list item.
  Widget _getListItemTile(BuildContext context, int index) {
    final item = _items[index];
    final intl = AppLocalizations.of(context)!;
    return Dismissible(
      // Show a red background as the item is swiped away.
      background: slideRightBackground(),
      secondaryBackground: slideLeftBackground(),
      key: Key(item),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final bool res = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  content: Text(intl.confirmdelete + " $item?"),
                  actions: <Widget>[
                    FlatButton(
                      child: Text(
                        intl.cancel,
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    FlatButton(
                      child: Text(
                        intl.delete,
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () {
                        removeFile(item);
                        setState(() {
                          _items.removeAt(index);
                          _itemsAll.remove(item);
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              });
          return res;
        } else {
          Navigator.push(context,
              new MaterialPageRoute(builder: (context) => new FileBox(item)));
          return false;
        }
      },
      /*
      onDismissed: (direction) {
        removeFile(item);
        setState(() {
          _items.removeAt(index);
          _itemsAll.remove(item);
        });

        Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text("$item dismissed")));
      },*/
      child: GestureDetector(
        onLongPress: () {
          Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => new FileBox(_items[index])));

          //setState(() {
          //  list[index].isSelected = true;
          //});
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: const Color(0xFF1E1E1E),
          ),
          //color: list[index].isSelected ? Colors.red[100] : Colors.white,
          child: ListTile(
            title: Text(
              _items[index],
              style: TextStyle(
                fontFamily: 'HK Grotesk',
                fontSize: 20.0,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 0.97,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    } else {
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
                  onChanged: (value) {
                    filterSearchResults(value);
                  },
                  decoration: InputDecoration(
                    hintText: intl.search,
                    prefixIcon: Icon(Icons.search, color: Colors.white),
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
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: _getListItemTile,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Container(
                    alignment: Alignment.center,
                    width: 200.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: const Color(0xFFF32121),
                    ),
                    child: Text(
                      intl.close,
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
        ),
      );
    }
  }

  // Fetch list data from PI.
  Future<String> fetchData() async {
    Completer<String> _cmp = new Completer<String>();
    print("Open connection to PI\n");
    _response = "";
    try {
      _s = await Socket.connect(globals.api_url, 55555);
      _s?.listen((data) {
        _response += new String.fromCharCodes(data);
        print('(1)');
      }, onError: ((error, StackTrace trace) {
        _response = error.toString();
        print("(2) $_response");
        _cmp.complete(_response);
      }), onDone: (() {
        print("(3):Done");
        _cmp.complete(_response);
        _s?.destroy();
      }), cancelOnError: false);
      _s?.write("list\n");
      await _s?.flush();
    } catch (e) {
      print("(4): Exeption $e");
      _cmp.complete(_response);
    }
    return _cmp.future;
  }

  // Remove file on PI filesystem.
  void removeFile(String name) async {
    print("Unlink file $name");
    Socket s = await Socket.connect(globals.api_url, 55555);
    s.write("unlink:$name\n");
    await s.flush();
    s.close();
    s.destroy();
  }
}
