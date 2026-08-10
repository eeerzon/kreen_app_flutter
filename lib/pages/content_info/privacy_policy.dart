import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:kreen_app_flutter/helper/global_function.dart';
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

  String? rawContent, cleanContent;

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
        errorMessage = resultInformasi?['message'] ?? '';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      infoKonten = resultInformasi['data'] ?? [];

      if (infoKonten.isEmpty) {
        rawContent = '';
      } else if (langCode == 'en') {
        rawContent = infoKonten[0]['en_content'];
      } else {
        rawContent = infoKonten[0]['content'];
      }

      // cleanContent = (rawContent ?? '')
      //   .replaceAll(RegExp(r'[\r\n]+'), '')
      //   .trim();

      cleanContent = simplifyKontenHtml(rawContent ?? '');

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
        title: Text(bahasa['kebijakan_privasi'] ?? ""),
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
                    data: cleanContent,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(14),
                        lineHeight: LineHeight.number(1.5),
                        color: Colors.black87,
                      ),
                      "h5": Style(
                        fontSize: FontSize(16),
                        fontWeight: FontWeight.bold,
                        margin: Margins.only(top: 16, bottom: 6),
                      ),
                      "h6": Style(
                        fontSize: FontSize(14),
                        fontWeight: FontWeight.bold,
                        margin: Margins.only(top: 10, bottom: 4),
                      ),
                      "ol": Style(padding: HtmlPaddings.only(left: 20), margin: Margins.only(bottom: 10)),
                      "ul": Style(padding: HtmlPaddings.only(left: 20), margin: Margins.only(bottom: 10)),
                      "li": Style(margin: Margins.only(bottom: 8), lineHeight: LineHeight.number(1.5)),
                      "p": Style(margin: Margins.only(bottom: 10), lineHeight: LineHeight.number(1.5)),
                    },
                  )
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