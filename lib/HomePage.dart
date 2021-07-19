import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'Diary.dart';
import 'Recommend.dart';
import 'TOFU.dart';
import 'alarm.dart';
import 'domesticPost.dart';

const int maxFailedLoadAttempts = 3;


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseAnalytics analytics = FirebaseAnalytics();

class _HomePageState extends State<HomePage> {
  late FirebaseMessaging messaging;
  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  int _rewardPoints = 0;
  int flag = 0;
  InterstitialAd? _alarmAd;


  int _numalarmLoadAttempts = 0;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  Future logAppOpen() async {
    await analytics.logAppOpen();
  } //앱 켰을때 로그 남기기

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
      } catch (e) {}
    }
    analytics.setUserProperty(name: 'name', value: auth.currentUser!.uid);
  }

  Future homelog() async {
    await analytics.setCurrentScreen(
      screenName: '홈',
      screenClassOverride: 'home',
    );
  } //앱

  late BannerAd banner;
  final String iOSTestId = 'ca-app-pub-6925657557995580/7108082955';
  final String androidTestId = 'ca-app-pub-6925657557995580/7753030928';

  @override
  void initState() {
    _createInterstitialAd();
    _createAlarmAd();
    _initRewardedVideoAdListener();
    logAppOpen();
    _signInAnonymously();
    homelog();

    banner = BannerAd(
      size: AdSize.banner,
      adUnitId: Platform.isIOS ? iOSTestId : androidTestId,
      listener: BannerAdListener(),
      request: AdRequest(),
    )..load();

    messaging = FirebaseMessaging.instance;
    messaging.getToken().then((value) {});
    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("추천주 도착!"),
              content: Text(event.notification!.body!),
              actions: [
                TextButton(
                  child: Text("Ok"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("추천주 도착!"),
              content: Text(message.notification!.body!),
              actions: [
                TextButton(
                  child: Text("Ok"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TargetPlatform os = Theme.of(context).platform;
    if (flag == 1)
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
                onPressed: () {
                  _showAlarmAd();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Alarm(),
                    ),
                  );
                },
                icon: Image.asset("assets/images/bell.png"))
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [Title(), maemae(), recommend(), tofu(), info()],
              ),
            ),
            Container(
              height: 50.0,
              child: AdWidget(
                ad: banner,
              ),
            ),
          ],
        ),
      );
    else
      return Scaffold(
        body: Center(
            child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 30),
              Text(
                '로딩중입니다',
              )
            ],
          ),
        )),
      );
  }

  Widget Title() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: Center(
        child: Container(
          child: Text(
            '주식 일지',
            style: TextStyle(fontFamily: 'Strong', fontSize: 50),
          ),
        ),
      ),
    );
  }

  Widget maemae() {
    return Container(
        height: 100,
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
        height: 100,
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
        height: 100,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            color: Colors.black,
            child: InkWell(
              onTap: () {
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

                                showDialog(
                                    context: context,
                                    builder: (context) {
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

  Widget info() {
    return Container(
        height: 100,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            color: Colors.black,
            child: InkWell(
              onTap: () {
                _showInterstitialAd();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Info(),
                  ),
                );
              },
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                        child: Icon(
                      Icons.info_rounded,
                      size: 40,
                      color: Colors.white,
                    )),
                  ),
                  SizedBox(width: 20),
                  Text(
                    '주식 정보글',
                    style: TextStyle(
                        fontFamily: 'Strong', fontSize: 30, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: 'ca-app-pub-6925657557995580/8468539731',
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _numInterstitialLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            _numInterstitialLoadAttempts += 1;
            _interstitialAd = null;
            if (_numInterstitialLoadAttempts <= maxFailedLoadAttempts) {
              _createInterstitialAd();
            }
          },
        ));
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        _createInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  void _createAlarmAd() {
    InterstitialAd.load(
        adUnitId: 'ca-app-pub-6925657557995580/1248239853',
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _alarmAd = ad;
            _numalarmLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            _numalarmLoadAttempts += 1;
            _alarmAd = null;
            if (_numalarmLoadAttempts <= maxFailedLoadAttempts) {
              _createAlarmAd();
            }
          },
        ));
  }

  void _showAlarmAd() {
    if (_alarmAd == null) {
      return;
    }
    _alarmAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _createAlarmAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        _createAlarmAd();
      },
    );
    _alarmAd!.show();
    _alarmAd = null;
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Tofu(),
        ),
      );
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        Navigator.pop(context);
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _initRewardedVideoAdListener();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        Navigator.pop(context);

        ad.dispose();
        _initRewardedVideoAdListener();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (RewardedAd ad, RewardItem reward) {
      setState(() {
        // Video ad should be finish to get the reward amount.
        _rewardPoints += reward.amount.toInt();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Tofu(),
          ),
        );
      });
    });
    _rewardedAd = null;

    //RewardedVideoAdEvent must be loaded to show video ad thus we check and show it via listener
    //Tip: You chould show a loading spinner while waiting it to be loaded.

    //TODO: replace it with your own Admob Rewarded ID
  }

  void _initRewardedVideoAdListener() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-6925657557995580/4492775903',
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _numRewardedLoadAttempts = 0;
          flag = 1;
          setState(() {});
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _numRewardedLoadAttempts += 1;
          flag = 1;
          print('flag'+ flag.toString());
          setState(() {});
          if (_numRewardedLoadAttempts <= maxFailedLoadAttempts) {

            _initRewardedVideoAdListener();
          }
        },
      ),
    );
  }
}
