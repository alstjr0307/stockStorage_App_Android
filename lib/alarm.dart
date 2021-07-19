import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'HomePage.dart';
class Alarm extends StatefulWidget {
  @override
  _AlarmState createState() => _AlarmState();
}

class _AlarmState extends State<Alarm> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('알림'),
      ),
      body: _List(),
    );
  }
  Future alarmlog() async {
    await analytics.setCurrentScreen(
      screenName: '알림',
      screenClassOverride: 'alarm',
    );
  } //앱
  @override
  void initState() {
    super.initState();
    alarmlog();
  }
  Widget _List() {
    return StreamBuilder(stream:FirebaseFirestore.instance
        .collection('0000alarm')
        .doc('알람')
        .snapshots(),
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
          var index = data!.keys.toList();
          index.sort();


          return ListView(
            children: [
              for (var i in index.reversed) //i는 시간, data[i]는 map
                Card(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer),
                          Text(i, style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text(data[i]['title'], style: TextStyle(fontSize:17, fontFamily: 'Strong'),),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text(data[i]['content'].replaceAll("\\n", "\n")),
                          ],
                        ),
                      )

                    ],
                  ),
                )
            ],
          );
        }
    );
  }
}
