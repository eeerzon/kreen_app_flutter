import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:kreen_app_flutter/constants.dart';
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

  Map<String, dynamic> infoLang = {};
  List<dynamic> infoKonten = [];

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

    final tempinfolang = await LangService.getJsonData(langCode!, 'info');
    setState(() {
      infoLang = tempinfolang;
    });
  }

  Future<void> _loadKonten() async {
    final resultInformasi = await ApiService.get("/information?code=pp");
    setState(() {
      infoKonten = resultInformasi?['data'] ?? [];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading ? const Center(child: CircularProgressIndicator(color: Colors.red,),) : Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(infoLang['kebijakan_privasi']),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SingleChildScrollView(
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
    );
  }
}