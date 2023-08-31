import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewContainer extends StatefulWidget {
  final String url;

  const WebViewContainer({Key? key, required this.url}) : super(key: key);
  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  late WebViewController _webViewController;
  double _loadingProgress = 0.0; // Track loading progress

  @override
  void initState() {
    super.initState();
     _webViewController = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..setBackgroundColor(const Color(0xFFEBDDFF))
  ..setNavigationDelegate(
    NavigationDelegate(
      onProgress: (int progress) {
        setState(() {
          _loadingProgress = progress / 100; // Normalize progress
        });
      },
      onPageStarted: (String url) {
        setState(() {
          _loadingProgress = 0.0; // Reset progress when page starts loading
        });
      },
      onPageFinished: (String url) {
        setState(() {
          _loadingProgress = 1.0; // Set progress to complete when page finishes loading
        });
      },
      onWebResourceError: (WebResourceError error) {},
      onNavigationRequest: (NavigationRequest request) {
        return NavigationDecision.prevent;
      },
    ),
  )
  ..loadRequest(Uri.parse(widget.url));
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBDDFF),
      appBar: AppBar(
        title: const Text("Delete Account"),
        elevation: 50,
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loadingProgress < 1.0)
              Container (
                alignment: Alignment.center, 
                child:  CircularProgressIndicator(value: _loadingProgress),
              ),
            if (_loadingProgress == 1.0)
              Expanded(
                child: WebViewWidget(
                  controller: _webViewController,
                ),
              ),
          ],
        ),
    );
  }

}
