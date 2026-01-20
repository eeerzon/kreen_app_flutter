import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class HelpCenterSubCategoryPage extends StatefulWidget {
  final int idKategori;
  final String nameKategori;
  const HelpCenterSubCategoryPage({super.key, required this.idKategori, required this.nameKategori});

  @override
  State<HelpCenterSubCategoryPage> createState() => _HelpCenterSubCategoryPageState();
}

class _HelpCenterSubCategoryPageState extends State<HelpCenterSubCategoryPage> {
  String? langCode, search;
  bool isLoading = true;

  Map<String, dynamic> bahasa = {};
  
  List<dynamic> subKategori = [];
  Map<int, List<dynamic>> questionsBySub = {};
  List<bool> openSubKategori = [];
  Map<int, List<bool>> openQuestion = {};

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
    final resultSubKategori = await ApiService.get("/helpcenter/sub-categories/${widget.idKategori}");
    
    final tempSubKategori = resultSubKategori?['data'] ?? {};

    setState(() {
      subKategori = tempSubKategori;

      openSubKategori = List<bool>.filled(subKategori.length, false);
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
        title: Text(bahasa['pusat_bantuan']),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.nameKategori,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 16),
              ...subKategori.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300,),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              langCode == 'en'
                                ? item['en_name']
                                : item['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          SizedBox(width: 10,),
                          GestureDetector(
                            onTap: () async {
                              final idSubKategori = item['id'];
                              // openSubKategori[index] = !openSubKategori[index];
                              for (int i = 0; i < openSubKategori.length; i++) {
                                openSubKategori[i] = i == index
                                    ? !openSubKategori[i] // toggle yang diklik
                                    : false; // lainnya ditutup
                              }

                              if (!questionsBySub.containsKey(index)) {
                                final resultQuestion = await ApiService.get("/helpcenter/questions/$idSubKategori");

                                questionsBySub[index] = resultQuestion?['data'] ?? [];
                              }
                              setState(() {
                                openQuestion[index] = List<bool>.filled(questionsBySub[index]!.length, false);
                              });
                            },
                            child: !openSubKategori[index]
                            ? Icon(FontAwesomeIcons.plus, color: Colors.red, size: 20,)
                            : Icon(FontAwesomeIcons.minus, color: Colors.red, size: 20,)
                          )
                        ],
                      ),

                      if (openSubKategori[index]) ...[
                        SizedBox(height: 16),
                        ...questionsBySub[index]!.map((q) {
                          final indexx = questionsBySub[index]!.indexOf(q);
                          final title = (langCode == 'en' ? q['en_title'] : q['title'])
                            ?.toString()
                            .replaceAll('\n', ' ')
                            .trim() ?? '';
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 0, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        )
                                      ),
                                    ),

                                    SizedBox(width: 10,),
                                    GestureDetector(
                                      onTap: () {
                                        openQuestion[index]![indexx] = !openQuestion[index]![indexx];
                                        setState(() {});
                                      },
                                      child: !openQuestion[index]![indexx]
                                        ? Icon(FontAwesomeIcons.plus, color: Colors.red, size: 20,)
                                        : Icon(FontAwesomeIcons.minus, color: Colors.red, size: 20,)
                                    ),
                                  ],
                                ),
                                
                                if (openQuestion[index]![indexx]) ...[
                                  SizedBox(height: 6),
                                  Html(
                                    data: langCode == 'en'
                                      ? q['en_content']
                                      : q['content'],
                                    style: {
                                      "p": Style(
                                        margin: Margins.zero,
                                      ),
                                      "body": Style(
                                        margin: Margins.zero,
                                      ),
                                    },
                                  ),
                                ],
                              ],
                            ),
                          );
                        })
                      ]
                    ],
                  ),
                );
              })
            ],
          ),
        ),
      ),
    );
  }
}