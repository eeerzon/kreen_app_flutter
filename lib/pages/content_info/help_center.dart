import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/pages/content_info/help_center_sub_category.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  String? langCode, search;
  bool isLoading = true;

  Map<String, dynamic> bahasa = {};

  List<dynamic> kategori = [];
  List<dynamic> subKategori = [];
  List<dynamic> question = [];
  List<dynamic> popularFAQ = [];
  List<bool> openQuestion = [];

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
      search = bahasa['search'];
    });
  }

  Future<void> _loadKonten() async {
    final resultKategori = await ApiService.get("/helpcenter/categories", xLanguage: langCode);
    if (resultKategori == null || resultKategori['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultKategori?['message'] ?? '';
      });
      return;
    }

    final resultPopular = await ApiService.get("/helpcenter/popular-faqs", xLanguage: langCode);
    if (resultPopular == null || resultPopular['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultPopular?['message'] ?? '';
      });
      return;
    }
    
    final tempKategori = resultKategori['data'] ?? {};
    final tempPopular = resultPopular['data'] ?? [];

    if (!mounted) return;
    setState(() {
      kategori = tempKategori;
      popularFAQ = tempPopular;

      openQuestion = List<bool>.filled(popularFAQ.length, false);
      isLoading = false;
      showErrorBar = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          isLoading
            ? _buildSkeleton()
            : _buildKonten(),

          GlobalErrorBar(
            visible: showErrorBar,
            message: errorMessage,
            onRetry: () {
              _loadKonten();
            },
          ),
        ],
      ), 

    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: kGlobalPadding,
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search skeleton
            _skeletonBox(height: 48, radius: 12),

            const SizedBox(height: 24),

            // Kategori title
            _skeletonBox(width: 160, height: 16),

            const SizedBox(height: 16),

            // Kategori list
            ...List.generate(4, (_) => _skeletonKategori()),

            const SizedBox(height: 16),

            // FAQ title
            _skeletonBox(width: 180, height: 16),

            const SizedBox(height: 16),

            // FAQ list
            ...List.generate(4, (index) => _skeletonFaq(index)),
          ],
        ),
      )
    );
  }

  Widget _skeletonBox({
    double width = double.infinity,
    double height = 12,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _skeletonKategori() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          _skeletonBox(width: 24, height: 24, radius: 4),
          const SizedBox(width: 16),
          Expanded(
            child: _skeletonBox(height: 14),
          ),
        ],
      ),
    );
  }

  Widget _skeletonFaq(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skeletonBox(width: 20, height: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonBox(height: 14),
                if (index.isEven) ...[
                  const SizedBox(height: 8),
                  _skeletonBox(height: 12, width: 250),
                  const SizedBox(height: 6),
                  _skeletonBox(height: 12, width: 200),
                ]
              ],
            ),
          ),
          const SizedBox(width: 8),
          _skeletonBox(width: 16, height: 16, radius: 4),
        ],
      ),
    );
  }

  Widget _buildKonten() {
    return Scaffold(
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
      
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            padding: kGlobalPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // search bar
                // TextField(
                //   decoration: InputDecoration(
                //     hintText: search,
                //     hintStyle: TextStyle(color: Colors.grey.shade400),
                //     prefixIcon: Icon(Icons.search),
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //   ),
                //   onChanged: (value) {
                //     // _loadContent(false, value);
                //     setState(() {
                //       // buildKonten();
                //     });
                //   },
                // ),

                //konten
                SizedBox(height: 16),
                Text(
                  bahasa['kategori_informasi'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 16),
                ...kategori.asMap().entries.map((entry) {
                  final item = entry.value;

                  return GestureDetector(
                    onTap: () {
                      final idKategori = item['id'];
                      Navigator.push(context, 
                        MaterialPageRoute(
                          builder: (context) => HelpCenterSubCategoryPage(
                            idKategori: idKategori, 
                            nameKategori: langCode == 'en' 
                              ? item['en_name'] 
                              : item['name'],
                          ),
                        )
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300,),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (item['icon'] == 'search') ... [
                            SvgPicture.network(
                              '$baseUrl/image/search-gradient.svg',
                              width: 24,
                              height: 24,
                            ),
                          ] else if (item['icon'] == 'customer') ... [
                            SvgPicture.network(
                              '$baseUrl/image/customer-gradient.svg',
                              width: 24,
                              height: 24,
                            ),
                          ] else if(item['icon'] == 'eo') ... [
                            SvgPicture.network(
                              '$baseUrl/image/eo-gradient.svg',
                              width: 24,
                              height: 24,
                            ),
                          ] else if(item['icon'] == 'event') ... [
                            SvgPicture.network(
                              '$baseUrl/image/event-gradient.svg',
                              width: 24,
                              height: 24,
                            ),
                          ] else if(item['icon'] == 'vote') ... [
                            SvgPicture.network(
                              '$baseUrl/image/vote-gradient.svg',
                              width: 24,
                              height: 24,
                            ),
                          ],
                  
                          SizedBox(width: 16,),
                          Text(
                            langCode == 'en'
                            ? item['en_name']
                            : item['name']
                          )
                        ],
                      ),
                    )
                  );
                }),
                
                Text(
                  bahasa['pertanyaan_populer'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 16,),
                ...popularFAQ.asMap().entries.map((entry) {
                  final indexKat = entry.key;
                  final itemKat = entry.value;

                  return GestureDetector(
                    onTap: () {
                      openQuestion[indexKat] = !openQuestion[indexKat];
                      setState(() {});
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${indexKat + 1}. ',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Expanded(
                                      child: Text(
                                        langCode == 'en'
                                            ? itemKat['en_title']
                                            : itemKat['title'],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(width: 10,),
                              GestureDetector(
                                onTap: () {
                                  openQuestion[indexKat] = !openQuestion[indexKat];
                                  setState(() {});
                                },
                                child: !openQuestion[indexKat]
                                ? Icon(FontAwesomeIcons.plus, color: Colors.red, size: 20,)
                                : Icon(FontAwesomeIcons.minus, color: Colors.red, size: 20,)
                              )
                            ],
                          ),

                          if (openQuestion[indexKat]) ... [
                            Html(
                              data: 
                                langCode == 'en'
                                ? itemKat['en_content']
                                : itemKat['content'],
                              style: {
                                "p": Style(
                                  margin: Margins.only(left: 12),
                                ),
                                "body": Style(
                                  margin: Margins.only(left: 12),
                                ),
                              },
                            ),
                          ]
                        ],
                      ),
                    ),
                  );
                }),
              ]  
            ),
          ),
        ),
      ),
    );
  }

}