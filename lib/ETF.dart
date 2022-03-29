import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
class ETF extends StatefulWidget {
  const ETF({Key? key}) : super(key: key);

  @override
  _ETFState createState() => _ETFState();
}

class _ETFState extends State<ETF> {
  final Completer<WebViewController> webController =
  Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebView(
          initialUrl: 'https://www.stockstorage.net/etf',
          onWebViewCreated: (WebViewController _controller) async {
            webController.isCompleted
                ? ''
                : webController.complete(_controller);
          },
          javascriptMode: JavascriptMode.unrestricted,
        ))
    );

  }
}
