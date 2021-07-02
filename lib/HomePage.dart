import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:stockdiary/Diary.dart';
import 'package:stockdiary/Recommend.dart';

import 'TOFU.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

FirebaseAuth auth = FirebaseAuth.instance;

class _HomePageState extends State<HomePage> {
  static MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
    keywords: <String>['flutter', 'firebase', 'admob'],
    testDevices: <String>[],
  );
  int _rewardPoints = 0;
  BannerAd bannerAd = BannerAd(
    adUnitId: 'ca-app-pub-6925657557995580/7753030928',
    size: AdSize.banner,
    targetingInfo: targetingInfo,
    listener: (MobileAdEvent event) {
      print("BannerAd event is $event");
    },
  );

  Future<void> _signInAnonymously() async {
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
        await FirebaseFirestore.instance
            .collection(auth.currentUser!.uid)
            .doc('매매일지')
            .set({});
        await FirebaseFirestore.instance
            .collection(auth.currentUser!.uid)
            .doc('추천주 기록')
            .set({});
        print('로그인');
      } catch (e) {}
    }
  }

  @override
  void initState() {
    super.initState();
    _signInAnonymously();
    FirebaseAdMob.instance.initialize(
        appId: Platform.isIOS
            ? 'ca-app-pub-6925657557995580~2827388755' // iOS Test App ID
            : 'ca-app-pub-6925657557995580~2827388755'); // Android Test App ID
    bannerAd
      ..load()
      ..show();
    _initRewardedVideoAdListener();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Title(),
          maemae(),
          recommend(),
          tofu(),
        ],
      ),
    );
  }

  Widget Title() {
    return Center(
        child: Container(
      child: Text(
        '주식 일지',
        style: TextStyle(fontFamily: 'Strong', fontSize: 70),
      ),
    ));
  }

  Widget maemae() {
    return Container(
        height: 120,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            color: Color.fromARGB(255, 187, 222, 251),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Diary(),
                  ),
                );
              },
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipOval(
                      child: Material(
                        child: InkWell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.calendar_today_outlined,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Text(
                    '매매일지',
                    style: TextStyle(
                        fontFamily: 'Strong',
                        fontSize: 30,
                        color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Widget recommend() {
    return Container(
        height: 120,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            color: Color.fromARGB(255, 187, 222, 251),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Recommend(),
                  ),
                );
              },
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipOval(
                      child: Material(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.stacked_line_chart,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Text(
                    '추천주 기록',
                    style: TextStyle(
                        fontFamily: 'Strong',
                        fontSize: 30,
                        color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Widget tofu() {
    return Container(
        height: 120,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            color: Colors.black,
            child: InkWell(
              onTap: () {
                print('리워드: $_rewardPoints');
                if (_rewardPoints == 0 || _rewardPoints % 5 == 0) {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('추천주 확인'),
                          content: Text('광고를 시청해야합니다\n시청하시겠습니까?'),
                          actions: [
                            FlatButton(
                              onPressed: () {
                                Navigator.pop(context, "네");
                                showDialog(context: context,  builder: (context) {
                                  return AlertDialog(
                                    title: Text('로딩중'),
                                    content: CircularProgressIndicator(),
                                    actions: [
                                      FlatButton(
                                          onPressed: () {
                                            Navigator.pop(context, "ok");

                                          },
                                          child: Text('취소'))
                                    ],
                                  );
                                });
                                _showRewardedAd();

                              },
                              child: Text('네'),
                            ),
                            FlatButton(
                                onPressed: () {
                                  Navigator.pop(context, "아니요");
                                },
                                child: Text('취소'))
                          ],
                        );
                      });
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Tofu(),
                    ),
                  );
                  _rewardPoints += 1;
                }
              },
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Material(
                      child: InkWell(
                        child: Image.asset(
                          "assets/images/unnamed.png",
                          scale: 5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Text(
                    '두부개미 추천주',
                    style: TextStyle(
                        fontFamily: 'Strong', fontSize: 30, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  void _showRewardedAd() {
    //RewardedVideoAdEvent must be loaded to show video ad thus we check and show it via listener
    //Tip: You chould show a loading spinner while waiting it to be loaded.
    RewardedVideoAd.instance
        .load(adUnitId: 'ca-app-pub-6925657557995580/4492775903',
    targetingInfo: targetingInfo);
    //TODO: replace it with your own Admob Rewarded ID
  }

  void _initRewardedVideoAdListener() {
    RewardedVideoAd.instance.listener =
        (RewardedVideoAdEvent event, {String? rewardType, int? rewardAmount}) {

      if (event == RewardedVideoAdEvent.loaded) {

        RewardedVideoAd.instance.show();
      }
      else if(event == RewardedVideoAdEvent.failedToLoad){
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
            builder: (context) => Tofu(),
            ));
      }
      else if (event == RewardedVideoAdEvent.rewarded) {
        setState(() {
          // Video ad should be finish to get the reward amount.
          _rewardPoints += rewardAmount!;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Tofu(),
            ),
          );
        });
      }
    };
  }
}
