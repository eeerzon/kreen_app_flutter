import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:kreen_app_flutter/helper/constants.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  String? langCode;
  bool isLoading = true;

  Map<String, dynamic> bahasa = {};
  List<dynamic> infoKonten = [];

  bool showErrorBar = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _loadKonten();
    });
  }

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();
    setState(() => langCode = code);

    final tempbahasa = await LangService.getJsonData(langCode!, 'bahasa');
    setState(() {
      bahasa = tempbahasa;
    });
  }

  Future<void> _loadKonten() async {
    final resultInformasi = await ApiService.get("/information?code=pp", xLanguage: langCode);
    if (resultInformasi == null || resultInformasi['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultInformasi?['message'];
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      infoKonten = resultInformasi?['data'] ?? [];
      isLoading = false;
      showErrorBar = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(bahasa['kebijakan_privasi']),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: Stack(
        children: [
          isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.red,))
            : SingleChildScrollView(
                child: Container(
                  color: Colors.white,
                  padding: kGlobalPadding,
                  child: Html(
                    data: langCode == 'en'
                      ? infoKonten[0]['en_content']
                      : infoKonten[0]['content'],
                  ),
                ),
              ),

          GlobalErrorBar(
            visible: showErrorBar, 
            message: errorMessage, 
            onRetry: () {
              _loadKonten();
            }
          )
        ],
      ),
    );
  }
}