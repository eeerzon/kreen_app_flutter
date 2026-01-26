// ignore_for_file: non_constant_identifier_names, prefer_typing_uninitialized_variables, use_build_context_synchronously, deprecated_member_use

import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/constants.dart';
import 'package:kreen_app_flutter/helper/get_geo_location.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/modal/payment/state_payment_global.dart';
import 'package:kreen_app_flutter/pages/content_info/privacy_policy.dart';
import 'package:kreen_app_flutter/pages/content_info/snk_page.dart';
import 'package:kreen_app_flutter/pages/order/order_event_paid.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:path/path.dart' as path;

class TiketGlobalPage extends StatefulWidget {
  final String id_event;
  final num price_global;
  final List<String>? ids_tiket;
  final List<String>? namas_tiket;
  final List<num>? prices_tiket;
  final List<num>? prices_tiket_asli;
  final List<int> qty;
  final String? flag_samakan_input_tiket_pertama;
  final String? jenis_participant;
  final String? idUser;
  final num rateCurrency;
  final num rateCurrencyUser;

  const TiketGlobalPage({
    super.key, 
    required this.id_event, 
    required this.price_global, 
    required this.qty, 
    this.ids_tiket, 
    this.namas_tiket, 
    this.prices_tiket, 
    this.prices_tiket_asli,
    this.flag_samakan_input_tiket_pertama,
    this.jenis_participant,
    this.idUser,
    required this.rateCurrency,
    required this.rateCurrencyUser
  });

  @override
  State<TiketGlobalPage> createState() => _TiketGlobalPageState();
}

class _TiketGlobalPageState extends State<TiketGlobalPage> {
  String? langCode, currencyCode;

  bool _isLoading = true;
  bool _isFree = false;
  List<bool> _isCheckedList = [];

  late List<TextEditingController> emailControllers;
  late List<TextEditingController> nameControllers;
  late List<String?> selectedGenders;
  String? selected;
  late List<TextEditingController> phoneControllers;
  var gender;
  bool _showError = false;

  String? notLoginText, notLoginDesc, login;
  String? namaLabel, namaHint;
  String? nohpLabel, nohpHint, nohpError;
  String? cobaLagi;
  Map<String, dynamic> bahasa = {};

  bool showErrorBar = false;
  String errorMessage = '';

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  bool isValidPhone(String phone) {
    final regex = RegExp(r'^08[0-9]{8,11}$');
    return regex.hasMatch(phone);
  }
  
  Set<int> _duplicateEmailIndexes = {};
  Set<int> _duplicatePhoneIndexes = {};
  Set<int> _duplicateNameIndexes = {};

  void checkDuplicateInputs() {
    Map<String, List<int>> emailMap = {};
    Map<String, List<int>> phoneMap = {};
    Map<String, List<int>> nameMap = {};

    for (int i = 0; i < totalQty; i++) {
      final e = emailControllers[i].text.trim();
      final p = phoneControllers[i].text.trim();
      final n = nameControllers[i].text.trim();

      if (e.isNotEmpty) {
        emailMap.putIfAbsent(e, () => []).add(i);
      }

      if (p.isNotEmpty) {
        phoneMap.putIfAbsent(p, () => []).add(i);
      }

      if (n.isNotEmpty) {
        nameMap.putIfAbsent(n, () => []).add(i);
      }
    }

    Set<int> dupEmail = {};
    Set<int> dupPhone = {};
    Set<int> dupName = {};

    emailMap.forEach((key, indexes) {
      if (indexes.length > 1) dupEmail.addAll(indexes);
    });

    phoneMap.forEach((key, indexes) {
      if (indexes.length > 1) dupPhone.addAll(indexes);
    });

    nameMap.forEach((key, indexes) {
      if (indexes.length > 1) dupName.addAll(indexes);
    });

    setState(() {
      _duplicateEmailIndexes = dupEmail;
      _duplicatePhoneIndexes = dupPhone;
      _duplicateNameIndexes = dupName;
    });
  }


  late List<TextEditingController> questionControllers;
  late List<TextEditingController> answerControllers;

  late final int totalQty;
  final expandedNames = <String>[];
  List<dynamic> formTiket = [];
  List<String> ids_order_form_detail = [];
  List<String> ids_order_form_master = [];
  List<String> answers = [];

  Map<String, dynamic> event = {};
  Map<String, dynamic> detailEvent = {};
  List<dynamic> eventTiket = [];

  List<FocusNode> emailFocusNodes = [];
  List<FocusNode> nameFocusNodes = [];
  List<FocusNode> phoneFocusNodes = [];
  List<FocusNode> genderFocusNodes = [];
  List<FocusNode> indikatorFocus = [];

  @override
  void initState() {
    super.initState();
    
    totalQty = widget.qty.fold(0, (sum, item) => sum + item);
    for (int i = 0; i < widget.namas_tiket!.length; i++) {
      for (int j = 0; j < widget.qty[i]; j++) {
        expandedNames.add(widget.namas_tiket![i]);
      }
    }

    emailControllers = List.generate(totalQty, (_) => TextEditingController());
    nameControllers = List.generate(totalQty, (_) => TextEditingController());
    selectedGenders = List.generate(totalQty, (_) => null);
    phoneControllers = List.generate(totalQty, (_) => TextEditingController());
    _isCheckedList = List.generate(totalQty, (_) => false);

    emailFocusNodes = List.generate(totalQty, (_) => FocusNode());
    nameFocusNodes = List.generate(totalQty, (_) => FocusNode());
    phoneFocusNodes = List.generate(totalQty, (_) => FocusNode());
    genderFocusNodes = List.generate(totalQty, (_) => FocusNode());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _getCurrency();
      await _loadTiket();

      if (widget.price_global == 0) {
        _isFree = true;
      } else {
        _isFree = false;
      }
    });
  }

  late final genders = [
    {'label': bahasa['gender_1'], 'icon': '$baseUrl/image/male.png'},
    {'label': bahasa['gender_2'], 'icon': '$baseUrl/image/female.png'},
  ];

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();

    setState(() {
      langCode = code;
    });

    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");

    setState(() {
      bahasa = tempbahasa;
      notLoginText = bahasa['notLogin'];
      notLoginDesc = bahasa['notLoginDesc'];
      login = bahasa['login'];
      namaLabel = bahasa['nama_lengkap_label'];
      namaHint = bahasa['nama_lengkap'];
      nohpLabel = bahasa['nomor_hp_label'];
      nohpHint = bahasa['nomor_hp'];
      nohpError = bahasa['nomor_hp_error'];
      cobaLagi = bahasa['coba_lagi'];
    });
  }

  Future<void> _getCurrency() async {
    final code = await StorageService.getCurrency();
    setState(() {
      currencyCode = code;
    });
  }

  Future<void> _loadTiket() async {
    final body = {
      "id_event": widget.id_event,
    };

    final resultTiket = await ApiService.post('/event/listQuestionOrderForm', body: body, xLanguage: langCode);
    if (resultTiket == null || resultTiket['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultTiket?['message'];
      });
      return;
    }
    final List<dynamic> tempTiket = resultTiket['data'] ?? [];

    final resultEvent = await ApiService.post('/event/detail', body: body, xCurrency: currencyCode, xLanguage: langCode);
    if (resultEvent == null || resultEvent['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultEvent?['message'];
      });
      return;
    }
    final Map<String, dynamic> tempEvent = resultEvent['data'] ?? {};

    await _precacheAllImages(context, tempEvent);

    if (!mounted) return;
    if (mounted) {
      setState(() {
        formTiket = tempTiket;

        event = tempEvent;
        detailEvent = event['event'];
        eventTiket = event['event_ticket'];

        if (formTiket.isNotEmpty) {
          questionControllers = List.generate(formTiket.length, (_) => TextEditingController());
          answerControllers = List.generate(formTiket.length, (_) => TextEditingController());

          ids_order_form_detail = List.generate(formTiket.length, (_) => '');
          ids_order_form_master = List.generate(formTiket.length, (_) => '');
          answers = List.generate(formTiket.length, (_) => '');

          indikatorFocus = List.generate(formTiket.length, (_) => FocusNode());
        }

        _isLoading = false;
        showErrorBar = false;
      });
    }
  }

  Future<void> _precacheAllImages(
    BuildContext context,
    Map<String, dynamic> event,
  ) async {
    List<String> allImageUrls = [];
    
    final eventData = event['data'];
    if (eventData is List) {
      for (var item in eventData) {
        final url = item['event']['img_organizer']?.toString();
        if (url != null && url.isNotEmpty) {
          allImageUrls.add(url);
        }
      }
    }

    // Hilangkan duplikat supaya efisien
    allImageUrls = allImageUrls.toSet().toList();

    // Pre-cache semua gambar
    for (String url in allImageUrls) {
      await precacheImage(NetworkImage(url), context);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [
          _isLoading
            ? buildSkeleton()
            : buildKonten(),

          GlobalErrorBar(
            visible: showErrorBar,
            message: errorMessage,
            onRetry: () {
              _loadTiket();
            },
          ),
        ],
      ),
    );
  }

  Widget buildSkeleton() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 40,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        centerTitle: false,
        leading: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(height: 40, width: 40, color: Colors.white)
        ),
        actions: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Padding(
              padding: EdgeInsetsGeometry.all(10),
              child: Container(height: 40, width: 40, color: Colors.white),
            ) 
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.grey[200],
          padding: kGlobalPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Container(
                width: 200,
                height: 16,
                color: Colors.white,
              ),

              const SizedBox(height: 4),
              Container(
                width: 250,
                height: 14,
                color: Colors.white,
              ),

              const SizedBox(height: 12),
              Container(
                width: 100,
                height: 14,
                color: Colors.white,
              ),
              const SizedBox(height: 4),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              const SizedBox(height: 12),
              Container(
                width: 100,
                height: 14,
                color: Colors.white,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                    )
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                    )
                  ),
                ],
              ),
            ]
          ),
        ),
      ),
    );
  }

  Widget buildKonten() {
    final formatter = NumberFormat.decimalPattern("en_US");

    ids_order_form_detail.clear();
    ids_order_form_master.clear();
    num totalHarga = 0;
    num totalHargaAsli = 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(bahasa['tiket']),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SingleChildScrollView(
        padding: kGlobalPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300,),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.network(
                        detailEvent['img_organizer'],
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/img_broken.jpg',
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                          );
                        },
                      ),

                      SizedBox(width: 20,),
                      Text(
                        detailEvent['title']?.toString() ?? '-',
                      )
                    ],
                  ),

                  SizedBox(height: 10,),
                  Divider(),

                  SizedBox(height: 10,),
                  Column(
                    children: List.generate(widget.namas_tiket!.length, (index) {
                      final num price = widget.prices_tiket![index];
                      final num price_asli = widget.prices_tiket_asli![index];
                      final int qty = widget.qty[index];

                      totalHarga += price * qty;
                      totalHargaAsli += price_asli * qty;
                        
                      String hargaFormatted = '-';
                      hargaFormatted = currencyCode == null
                        ? "${detailEvent['currency']} ${formatter.format(price)}"
                        : "$currencyCode ${formatter.format(price)}";
                      if (eventTiket[index]['price'] == 0) {
                        hargaFormatted = bahasa['harga_detail'];
                      }

                      return Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${widget.namas_tiket![index]} (${widget.qty[index]}x)'
                            ),

                            Text(
                              hargaFormatted
                            )
                          ],
                        ),
                      );
                    })
                  ),
                  
                  Divider(),

                  SizedBox(height: 10,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      Text(
                        totalHarga == 0
                          ? bahasa['harga_detail']
                          : currencyCode == null
                            ? '${detailEvent['currency']} ${formatter.format(totalHarga)}'
                            : '$currencyCode ${formatter.format(totalHarga)}',
                      )
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20,),
            ...List.generate(totalQty, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300,),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bahasa['data_diri'],
                                  style: TextStyle(fontWeight: FontWeight.bold,),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  bahasa['sub_titel_2'],
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(width: 20),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.red,
                            ),
                            child: Row(
                              children: [
                                SvgPicture.network(
                                  "$baseUrl/image/ticket-white.svg",
                                  width: 17,
                                  height: 17,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "${bahasa['tiket']} ${index + 1}",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),


                      if (index != 0 && widget.flag_samakan_input_tiket_pertama == '1') ...[
                        SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _isCheckedList[index],
                              onChanged: (value) {
                                setState(() {
                                  _isCheckedList[index] = value ?? false;
                                  if (_isCheckedList[index]) {
                                    // salin data dari tiket pertama
                                    emailControllers[index].text = emailControllers[0].text;
                                    nameControllers[index].text = nameControllers[0].text;
                                    phoneControllers[index].text = phoneControllers[0].text;
                                    selectedGenders[index] = selectedGenders[0];
                                  } else {
                                    // reset data jika checkbox di-uncheck
                                    emailControllers[index].clear();
                                    nameControllers[index].clear();
                                    phoneControllers[index].clear();
                                    selectedGenders[index] = null;
                                  }
                                });
                              },
                              activeColor: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text("${bahasa['samakan_input']} ${bahasa['tiket']} 1"),
                            ),
                          ],
                        ),
                      ],

                      Divider(),
                      // input form
                      Text(
                        expandedNames[index],
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold
                        ),
                      ),

                      SizedBox(height: 10,),
                      Row(
                        children: [
                          Text(
                            "Email"
                          ),
                          Text(
                            "*", style: TextStyle(color: Colors.red)
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        focusNode: emailFocusNodes[index],
                        controller: emailControllers[index],
                        onChanged: (value) {
                          if (widget.flag_samakan_input_tiket_pertama == '0') {
                            emailControllers[index].text = value;
                            emailControllers[index].selection = TextSelection.fromPosition(
                              TextPosition(offset: value.length),
                            );
                            checkDuplicateInputs();
                          } else {
                            emailControllers[0].text = value;
                            emailControllers[0].selection = TextSelection.fromPosition(TextPosition(offset: value.length));
                            
                            for (int i = 1; i < totalQty; i++) {
                              if (_isCheckedList[i]) {
                                emailControllers[i].text = value;
                              }
                            }
                          }
                        },
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: bahasa['email_hint'],
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          errorText: _showError && !isValidEmail(emailControllers[index].text)
                            ? bahasa['error_email_1']
                            : _duplicateEmailIndexes.contains(index)
                                ? bahasa['error_email_2']
                                : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4,),
                      Text(
                          bahasa['info_email'],
                        ),
                      if (_showError && emailControllers[index].text.trim().isEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            bahasa['error_email_3'],
                            style: TextStyle(color: Colors.red),
                          ),
                        ),

                      SizedBox(height: 12,),
                      Row(
                        children: [
                          Text(
                            namaLabel!,
                          ),
                          Text(
                            "*", style: TextStyle(color: Colors.red)
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        focusNode: nameFocusNodes[index],
                        controller: nameControllers[index],
                        onChanged: (value) {
                          if (widget.flag_samakan_input_tiket_pertama == '0') {
                            nameControllers[index].text = value;
                            nameControllers[index].selection = TextSelection.fromPosition(
                              TextPosition(offset: value.length),
                            );
                            checkDuplicateInputs();
                          } else {
                            nameControllers[0].text = value;
                            nameControllers[0].selection = TextSelection.fromPosition(TextPosition(offset: value.length));
                            
                            for (int i = 1; i < totalQty; i++) {
                              if (_isCheckedList[i]) {
                                nameControllers[i].text = value;
                              }
                            }
                          }
                        },
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: namaHint,
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          errorText: _duplicateNameIndexes.contains(index)
                            ? bahasa['error_nama_1']
                            : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      if (_showError && nameControllers[index].text.trim().isEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            bahasa['error_nama_2'],
                            style: TextStyle(color: Colors.red),
                          ),
                        ),

                      SizedBox(height: 12),
                      Focus(
                        focusNode: genderFocusNodes[index],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(bahasa['gender_label']),
                                const Text("*", style: TextStyle(color: Colors.red)),
                              ],
                            ),
                            const SizedBox(height: 4),

                            Row(
                              children: List.generate(genders.length, (indx) {
                                final item = genders[indx];
                                final isSelectedGender =
                                    selectedGenders[index] == item['label'];

                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedGenders[index] = item['label'];

                                        // copy ke tiket lain jika mode samakan aktif
                                        if (index == 0) {
                                          for (int i = 1; i < totalQty; i++) {
                                            if (_isCheckedList[i]) {
                                              selectedGenders[i] = selectedGenders[0];
                                            }
                                          }
                                        }
                                      });
                                    },
                                    child: Container(
                                      height: 120,
                                      margin: EdgeInsets.only(
                                        right: indx == 0 ? 8 : 0,
                                        left: indx == 1 ? 8 : 0,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey),
                                        color: isSelectedGender
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.white,
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.network(
                                            item['icon'], 
                                            width: 50, 
                                            height: 50,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/images/img_broken.jpg',
                                                height: 50,
                                                width: 50,
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          Text(item['label']),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),

                            if (_showError && selectedGenders[index] == null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  bahasa['gender_error'],
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: 12,),
                      Row(
                        children: [
                          Text(
                            nohpLabel!,
                          ),
                          Text(
                            "*", style: TextStyle(color: Colors.red)
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        focusNode: phoneFocusNodes[index],
                        controller: phoneControllers[index],
                        onChanged: (value) {
                          setState(() {
                            if (widget.flag_samakan_input_tiket_pertama == '0') {
                              phoneControllers[index].text = value;
                              phoneControllers[index].selection = TextSelection.fromPosition(
                                TextPosition(offset: value.length),
                              );
                              checkDuplicateInputs();
                            } else {
                              phoneControllers[0].text = value;
                              phoneControllers[0].selection = TextSelection.fromPosition(
                                TextPosition(offset: value.length),
                              );

                              for (int i = 1; i < totalQty; i++) {
                                if (_isCheckedList[i]) {
                                  phoneControllers[i].text = value;
                                }
                              }
                            }
                          });
                        },
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: nohpHint!,
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          errorText: phoneControllers[index].text.isNotEmpty &&
                                  !isValidPhone(phoneControllers[index].text)
                              ? nohpError
                              : _duplicatePhoneIndexes.contains(index)
                                  ? bahasa['error_nohp_1']
                                  : null,
                          errorMaxLines: 3,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      if (_showError && phoneControllers[index].text.trim().isEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            bahasa['error_nohp_2'],
                            style: TextStyle(color: Colors.red),
                          ),
                        ),

                      SizedBox(height: 12,),
                    ],
                  ),
                ),
              );
            }),
            
            if (formTiket.isNotEmpty) ... [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300,),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formTiket[0]['title'],
                      style: TextStyle(fontWeight: FontWeight.bold,),
                    ),
                    SizedBox(height: 2),
                    Text(
                      bahasa['sub_titel_2']
                    ),

                    SizedBox(height: 20,),
                    ...List.generate(formTiket.length, (idx) {
                      ids_order_form_detail.add(formTiket[idx]['id_order_form_detail']);
                      ids_order_form_master.add(formTiket[idx]['id_order_form_master']);
                      return Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  formTiket[idx]['question']
                                ),
                                if (formTiket[idx]['required'] == 1)
                                  Text(
                                    "*", style: TextStyle(color: Colors.red)
                                  )
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (formTiket[idx]['type_form'] == 'varchar') ... [
                              TextField(
                                focusNode: indikatorFocus[idx],
                                controller: answerControllers[idx],
                                onChanged: (value) {
                                  answerControllers[idx].text = value;

                                  answers[idx] = value;
                                },
                                autofocus: false,
                                decoration: InputDecoration(
                                  hintText: bahasa['tiket_template_answer_hint'],
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              if (formTiket[idx]['required'] == 1 && _showError && answerControllers[idx].text.trim().isEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    bahasa['tiket_template_answer_error'],
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                            ] 

                            else if (formTiket[idx]['type_form'] == 'file') ... [
                              Focus(
                                focusNode: indikatorFocus[idx],
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        final result = await FilePicker.platform.pickFiles(
                                          type: FileType.any,
                                        );

                                        if (result != null && result.files.single.path != null) {
                                          final file = File(result.files.single.path!);
                                          final fileName = path.basename(file.path);
                                          final resultUpload = await ApiService.postImage('/uploads/tmp', file: file, xLanguage: langCode);
                                          final List<dynamic> tempData = resultUpload?['data'] ?? [];
                                          final storedFileName = tempData[0]['stored_as'];

                                          setState(() {
                                            answerControllers[idx].text = fileName;

                                            if (answers.length > idx) {
                                              answers[idx] = storedFileName;
                                            } else {
                                              answers.add(storedFileName);
                                            }
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                answerControllers[idx].text.isNotEmpty
                                                    ? path.basename(answerControllers[idx].text)
                                                    : bahasa['pilih_file'],
                                                style: TextStyle(
                                                  color: answerControllers[idx].text.isNotEmpty
                                                      ? Colors.black
                                                      : Colors.grey,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const Icon(Icons.upload_file, color: Colors.red),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (formTiket[idx]['required'] == 1 &&
                                        _showError &&
                                        answerControllers[idx].text.trim().isEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          bahasa['tiket_template_answer_error'],
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            ]

                            else if (formTiket[idx]['type_form'] == 'radio') ... [
                              if (formTiket[idx]['question'].contains('Jenis Kelamin')) ...[
                                Focus(
                                  focusNode: indikatorFocus[idx],
                                  child: Row(
                                    children: List.generate(genders.length, (indx) {
                                      final item = genders[indx];
                                      final bool isSelected = selected == item['label'];

                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selected = item['label'];
                                              answerControllers[idx].text = item['label'];
                                            });
                                          },
                                          child: Container(
                                            height: 120,
                                            margin: EdgeInsets.only(
                                              right: indx == 0 ? 8 : 0,
                                              left: indx == 1 ? 8 : 0,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey,
                                                width: 1,
                                              ),
                                              color: isSelected ? Colors.green.withOpacity(0.1) : Colors.white,
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Image.network(
                                                  item['icon'] as String,
                                                  width: 50,
                                                  height: 50,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Image.asset(
                                                      'assets/images/img_broken.jpg',
                                                      height: 50,
                                                      width: 50,
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  item['label']!,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                if (formTiket[idx]['required'] == 1 &&
                                        _showError &&
                                        answerControllers[idx].text.trim().isEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          bahasa['tiket_template_answer_error'],
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                              ]

                              else ...[
                                Focus(
                                  focusNode: indikatorFocus[idx],
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ...formTiket[idx]['answer']
                                          .toString()
                                          .split(',')
                                          .map((option) => RadioListTile<String>(
                                                title: Text(option.trim()),
                                                value: option.trim(),
                                                groupValue: answerControllers[idx].text,
                                                onChanged: (value) {
                                                  setState(() {
                                                    answerControllers[idx].text = value ?? '';
                                                  });
                                                },
                                                contentPadding: EdgeInsets.zero,
                                                dense: true,
                                                activeColor: Colors.red,
                                              ))
                                          ,
                                      if (formTiket[idx]['required'] == 1 &&
                                          _showError &&
                                          answerControllers[idx].text.trim().isEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Text(
                                            bahasa['tiket_template_answer_error'],
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                    ],
                                  ),
                                )
                              ]
                            ]

                            else if (formTiket[idx]['type_form'] == 'select')
                              Focus(
                                focusNode: indikatorFocus[idx],
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DropdownButtonFormField<String>(
                                      value: answerControllers[idx].text.isNotEmpty
                                          ? answerControllers[idx].text
                                          : null,
                                      items: formTiket[idx]['answer']
                                          .toString()
                                          .split(',')
                                          .map((option) => DropdownMenuItem<String>(
                                                value: option.trim(),
                                                child: Text(option.trim()),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          answerControllers[idx].text = value ?? '';
                                        });
                                      },
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                        hintText: bahasa['pilih_radio'],
                                        hintStyle: TextStyle(color: Colors.grey.shade400),
                                      ),
                                    ),
                                    if (formTiket[idx]['required'] == 1 &&
                                        _showError &&
                                        answerControllers[idx].text.trim().isEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          bahasa['tiket_template_answer_error'],
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            SizedBox(height: 12,),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300,),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(text: bahasa['kebijakan_privasi_1']),
                        TextSpan(
                            text: "KREEN ",),
                        TextSpan(
                            text:
                                bahasa['kebijakan_privasi_2']),
                        TextSpan(
                            text: bahasa['kebijakan_privasi_3'],
                            style: TextStyle(color: Colors.red),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SnkPage(),
                                  ),
                                );
                              },
                          ),
                        TextSpan(text: bahasa['kebijakan_privasi_4']),
                        TextSpan(
                            text: bahasa['kebijakan_privasi_5'],
                            style: TextStyle(color: Colors.red),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PrivacyPolicyPage(),
                                  ),
                                );
                              },
                        ),
                        TextSpan(text: bahasa['kebijakan_privasi_6']),
                      ],
                    ),
                    textAlign: TextAlign.justify,
                  ),

                  SizedBox(height: 20,),
                  InkWell(
                    onTap: () async {
                      // answers = List.generate(answerControllers.length, (index) {
                      //   return answerControllers[index].text.trim();
                      // });

                      setState(() {
                        _showError = true;
                      });

                      final isValid = _validateAllForm();

                      for (var i = 0; i < formTiket.length; i++) {
                        if (formTiket[i]['type_form'] != 'file') {
                          answers[i] = answerControllers[i].text.trim();
                        }
                      }

                      if (!isValid) {
                        return;
                      }
                      
                      if (_isFree) {
                        final position = await getCurrentLocationWithValidation(context);

                        if (position == null) {
                          // Stop, jangan lanjut submit
                          return;
                        }

                        final latitude = position.latitude;
                        final longitude = position.longitude;
                        //payment
                        String platform = Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : Platform.operatingSystem;

                        final tickets = <Map<String, dynamic>>[];
                        int controllerIndex = 0;

                        for (int i = 0; i < widget.ids_tiket!.length; i++) {
                          final idTicket = widget.ids_tiket![i];
                          final count = int.tryParse(widget.qty[i].toString()) ?? 1;

                          for (int j = 0; j < count; j++) {
                            
                            String genderValue;
                            final rawGender = selectedGenders[controllerIndex]?.toString().toLowerCase();

                            if (rawGender == 'laki-laki' || rawGender == 'male') {
                              genderValue = 'male';
                            } else if (rawGender == 'perempuan' || rawGender == 'female') {
                              genderValue = 'female';
                            } else {
                              genderValue = ''; // atau throw / handle error
                            }
                            tickets.add({
                              "id_ticket": idTicket,
                              "first_name": nameControllers[controllerIndex].text,
                              "email": emailControllers[controllerIndex].text,
                              "phone": phoneControllers[controllerIndex].text,
                              "gender" : genderValue
                            });
                            controllerIndex++;
                          }
                        }

                        final body = {
                          "id_event": widget.id_event,
                          "id_user": widget.idUser,
                          'platform': platform,
                          "latitude": latitude,
                          "longitude": longitude,
                          "tickets": tickets,
                          "payment_method": null,
                          "order_form_answers_global": List.generate(
                            ids_order_form_master.length, (index) => {
                              "id_order_form_master": ids_order_form_master[index],
                              "id_order_form_detail": ids_order_form_detail[index],
                              "answer": answers[index]
                            },
                          ),
                        };

                        var resultEventOrder = await ApiService.post("/order/event/checkout", body: body);

                        if (resultEventOrder != null) {
                          if (resultEventOrder['rc'] == 200) {
                            var tempOrder = resultEventOrder['data'];

                            var id_order = tempOrder['id_order'];
                            Navigator.pop(context);

                            Navigator.pop(context);

                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => OrderEventPaid(idOrder: id_order, isSukses: true,)),
                            );
                          } else if (resultEventOrder['rc'] == 422) {
                            final data = resultEventOrder['data'];
                            String desc = '';
                            if (data is Map) {
                              final errorMessages = data.values
                                .whereType<List>()
                                .expand((e) => e)
                                .whereType<String>()
                                .toList();

                            desc = errorMessages.join('\n');
                            } else {
                              desc = data?.toString() ?? '';
                            }
                            AwesomeDialog(
                              context: context,
                              dialogType: DialogType.error,
                              animType: AnimType.topSlide,
                              title: 'Oops!',
                              desc: desc,
                              btnOkOnPress: () {},
                              btnOkColor: Colors.red,
                              buttonsTextStyle: TextStyle(color: Colors.white),
                              headerAnimationLoop: false,
                              dismissOnTouchOutside: true,
                              showCloseIcon: true,
                            ).show();
                          }
                        } else {
                          AwesomeDialog(
                            context: context,
                            dialogType: DialogType.error,
                            animType: AnimType.topSlide,
                            title: 'Oops!',
                            desc: cobaLagi,
                            btnOkOnPress: () {},
                            btnOkColor: Colors.red,
                            headerAnimationLoop: false,
                            dismissOnTouchOutside: true,
                            showCloseIcon: true,
                          ).show();
                        }
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StatePaymentGlobal(
                              id_event: widget.id_event,
                              ids_tiket: widget.ids_tiket!, 
                              names_tiket: widget.namas_tiket!, 
                              counts_tiket: widget.qty, 
                              prices_tiket: widget.prices_tiket!, 
                              prices_tiket_asli: widget.prices_tiket_asli!,
                              totalHarga: totalHarga,
                              totalHargaAsli: totalHargaAsli,
                              first_names: nameControllers,
                              genders: selectedGenders,
                              emails: emailControllers,
                              phones: phoneControllers,
                              ids_order_form_details: ids_order_form_detail,
                              ids_order_form_master: ids_order_form_master,
                              answers: answers,
                              formGlobal: true,
                              fromDetail: true,
                              jenis_participant: widget.jenis_participant!,
                              idUser: widget.idUser,
                              rateCurrency: widget.rateCurrency,
                              rateCurrencyUser: widget.rateCurrencyUser,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.network(
                            "$baseUrl/image/ticket-white.svg",
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(width: 8),
                          Text(
                            _isFree
                            ? bahasa['pilih_tiket']
                            : bahasa['pilih_pembayaran'],
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ]
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final f in genderFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  bool _validateAllForm() {
    bool isValid = true;
    FocusNode? firstErrorFocus;

    checkDuplicateInputs();

    for (int i = 0; i < totalQty; i++) {
      // email
      if (emailControllers[i].text.trim().isEmpty ||
          !isValidEmail(emailControllers[i].text) ||
          _duplicateEmailIndexes.contains(i)) {
        isValid = false;
        firstErrorFocus ??= emailFocusNodes[i];
      }

      // nama
      if (nameControllers[i].text.trim().isEmpty ||
          _duplicateNameIndexes.contains(i)) {
        isValid = false;
        firstErrorFocus ??= nameFocusNodes[i];
      }

      // gender
      if (selectedGenders[i] == null) {
        isValid = false;
        firstErrorFocus ??= genderFocusNodes[i];
      }

      // phone
      if (phoneControllers[i].text.trim().isEmpty ||
          !isValidPhone(phoneControllers[i].text) ||
          _duplicatePhoneIndexes.contains(i)) {
        isValid = false;
        firstErrorFocus ??= phoneFocusNodes[i];
      }

      // form tiket
      for (int j = 0; j < formTiket.length; j++) {
        if (formTiket[j]['required'] == 1 &&
            answers[j].toString().trim().isEmpty) {
          isValid = false;
          firstErrorFocus ??= indikatorFocus[j];
        }
      }
    }

    if (!isValid && firstErrorFocus != null) {
      _scrollToFocus(firstErrorFocus);
      firstErrorFocus.requestFocus();
    }

    return isValid;
  }

  void _scrollToFocus(FocusNode focusNode) {
    final context = focusNode.context;
    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
  }
}