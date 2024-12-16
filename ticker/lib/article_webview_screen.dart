import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ArticleWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  ArticleWebViewScreen({required this.url, required this.title});

  @override
  _ArticleWebViewScreenState createState() => _ArticleWebViewScreenState();
}

class _ArticleWebViewScreenState extends State<ArticleWebViewScreen> {
  bool _isLoadingPage = true;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (finish) {
            setState(() {
              _isLoadingPage = false;
            });
          },
          onNavigationRequest: (request) {
            if (!request.url.startsWith('http')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title.length > 30
              ? widget.title.substring(0, 30) + '...'
              : widget.title,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoadingPage)
            Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurple,
              ),
            ),
        ],
      ),
    );
  }
}
