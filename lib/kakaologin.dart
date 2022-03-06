import 'dart:convert';

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dropdown_alert/alert_controller.dart';
import 'package:flutter_dropdown_alert/model/data_alert.dart';
import 'package:kakao_flutter_sdk/all.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stockdiary/HomePage.dart';
import 'package:stockdiary/Password.dart';
import 'package:stockdiary/setID.dart';

class LoginResult extends StatefulWidget {
  @override
  _LoginResultState createState() => _LoginResultState();
}

class _LoginResultState extends State {
  bool _isLoading = false;
  TextEditingController passwordController = TextEditingController();
  TextEditingController nicknameController = TextEditingController();
  TextEditingController passwordConfirmController = TextEditingController();
  String _accountEmail = 'None';

  var _userid = 'None';

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    checkAccount(_accountEmail);
    print(_accountEmail);
  }

  String sentence = "로그인중입니다";

  checkAccount(String username) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    final User user = await UserApi.instance.me();
    setState(() {
      _accountEmail = user.kakaoAccount!.email.toString();
      _userid = user.id.toString();
    });

    Map body = {
      "username": _userid,
    };
    var responsee =
        await http.post(Uri.http("13.209.87.55", "signup/"), body: body);

    var imsilogin = await http.post(
        Uri.http("13.209.87.55", "api/v2/auth/token/login/"),
        body: {"username": _userid, "password": '1234'});
    if (imsilogin.statusCode == 200) {
      var jsonDataa = json.decode(imsilogin.body);
      var tokenn = jsonDataa['auth_token'];
      var userresponse = await http.get(
          Uri.http("13.209.87.55", "api/v2/auth/users/me"),
          headers: {"Authorization": "Token ${tokenn}"});
      var user = jsonDecode(utf8.decode(userresponse.bodyBytes));
      print(user);

      setState(() {
        sharedPreferences.setString("token", tokenn);
        sharedPreferences.setString("nickname", user['first_name'].toString());
        sharedPreferences.setInt('userID', user['id']);

        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (BuildContext context) => HomePage()),
            (Route<dynamic> route) => false);
        AlertController.show(
          "로그인 성공",
          "이제 댓글, 좋아요 기능을 사용할 수 있어요  ",
          TypeAlert.success,
        );
      });
    } else {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => InputPassword(userID: _userid)));
    }
  }

  Widget successText() {
    return Text(sentence);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: successText(),
        ),
      ),
    );
  }
}

class KakaoRegister extends StatefulWidget {
  @override
  _KakaoRegisterState createState() => _KakaoRegisterState();
}

class _KakaoRegisterState extends State<KakaoRegister> {
  TextEditingController passwordController = TextEditingController();
  TextEditingController nicknameController = TextEditingController();
  TextEditingController passwordConfirmController = TextEditingController();
  late String? _accountEmail;

  CheckKakao() async {
    final User user = await UserApi.instance.me();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    setState(() {
      _accountEmail = user.kakaoAccount!.email;
    });
  }

  @override
  void initState() {
    super.initState();
    nicknameController = TextEditingController();
    CheckKakao();
  }

  signin(String nickname) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var token = sharedPreferences.getString("token");
    print(nickname);
    if (nickname == '') {
      nickname = '${sharedPreferences.getInt('userID')}번째가입자';
    }
    Map data = {"first_name": nickname};
    var response = await http.patch(
        Uri.http("13.209.87.55",
            "api/v1/AuthUser/${sharedPreferences.getInt('userID')}/"),
        body: data,
        headers: {"Authorization": "Token ${token}"});
    print('닉' + response.body);
    if (response.statusCode == 200) {
      await sharedPreferences.setString("nickname", nickname);
      Navigator.pop(context);
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('카카오 가입 성공'),
              content: Text("닉네임을 성공적으로 등록했습니다 '${nickname}' "),
              actions: [
                FlatButton(
                    onPressed: () {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => HomePage()));
                    },
                    child: Text('확인')),
              ],
            );
          });
    } else
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('닉네임 중복'),
              content: Text("닉네임이 중복되었습니다 '${nickname}' "),
              actions: [
                FlatButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('확인')),
              ],
            );
          });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Text(
                '카카오계정으로 가입중입니다',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 50),
              Text(
                '닉네임을 설정해주세요',
              ),
              Container(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: TextField(
                  maxLength: 10,
                  inputFormatters: [
                    new FilteringTextInputFormatter.allow(
                        RegExp('[a-zA-Z0-9ㄱ-ㅎ가-힣ㆍᆢ]')),
                  ],
                  controller: nicknameController,
                  decoration: InputDecoration(
                    hintText: '(한글 영어 숫자 가능, 10자 이내)',
                    border: OutlineInputBorder(),
                    labelText: '닉네임',
                  ),
                ),
              ),
              Text('설정하지 않을 시 자동으로 생성됩니다'),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  // foreground
                ),
                child: Text('완료'),
                onPressed: () {
                  signin(nicknameController.text);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
