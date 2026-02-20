// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WidgetWebView extends StatefulWidget {
  final String header;
  final String url;

  const WidgetWebView({super.key,required this.header, required this.url});

  @override
  State<WidgetWebView> createState() => _WidgetWebViewState();
}

class _WidgetWebViewState extends State<WidgetWebView> {
  late final String url = widget.url;
  bool isLoading = true;

  late final WebViewController controller;

  // String? langCode, artikel;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // await _getBahasa();
      isLoading = false;
    });

    controller = WebViewController.fromPlatformCreationParams(
      const PlatformWebViewControllerCreationParams(),
    );

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(false)
      ..setUserAgent(
        "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() => isLoading = true);
          },
          onPageFinished: (_) async {
            setState(() => isLoading = false);

            await controller.runJavaScript("""
              window.localStorage;
              window.sessionStorage;
            """);
          },
          onWebResourceError: (_) {
            setState(() => isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  // Future<void> _getBahasa() async {
  //   final code = await StorageService.getLanguage();
  //   setState(() => langCode = code);

  //   final tempArtikel = await LangService.getJsonData(langCode!, "bahasa");
  //   setState(() {
  //     artikel = tempArtikel['artikel'];
  //     isLoading = false;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await controller.canGoBack()) {
          controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          scrolledUnderElevation: 0,
          title: Text(widget.header),
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: kGlobalPadding,
                child: Column(
                  children: [
                    Expanded(child: WebViewWidget(controller: controller)),
                  ],
                ),
              ),
              
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.red,),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
