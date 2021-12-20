import 'dart:ui';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'package:back_button_interceptor/back_button_interceptor.dart';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockdiary/TagPost.dart';
import 'package:stockdiary/TagPostList.dart';
import 'package:stockdiary/writerpost.dart';

import 'HomePage.dart';

class allDetail extends StatefulWidget {
  final int index;

  const allDetail({Key? key, required this.index})
      : super(key: key); //index = 게시물 번호
  @override
  _allDetailState createState() => _allDetailState();
}

class _allDetailState extends State<allDetail>
    with AutomaticKeepAliveClientMixin<allDetail> {
  @override
  bool get wantKeepAlive => true;
  late Timer _timer;

  int _timerCount = 0;

  late Map commentmap;
  late Map postlistmap;
  var comment;
  var postlist;
  var sharedPreferences;
  var token;
  var userid;
  var likecount;
  late Future _future;
  var username;
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  var pushtoken;
  var postowner;
  var blockid;
  checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();
    blockid = sharedPreferences.getStringList("blockid");
    if (sharedPreferences.getString("token") != null) {
      username = sharedPreferences.getString("nickname");
      userid = sharedPreferences.getInt("userID");
      token = sharedPreferences.getString("token");

    }
  }

  final TextEditingController commentController = TextEditingController();
  Map content = {};
  ScrollController _sc = new ScrollController();

  Future<void> doLikes() async {
    final likeresponse = await http.post(
        Uri.http('13.125.62.90', "api/v1/BlogPostsLikes/"),
        headers: {
          "Authorization": "Token ${token}",
          "Content-Type": "application/json"
        },
        body: jsonEncode(<String, int>{
          'post': widget.index.toInt(),
          'user': sharedPreferences.getInt("userID")!.toInt(),
        }));



    if (likeresponse.statusCode == 400) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('추천 취소'),
            content: Text('추천을 취소하시겠습니까?'),
            actions: [
              FlatButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Container(child: CircularProgressIndicator()),
                      );
                    }
                  );
                  final likeresponsee = await http.get(
                    Uri.http('13.125.62.90', "api/v1/BlogPostsLikes/", {
                      "user": "${sharedPreferences.getInt("userID")}",
                      "post": "${widget.index}"
                    }),
                    headers: {
                      "Authorization": "Token ${token}",
                      "Content-Type": "application/json"
                    },
                  );
                  likecount = likecount - 1;
                  var a = jsonDecode(likeresponsee.body);

                  final likeresponseee = await http.delete(
                    Uri.http('13.125.62.90', "api/v1/BlogPostsLikes/${a[0]['id']}/"),
                    headers: {
                      "Authorization": "Token ${token}",
                      "Content-Type": "application/json"
                    },
                  );
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('예'),
              ),
              FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('아니오')),
            ],
          );
        },
      );

    }
    else     likecount = likecount + 1;
  }

  Future detaillog() async {
    await analytics.setCurrentScreen(
      screenName: '게시물' + widget.index.toString(),
    );
  } //앱

  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: 'ca-app-pub-6925657557995580/9774647854',
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
    print('s');
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      print('null');
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

  @override
  initState() {
    super.initState();
    _createInterstitialAd();
    _timer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      _timerCount++;
    });
    checkLoginStatus();
    detaillog();
    _future = getPostData(widget.index, content);
    BackButtonInterceptor.add(myInterceptor);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    _sc.dispose();
    _timer.cancel();

    commentController.dispose();
    super.dispose();
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    Navigator.pop(context);
    if (_timerCount > 10) _showInterstitialAd();

    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    FocusScopeNode currentFocus = FocusScope.of(context);
    return new WillPopScope(
      onWillPop: () async {
        if (_timerCount > 10) {
          _showInterstitialAd();
        }
        Navigator.pop(context);
        return false;
      },
      child: GestureDetector(
        onTap: () {
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {

            if (snapshot.hasError)
              return Scaffold(body: Center(child: Text('게시물이 존재하지 않습니다')));
            else if (!snapshot.hasData)
              return Scaffold(
                body: Center(
                    child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.amber),
                )),
              );
            else {
              final restaurant = snapshot.data as Map;
              if (likecount == null) likecount = restaurant['likes'];
              return Scaffold(
                appBar: AppBar(
                  backgroundColor: Color.fromRGBO(122, 154, 130, 1),
                  iconTheme: IconThemeData(
                    color: Colors.white,
                  ),
                  title: Text(
                    restaurant['title'],
                    style: TextStyle(color: Colors.white),
                  ),
                  actions: [
                    PopupMenuButton<int>(
                      onSelected: (result) async {
                        if (result == 0) {
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('삭제'),
                                content: Text('게시물 삭제하시겠습니까?'),
                                actions: [
                                  FlatButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();

                                      await http.delete(
                                        Uri.http('13.125.62.90',
                                            'api/v1/BlogPosts/${widget.index}/'),
                                        headers: {
                                          "Authorization": "Token $token",
                                          "Content-Type": "application/json"
                                        },
                                      );
                                    },
                                    child: Text('예'),
                                  ),
                                  FlatButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('아니오')),
                                ],
                              );
                            },
                          );
                        } else if (result == 2) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => WriterPost(
                                      userID: restaurant['owner'],
                                      nickname: restaurant['writer'])));
                        }
                        else if (result ==3) {
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('작성자 차단'),
                                content: Text('해당 회원 게시물을 볼 수 없게 됩니다\n작성자를 차단하겠습니까?'),
                                actions: [
                                  FlatButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      var blocklist =sharedPreferences.getStringList('blockid');
                                      blocklist.add(restaurant['writer']);
                                      sharedPreferences.setStringList('blockid', blocklist);
                                      Navigator.pop(context);
                                      Navigator.pushReplacement(context,
                                          MaterialPageRoute(builder: (context) => HomePage()));
                                      setState(() {

                                      });
                                    },
                                    child: Text('예'),
                                  ),
                                  FlatButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('아니오')),
                                ],
                              );
                            },
                          );
                        }
                        else if (result ==4) {
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('작성자 신고'),
                                content: Text('해당 회원을 관리자에게 신고합니다\n작성자를 신고하시겠습니까?'),
                                actions: [
                                  FlatButton(
                                    onPressed: () async {

                                      Navigator.pop(context);

                                      setState(() {

                                      });
                                    },
                                    child: Text('예'),
                                  ),
                                  FlatButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('아니오')),
                                ],
                              );
                            },
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        if (restaurant['id'] == restaurant['owner'])
                          PopupMenuItem(
                            value: 0,
                            child: Text(
                              "게시물 삭제",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        PopupMenuItem(
                          value: 2,
                          child: Text(
                            "작성자 게시물 더보기",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        if(restaurant['id'] != restaurant['owner'])
                          PopupMenuItem(
                            value:3,
                            child: Text("작성자 차단", style: TextStyle(color:Colors.red, fontWeight: FontWeight.w700)),
                          ),
                        if(restaurant['id'] != restaurant['owner'])
                        PopupMenuItem(
                          value: 4,
                          child: Text(
                            "작성자 신고",
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w700),
                          ),
                        ),


                      ],
                      icon: Icon(Icons.menu, color: Colors.white),
                      offset: Offset(0, 20),
                    ),

                  ],
                ),
                body: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          controller: _sc,
                          children: [
                            Container(
                              padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    //제목&작성자
                                    margin: EdgeInsets.fromLTRB(3, 3, 3, 3),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          width: 3, color: Colors.black38),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20.0)),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: ListTile(
                                                contentPadding:
                                                    EdgeInsets.all(0),
                                                leading: Icon(
                                                    Icons.person_outline,
                                                    size: 40),
                                                title:
                                                    Text(restaurant['writer']),
                                                subtitle: Row(
                                                  children: [
                                                    Text(restaurant['time']),
                                                    SizedBox(
                                                      width: 10,
                                                      height: 20,
                                                    ),
                                                    Icon(Icons.thumb_up,
                                                        size: 13,
                                                        color: Colors.red),
                                                    LikeCount(likecount),
                                                    SizedBox(width: 10),
                                                    Icon(Icons.comment,
                                                        size: 13,
                                                        color: Colors.red),
                                                    Text(
                                                        restaurant['comment']
                                                            .toString(),
                                                        style: TextStyle(
                                                            color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (restaurant['token'] !=
                                                null) //추천버튼
                                              Container(
                                                  margin: EdgeInsets.fromLTRB(
                                                      0, 0, 10, 0),
                                                  child: OutlinedButton(


                                                    onPressed: () async {
                                                      await doLikes();
                                                      setState(() {});
                                                    },
                                                    child: Icon(
                                                      Icons.thumb_up,
                                                      size: 15,
                                                      color: Colors.redAccent,
                                                    ),

                                                  )),
                                          ],
                                        ),
                                        titleText(restaurant['title'], context),
                                      ],
                                    ),
                                  ),

                                  //댓글 리스트
                                ],
                              ),
                            ),
                            SizedBox(height: 20,),
                            contentText(restaurant['content']),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  if (restaurant['taggittaggeditem_set']
                                      .toString() !=
                                      '[]')
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      margin:
                                      EdgeInsets.fromLTRB(0, 0, 3, 0),
                                      decoration: BoxDecoration(
                                          color: Colors.blueAccent,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      child: Text(
                                        '연관 종목',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                    ),
                                  for (Map i in restaurant['taggittaggeditem_set'])
                                    Container(
                                      child: TextButton(
                                        child: Text(
                                          i['name'] + '  ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => StoragePost(tag: i['name'])));
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              child: Row(
                                children: [
                                  SizedBox(
                                    height: 50,
                                    width: 5,
                                  ),
                                  Icon(Icons.comment, color: Colors.red),
                                  Text(
                                    '댓글',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  Text(
                                    '(${restaurant['comment'].toString()})',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            for (var i in restaurant[
                                'blogpostcomment_set'])
                              if (blockid.contains(i['user']) == false)
                              Container(
                                padding: EdgeInsets.fromLTRB(3, 10, 3, 10),
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(width: 0.1))),
                                child: Column(
                                  children: [

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(children: [
                                          if (i['user'] == '두부개미')
                                            Icon(Icons.star),
                                          Text(
                                            i['user'],
                                            style: TextStyle(

                                                fontWeight:
                                                    FontWeight.bold, fontFamily: 'Strong'),
                                          ),
                                        ]),

                                        Row(
                                          children: [
                                            Text(i!['time'],
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 10)),
                                            Container(
                                              height:30,
                                              child: PopupMenuButton<int>(
                                                onSelected: (result) async {
                                                  if (result == 0) {
                                                    await showDialog(
                                                        context: context,
                                                        builder:
                                                            (BuildContext
                                                        context) {
                                                          return AlertDialog(
                                                            title:
                                                            Text('삭제'),
                                                            content: Text(
                                                                '댓글을 삭제하시겠습니까?'),
                                                            actions: [
                                                              FlatButton(
                                                                onPressed:
                                                                    () async {
                                                                  var response =
                                                                  await http
                                                                      .delete(
                                                                    Uri.http(
                                                                        '13.125.62.90',
                                                                        'api/v1/BlogPostcomment/${i['id']}/'),
                                                                    headers: {
                                                                      "Authorization":
                                                                      "Token ${restaurant['token']}",
                                                                      "Content-Type":
                                                                      "application/json"
                                                                    },
                                                                  );
                                                                  setState(
                                                                          () {
                                                                        _future = getPostData(
                                                                            widget.index,
                                                                            content);
                                                                      });
                                                                  Navigator.of(
                                                                      context)
                                                                      .pop();
                                                                },
                                                                child: Text(
                                                                    '예'),
                                                              ),
                                                              FlatButton(
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(context)
                                                                        .pop();
                                                                  },
                                                                  child: Text(
                                                                      '아니오')),
                                                            ],
                                                          );
                                                        });
                                                  } else if (result == 2) {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) => WriterPost(
                                                                userID: i['writer'],
                                                                nickname: i['user'])));
                                                  }
                                                  else if (result ==3) {
                                                    await showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return AlertDialog(
                                                          title: Text('작성자 차단'),
                                                          content: Text('해당 회원 게시물, 댓글을 볼 수 없게 됩니다\n작성자를 차단하겠습니까?'),
                                                          actions: [
                                                            FlatButton(
                                                              onPressed: () async {
                                                                Navigator.of(context).pop();
                                                                var blocklist =sharedPreferences.getStringList('blockid');
                                                                blocklist.add(i['user']);
                                                                sharedPreferences.setStringList('blockid', blocklist);
                                                                Navigator.pop(context);

                                                                setState(() {

                                                                });
                                                              },
                                                              child: Text('예'),
                                                            ),
                                                            FlatButton(
                                                                onPressed: () {
                                                                  Navigator.of(context).pop();
                                                                },
                                                                child: Text('아니오')),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  }
                                                  else if (result ==4) {
                                                    await showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return AlertDialog(
                                                          title: Text('작성자 신고'),
                                                          content: Text('해당 회원을 관리자에게 신고합니다\n작성자를 신고하시겠습니까?'),
                                                          actions: [
                                                            FlatButton(
                                                              onPressed: () async {

                                                                Navigator.pop(context);

                                                                setState(() {

                                                                });
                                                              },
                                                              child: Text('예'),
                                                            ),
                                                            FlatButton(
                                                                onPressed: () {
                                                                  Navigator.of(context).pop();
                                                                },
                                                                child: Text('아니오')),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  if (i['writer'] ==
                                                      restaurant['id'])
                                                    PopupMenuItem(
                                                      value: 0,
                                                      child: Text(
                                                        "댓글 삭제",
                                                        style: TextStyle(
                                                            color: Colors.black,
                                                            fontWeight: FontWeight.w700),
                                                      ),
                                                    ),
                                                  PopupMenuItem(
                                                    value: 2,
                                                    child: Text(
                                                      "댓글 작성자 게시물 더보기",
                                                      style: TextStyle(
                                                          color: Colors.black,
                                                          fontWeight: FontWeight.w700),
                                                    ),
                                                  ),
                                                  if (i['writer'] !=
                                                      restaurant['id'])
                                                    PopupMenuItem(
                                                      value:3,
                                                      child: Text("작성자 차단", style: TextStyle(color:Colors.red, fontWeight: FontWeight.w700)),
                                                    ),
                                                  if (i['writer'] !=
                                                      restaurant['id'])
                                                    PopupMenuItem(
                                                      value: 4,
                                                      child: Text(
                                                        "작성자 신고",
                                                        style: TextStyle(
                                                            color: Colors.red,
                                                            fontWeight: FontWeight.w700),
                                                      ),
                                                    ),


                                                ],
                                                icon: Icon(CupertinoIcons.ellipsis_vertical, color: Colors.black, size: 15,),
                                                offset: Offset(0, 20),
                                              ),
                                            ),


                                          ],
                                        )
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        i['content'],
                                      ),
                                    ),

                                  ],
                                ),
                              )
                          ],
                        ),
                      ),
                      if (restaurant['token'] != null)
                        Container(
                          //댓글달기
                          child: Column(
                            children: [
                              new Padding(padding: EdgeInsets.only(top: 5.0)),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                      margin: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(color: Colors.blue),
                                      ),
                                      child: TextField(
                                        controller: commentController,
                                        keyboardType: TextInputType.multiline,
                                        maxLines: null,
                                        autofocus: false,
                                        decoration: InputDecoration(
                                          hintText: "댓글을 입력해주세요",
                                          suffixIcon: IconButton(
                                            onPressed: () {
                                              postComment(
                                                  commentController.text);
                                              commentController.clear();
                                              currentFocus.unfocus();
                                            },
                                            icon: Icon(Icons.send),
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<Map> getPostData(int postId, Map content) async {
    final response = await http.get(
      Uri.http('13.125.62.90', "api/v1/BlogPosts/${postId}/"),
    ); //게시물 가져오기

    if (response.statusCode == 200) {
      // 만약 서버가 OK 응답을 반환하면, JSON을 파싱합니다.
      content = jsonDecode(utf8.decode(response.bodyBytes));
      content['time'] =
          DateFormat("M월dd일 H:m").format(DateTime.parse(content['create_dt']));
      if (token != null) {
        content['id'] = sharedPreferences.getInt("userID");
        content['token'] = token;
      }
      for (var i in content['blogpostcomment_set']) {
        i['time'] =
            DateFormat("M월dd일 H:m").format(DateTime.parse(i['created']));
      }
      postowner = content['owner'];
      pushtoken = content['pushtoken'];
      print(content['taggittaggeditem_set']);
      return content;
    } else {
      // 만약 응답이 OK가 아니면, 에러를 던집니다.
      throw Exception('Failed to load post');
    }
  }

  Widget titleText(String title, BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> postComment(String comment) async {
    var formatter = new DateFormat('yyyy-MM-dd H:m');
    var now = new DateTime.now();
    final likeresponse = await http.post(
        Uri.http('13.125.62.90', "api/v1/BlogPostcomment/"),
        headers: {
          "Authorization": "Token ${token}",
          "Content-Type": "application/json"
        },
        body: jsonEncode(<String, dynamic>{
          'blogpost_connected': widget.index.toInt(),
          'writer': sharedPreferences.getInt("userID"),
          'created': formatter.format(now),
          'updated': formatter.format(now),
          'content': comment
        }));

    _future = getPostData(widget.index, content);

    if (postowner != userid)
      await http.get(Uri.http('13.125.62.90', 'push/$pushtoken/$comment'));
    setState(() {});

    Timer(Duration(milliseconds: 500), () {
      _sc.jumpTo(_sc.position.maxScrollExtent);
    });
  }

  Widget contentText(String content) {
    return Container(
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: Colors.black26,
                  width: 1,
                  style: BorderStyle.solid))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 20),
        child: HtmlWidget(
          content,
        ),
      ),
    );
  }

  Widget LikeCount(int like) {
    //추천 갯수 업데이트하기위함
    return Text(
      like.toString(),
      style: TextStyle(color: Colors.red),
    );
  }


}
