import 'dart:convert';
import 'dart:core';
import 'dart:core';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'HomePage.dart';

class Tofu extends StatefulWidget {
  @override
  _TofuState createState() => _TofuState();
}

class _TofuState extends State<Tofu> {
  final _formKey = GlobalKey<FormState>();
  bool asTabs = false;
  late String selectedValue;
  var sharedPreferences;
  final List<DropdownMenuItem> items = [];
  var selectedItems;
  String result = '';
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final stockController = TextEditingController();
  final priceController = TextEditingController();
  final targetController = TextEditingController();
  final whyController = TextEditingController();
  final monthController = TextEditingController();
  final dateController = TextEditingController();
  FirebaseAuth _auth = FirebaseAuth.instance;
  var json;
  var nickname;

  Future<List> _loadFromAsset() async {
    final String data = await rootBundle.loadString("assets/KStock.json");
    var json = jsonDecode(data);
    setState(() {
      for (Map stock in json) {
        items.add(DropdownMenuItem(
          child: Text(stock["name"]),
          value: stock["name"],
        ));
      }
    });
    return items;
  }

  Future tofulog() async {
    sharedPreferences = await SharedPreferences.getInstance();

    nickname = sharedPreferences.getString("nickname");
    setState(() {});
    await analytics.setCurrentScreen(
      screenName: '추천주제공',
    );
  } //앱

  @override
  void initState() {
    super.initState();
    tofulog();
    if (DateTime.now().toString().substring(5, 6) == '0') {
      monthController.text = DateTime.now().toString().substring(0, 4) +
          '년 ' +
          DateTime.now().toString().substring(6, 7) +
          '월';
    } else {
      monthController.text = DateTime.now().toString().substring(0, 4) +
          '년 ' +
          DateTime.now().toString().substring(5, 7) +
          '월';
    }

    _loadFromAsset();
  }

  @override
  void dispose() {
    monthController.dispose();

    super.dispose();
  }

  AlertDialog alert = AlertDialog(
    title: Text("기록 중입니다"),
    content: Text("잠시만 기다려주세요 "),
  );

  Widget InputWidget() {
    return SingleChildScrollView(
        child: StatefulBuilder(builder: (context, setState) {
      return Column(
        children: [
          TextField(
            controller: dateController,
            decoration: InputDecoration(
              hintText: '날짜',
              contentPadding:
                  const EdgeInsets.only(left: 14.0, bottom: 1.0, top: 1.0),
            ),
          ),
          TextField(
            controller: stockController,
            decoration: InputDecoration(
              hintText: '종목',
              contentPadding:
                  const EdgeInsets.only(left: 14.0, bottom: 1.0, top: 1.0),
            ),
          ),
          TextField(
            controller: priceController,
            decoration: InputDecoration(
              hintText: '추천가',
              contentPadding:
                  const EdgeInsets.only(left: 14.0, bottom: 1.0, top: 1.0),
            ),
          ),
          TextField(
            decoration: InputDecoration(
              hintText: '목표가',
              contentPadding:
                  const EdgeInsets.only(left: 14.0, bottom: 1.0, top: 1.0),
            ),
            controller: targetController,
          ),
          TextField(
            keyboardType: TextInputType.multiline,
            maxLines: null,
            controller: whyController,
            decoration: InputDecoration(
              hintText: '매수/매도 이유',
              contentPadding:
                  const EdgeInsets.only(left: 14.0, bottom: 1.0, top: 1.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: new TextButton(
                autofocus: false,
                onPressed: () async {
                  if (priceController.text.isNotEmpty&&dateController.text.isNotEmpty&&targetController.text.isNotEmpty&&stockController.text.isNotEmpty) {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return alert;
                        });

                    var date = dateController.text;

                    var set = [];
                    var why = whyController.text;
                    if (whyController.text == "") {
                      why = "생략";
                    }

                    var newset = {
                      "종목": stockController.text,
                      "추천가": priceController.text,
                      "이유": why,
                      "목표가": targetController.text
                    };
                    await firestore
                        .collection('0re')
                        .doc('추천주')
                        .get()
                        .then((DocumentSnapshot ds) {
                      try {
                        set = ds[date];
                      } catch (e) {}
                    });

                    set.insert(0, newset);
                    await firestore
                        .collection('0re')
                        .doc('추천주')
                        .update({date: set});

                    targetController.clear();
                    stockController.clear();
                    priceController.clear();
                    whyController.clear();
                    Navigator.pop(context);
                    Navigator.pop(context);
                  } else {
                    Navigator.pop(context);
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('내용이 비어있습니다'),
                            content: Text('값을 입력해주세요'),
                            actions: [
                              FlatButton(
                                  onPressed: () {
                                    Navigator.pop(context, "ok");

                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            content: Stack(
                                              overflow: Overflow.visible,
                                              children: <Widget>[InputWidget()],
                                            ),
                                          );
                                        });
                                  },
                                  child: Text('확인'))
                            ],
                          );
                        });
                  }
                },
                style: TextButton.styleFrom(
                    primary: Colors.white, backgroundColor: Colors.red),
                child: Text('입력'),
              ),
            ),
          ),
        ],
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backwardsCompatibility: false,
          toolbarHeight: 110,
          backgroundColor: Color.fromRGBO(122, 154, 130, 1),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
          title: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '두부개미 추천주',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                ),
              ),
              _DateSelect(),
            ],
          ),
        ),
        floatingActionButton: SpeedDial(
          child: Icon(Icons.list),
          children: [
            SpeedDialChild(
              child: Icon(Icons.home),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            if (sharedPreferences.getString("nickname") == '두부개미')
              SpeedDialChild(
                child: Icon(Icons.add),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return StatefulBuilder(builder: (context, setState) {
                          return AlertDialog(
                            content: Stack(
                              overflow: Overflow.visible,
                              children: <Widget>[
                                InputWidget(),
                              ],
                            ),
                          );
                        });
                      });
                },
              ),
          ],
        ),
        body: Container(
          color: Colors.white,
          child: Column(
            children: [_List()],
          ),
        ));
  }

  Widget _DateSelect() {
    return Container(
      height: 50,
      child: Row(
        children: [
          Container(
            margin: EdgeInsets.all(5),
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: FlexColor.redLightPrimary),
            child: IconButton(
              onPressed: () {
                var year;
                var nextmonth;

                if (monthController.text.substring(6, 8) == '1월') {
                  year = int.parse((monthController.text.substring(0, 4))) - 1;
                  nextmonth = 12;
                } else if (monthController.text.toString().length == 8) {
                  year = int.parse(monthController.text.substring(0, 4));
                  nextmonth =
                      int.parse(monthController.text.substring(6, 7)) - 1;
                } else {
                  year = int.parse(monthController.text.substring(0, 4));
                  nextmonth =
                      int.parse(monthController.text.substring(6, 8)) - 1;
                }

                monthController.text =
                    year.toString() + '년 ' + nextmonth.toString() + '월';
                setState(() {});
              },
              icon: Icon(
                Icons.arrow_left,
              ),
            ),
          ),
          Expanded(
            child: Container(
              child: TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: FlexColor.lightSurface,
                  hintText: '월 선택',
                  contentPadding:
                      const EdgeInsets.only(left: 14.0, bottom: 1.0, top: 1.0),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(25.7),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(25.7),
                  ),
                ),
                style: TextStyle(color: FlexColor.darkScaffoldBackground),
                textAlign: TextAlign.center,
                autofocus: false,
                readOnly: true,
                controller: monthController,
                onTap: () async {
                  var date = await showMonthPicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                      locale: Locale("ko", "KO"));
                  if (date.toString().substring(5, 6) == '0') {
                    monthController.text = date.toString().substring(0, 4) +
                        '년 ' +
                        date.toString().substring(6, 7) +
                        '월';
                  } else {
                    monthController.text = date.toString().substring(0, 4) +
                        '년 ' +
                        date.toString().substring(5, 7) +
                        '월';
                  }
                  setState(() {});
                },
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.all(5),
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: FlexColor.redLightPrimary),
            child: IconButton(
                onPressed: () {
                  var year;
                  var nextmonth;

                  if (monthController.text.toString().length == 8) {
                    year = int.parse(monthController.text.substring(0, 4));
                    nextmonth =
                        int.parse(monthController.text.substring(6, 7)) + 1;
                  } else if (monthController.text.substring(6, 9) == '12월') {
                    year =
                        int.parse((monthController.text.substring(0, 4))) + 1;
                    nextmonth = 1;
                  } else {
                    year = int.parse(monthController.text.substring(0, 4));
                    nextmonth =
                        int.parse(monthController.text.substring(6, 8)) + 1;
                  }

                  monthController.text =
                      year.toString() + '년 ' + nextmonth.toString() + '월';
                  setState(() {});
                },
                icon: Icon(Icons.arrow_right)),
          )
        ],
      ),
    );
  }

  Widget _List() {
    return new StreamBuilder(
        stream:
            FirebaseFirestore.instance.collection('0re').doc('추천주').snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('error'),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          final data = snapshot.requireData.data();

          var keysss = data!.keys
              .where((k) =>
                  (monthController.text.length == 8 &&
                      k.substring(6, 7) ==
                          monthController.text.substring(6, 7) &&
                      k.substring(0, 4) ==
                          monthController.text.substring(0, 4)) ||
                  (k.substring(5, 7) == monthController.text.substring(6, 8) &&
                      k.substring(0, 4) ==
                          monthController.text.substring(0, 4)))
              .toList();
          keysss.sort();
          var keyss = List.from(keysss.reversed);
          return Flexible(
            child: ListView(
              children: [
                for (var index in keyss)
                  Container(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            alignment: Alignment.center,
                            width: 60,
                            height: 60,
                            child: Text(
                              index.replaceRange(0, 8, '') + '일',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.fromRGBO(0, 82, 33, 1),
                            ),
                            padding: EdgeInsets.all(10),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                for (var i in data[index])
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 0, 0, 10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Container(
                                        child: Card(
                                          color:
                                              Color.fromRGBO(255, 236, 227, 1),
                                          child: Padding(
                                            padding: const EdgeInsets.all(7.0),
                                            child: Column(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          0, 0, 0, 8),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text('종목: '),
                                                          Text(
                                                            i['종목'],
                                                            style: TextStyle(
                                                                fontFamily:
                                                                    'Strong',
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 20),
                                                          )
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Text('추천단가: '),
                                                    Text(
                                                      i['추천가'],
                                                      style: TextStyle(
                                                          fontFamily: 'Strong',
                                                          color: Colors.red,
                                                          fontSize: 20),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Text('목표가: '),
                                                    Text(
                                                      i['목표가'],
                                                      style: TextStyle(
                                                          fontFamily: 'Strong',
                                                          color: Colors.red,
                                                          fontSize: 20),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  child: Card(
                                                    elevation: 10,
                                                    child: Container(
                                                      width: 500,
                                                      padding:
                                                          EdgeInsets.all(10),
                                                      child: Text(
                                                        i['이유'].replaceAll(
                                                            "\\n", "\n"),
                                                        maxLines: 40,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            fontSize: 13,
                                                            fontFamily:
                                                                'Nanum'),
                                                      ),
                                                      color: Color(0xffFFFFA5),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                //data[index]가 날짜별 갯수
                                //data[index].keys는 갯수들
                              ],
                              crossAxisAlignment: CrossAxisAlignment.end,
                            ),
                          ),
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                      color: Colors.grey,
                      width: 2,
                    ))),
                  ),
              ],
            ),
          );
        });
  }
}
