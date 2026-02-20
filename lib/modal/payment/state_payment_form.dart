// ignore_for_file: non_constant_identifier_names, prefer_typing_uninitialized_variables, use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/helper/get_geo_location.dart';
import 'package:kreen_app_flutter/helper/get_fee_new.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/helper/payment/payment_item.dart';
import 'package:kreen_app_flutter/modal/payment/payment_list.dart';
import 'package:kreen_app_flutter/pages/order/waiting_order_event.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class StatePaymentForm extends StatefulWidget {
  final String id_event;
  final List<String> ids_tiket;
  final List<String> names_tiket;
  final List<int> counts_tiket;
  final List<num> prices_tiket;
  final List<num> prices_tiket_asli;
  final num totalHarga;
  final num totalHargaAsli;
  final List<TextEditingController> first_names;
  final List<String?> genders;
  final List<TextEditingController> emails;
  final List<TextEditingController> phones;
  final List<List<String>> ids_order_form_details;
  final List<List<String>> ids_order_form_master;
  final List<List<String>> answers;
  final bool formGlobal;
  final bool fromDetail;
  final String jenis_participant;
  final String? idUser;
  final num rateCurrency;
  final num rateCurrencyUser;

  const StatePaymentForm({
    super.key,
    
    required this.id_event,
    required this.ids_tiket,
    required this.names_tiket,
    required this.counts_tiket,
    required this.prices_tiket,
    required this.prices_tiket_asli,
    required this.totalHarga,
    required this.totalHargaAsli,
    required this.first_names,
    required this.genders,
    required this.emails,
    required this.phones,
    required this.ids_order_form_details,
    required this.ids_order_form_master,
    required this.answers,
    required this.formGlobal,
    required this.fromDetail,
    required this.jenis_participant,
    this.idUser,
    required this.rateCurrency,
    required this.rateCurrencyUser
  });

  @override
  State<StatePaymentForm> createState() => _StatePaymentFormState();
}

class _StatePaymentFormState extends State<StatePaymentForm> {
  var get_user;
  var user_id;
  var first_name;
  var last_name;
  var gender;
  var phone;
  var email;

  String? inputNama;
  
  Map<String, dynamic> detailEvent = {};
  Map<String, dynamic> payment = {};
  String? eventCurrency;
  var totalPayment, feeLayanan;

  String? id_payment_method, mobile_number, id_card_number, card_number, expiry_month, expiry_year, cvv;

  String? selectedGender;

  late List<TextEditingController> answerControllers;
  
  int? selectedIndex;

  late final formatter = NumberFormat.currency(
    locale: "en_US",
    symbol: "",
    decimalDigits: currencyCode == "IDR" ? 0 : 2,
  );
  final ScrollController _scrollController = ScrollController();
  final TextEditingController expDateController = TextEditingController();
  bool _isEditing = false;

  bool isLoading = true;

  String? langCode, token;
  Map<String, dynamic> bahasa = {};
  String? namaLengkapLabel, namaLengkapHint;
  String? phoneLabel, phoneHint;
  String? cobaLagi;

  Timer? _cvvDebounce, _phoneDebounce, _idCardDebounce;

  String? currencySession;

  String? notLoginText, notLoginDesc, login;

  bool creditCardClicked = false;
  bool virtualAkunClicked = false;
  bool paymentBankClicked = false;
  bool eWalletClicked = false;
  bool retailClicked = false;
  bool konterClicked = false;
  bool qrCodeClicked = false;
  bool debitClicked = false;

  bool isConfirmLoading = false;
  List<dynamic> creditCard = [];
  List<dynamic> virtualAkun = [];
  List<dynamic> paymentBank = [];
  List<dynamic> eWallet = [];
  List<dynamic> retail = [];
  List<dynamic> konter = [];
  List<dynamic> qrCode = [];
  List<dynamic> debit = [];

  final creditCardKey = GlobalKey();
  final virtualAkunKey = GlobalKey();
  final paymentBankKey = GlobalKey();
  final eWalletKey = GlobalKey();
  final retailKey = GlobalKey();
  final konterKey = GlobalKey();
  final qrCodeKey = GlobalKey();
  final debitKey = GlobalKey();

  bool showErrorBar = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _getCurrency();
      await _checkToken();
      await getPaymentEvent(widget.id_event);

      user_id = widget.idUser;
    });
  }

  Future<void> _getBahasa() async {
    final lang = await StorageService.getLanguage();
    setState(() => langCode = lang);

    final tempBahasa = await LangService.getJsonData(langCode!, "bahasa");

    setState(() {
      bahasa = tempBahasa;
      namaLengkapLabel = bahasa['nama_lengkap_label'];
      namaLengkapHint = bahasa['nama_lengkap'];
      phoneLabel = bahasa['nomor_hp_label'];
      phoneHint = bahasa['nomor_hp'];
      cobaLagi = bahasa['coba_lagi'];

      notLoginText = bahasa['notLogin'];
      notLoginDesc = bahasa['notLoginDesc'];
      login = bahasa['login'];
    });
  }

  Future<void> _getCurrency() async {
    final currency = await StorageService.getCurrency();
    setState(() => currencyCode = currency);
  }

  Future<void> _checkToken() async {
    final storedToken = await StorageService.getToken();
    if (mounted) {
      setState(() {
        token = storedToken;
      });
    }
  }

  Future<void> getPaymentEvent(String id_event) async {

    final body = {
      "id_event": id_event,
    };

    final resultEvent = await ApiService.post('/event/detail', body: body, xLanguage: langCode, xCurrency: currencyCode);
    if (resultEvent == null || resultEvent['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultEvent?['message'];
      });
      return;
    }

    final resultPayment = await ApiService.get("/event/$id_event/payment-methods", xLanguage: langCode, xCurrency: currencyCode);
    if (resultPayment == null || resultPayment['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultPayment?['message'];
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      detailEvent = resultEvent['data'] ?? {};
      eventCurrency = detailEvent['event']['currency'];
      payment = resultPayment['data'] ?? {};
    
      creditCard = payment['Credit Card'] ?? [];
      virtualAkun = payment['Virtual Account'] ?? [];
      paymentBank = payment['Payment Bank'] ?? [];
      eWallet = payment['E-Wallet'] ?? [];
      retail = payment['Retail'] ?? [];
      konter = payment['Counter'] ?? [];
      qrCode = payment['QR Codes'] ?? [];
      debit = payment['Direct Debit'] ?? [];

      if (creditCard.isNotEmpty) {
        creditCardClicked = true;
      } else if (virtualAkun.isNotEmpty) {
        virtualAkunClicked = true;
      } else if (paymentBank.isNotEmpty) {
        paymentBankClicked = true;
      } else if (eWallet.isNotEmpty) {
        eWalletClicked = true;
      } else if (retail.isNotEmpty) {
        retailClicked = true;
      } else if (konter.isNotEmpty) {
        konterClicked = true;
      } else if (qrCode.isNotEmpty) {
        qrCodeClicked = true;
      } else if (debit.isNotEmpty) {
        debitClicked = true;
      }
      
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
            ? const Center(child: CircularProgressIndicator(color: Colors.red,)) 
            : kontenSection(),

          GlobalErrorBar(
            visible: showErrorBar, 
            message: errorMessage, 
            onRetry: () {
              getPaymentEvent(widget.id_event);
            },
            onDismiss: () {
              setState(() {
                showErrorBar = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget kontenSection () {
    expDateController.addListener(() {
      final text = expDateController.text;

      if (_isEditing) return;
        _isEditing = true;

      // Hapus karakter selain angka dan '/'
      final cleaned = text.replaceAll(RegExp(r'[^0-9/]'), '');

      String newText = cleaned;

      // Kalau user baru ketik 2 digit dan belum ada '/'
      if (cleaned.length == 2 && !cleaned.contains('/')) {
        newText = "$cleaned/";
      }

      // Potong kalau lebih dari 5 karakter
      if (newText.length > 5) {
        newText = newText.substring(0, 5);
      }

      if (newText != text) {
        expDateController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }

      if (newText.contains('/')) {
        final parts = newText.split('/');
        expiry_month = parts[0];
        expiry_year = parts.length > 1 ? parts[1] : null;
      } else {
        expiry_month = newText;
        expiry_year = null;
      }

      _isEditing = false;
    });

    Future<void> doConfirmProcess() async {
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

      int globalIndex = 0;

      for (int i = 0; i < widget.ids_tiket.length; i++) {
        final idTicket = widget.ids_tiket[i];
        final count = int.tryParse(widget.counts_tiket[i].toString()) ?? 1;

        for (int j = 0; j < count; j++) {
          String genderValue;

          final rawGender = widget.genders[globalIndex]?.toString().toLowerCase();

          if (rawGender == 'laki-laki' || rawGender == 'male') {
            genderValue = 'male';
          } else if (rawGender == 'perempuan' || rawGender == 'female') {
            genderValue = 'female';
          } else {
            genderValue = ''; // handle error
          }

          tickets.add({
            "id_ticket": idTicket,
            "first_name": widget.first_names[globalIndex].text,
            "email": widget.emails[globalIndex].text,
            "phone": widget.phones[globalIndex].text,
            "gender": genderValue,
            "order_form_answers": List.generate(
              widget.ids_order_form_master[j].length,
              (index) => {
                "id_order_form_master": widget.ids_order_form_master[j][index],
                "id_order_form_detail": widget.ids_order_form_details[j][index],
                "answer": widget.answers[globalIndex][index],
              },
            ),
          });
          globalIndex++;
        }
      }

      final body = {
        "id_event": widget.id_event,
        "id_user": user_id ?? '',
        "platform": platform,
        "latitude": latitude,
        "longitude": longitude,
        "tickets": tickets,
        "payment_method": {
            "id_payment_method": id_payment_method,
            "mobile_number": mobile_number,
            "id_card_number": id_card_number,
            "card_number": card_number,
            "expiry_month": expiry_month,
            "expiry_year": expiry_year,
            "cvv": cvv
        },
      };

      var resultEventOrder = await ApiService.post("/order/event/checkout", body: body, xLanguage: langCode, token: token);

      if (resultEventOrder != null) {
        if (resultEventOrder['rc'] == 200) {
          final tempOrder = resultEventOrder['data'];

          var id_order = tempOrder['data']['id_order'];
          Navigator.pop(context);//tutup modal

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WaitingOrderEvent(id_order: id_order, formHistory: false, currency_session: currencyCode,)),
          );
        } else {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.noHeader,
            animType: AnimType.topSlide,
            title: bahasa['maaf'],
            desc: bahasa['error'], //error message dari api
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
          dialogType: DialogType.noHeader,
          animType: AnimType.topSlide,
          title: bahasa['maaf'],
          desc: bahasa['error'], //"Terjadi kesalahan. Silakan coba lagi.",
          btnOkOnPress: () {},
          btnOkColor: Colors.red,
          buttonsTextStyle: TextStyle(color: Colors.white),
          headerAnimationLoop: false,
          dismissOnTouchOutside: true,
          showCloseIcon: true,
        ).show();
      }
    }

    void handleConfirm() async {
      if (isConfirmLoading) return;

      setState(() => isConfirmLoading = true);

      try {
        await doConfirmProcess(); 
      } finally {
        if (mounted) {
          setState(() {
            isConfirmLoading = false;
          });
        }
      }
    }

    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          color: Colors.white,
          child: Center(child: CircularProgressIndicator(color: Colors.red,)),
        )
      );
    }

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: kGlobalPadding,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300,),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bahasa['header'], //"Pembayaran",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: kGlobalPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //pembayaran
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(FontAwesomeIcons.dollarSign),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      bahasa['pilih_payment'], //"Pilih Metode Pembayaran",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      bahasa['sub_pilih_payment'], //"Yuk pilih metode pembayaranmu...",
                    ),

                    const SizedBox(height: 12,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        if (creditCard.isNotEmpty) ... [
                          PaymentList(
                            sectionKey: creditCardKey, 
                            title: "International Payments",
                            isOpen: creditCardClicked, 
                            onTap: () {
                              setState(() {
                                bool willOpen = !creditCardClicked;

                                creditCardClicked = !creditCardClicked;

                                virtualAkunClicked = false;
                                paymentBankClicked = false;
                                eWalletClicked = false;
                                retailClicked = false;
                                konterClicked = false;
                                qrCodeClicked = false;
                                debitClicked = false;

                                if (willOpen) scrollTo(creditCardKey);
                              });
                            },
                            children: creditCard.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;
                              
                              final exchange_rate = item['exchange_rate_new'];
                              final limit_min = item['limit_min']; 
                              final limit_max = item['limit_max'];
    
                              final convertedHarga = widget.totalHargaAsli * (widget.rateCurrencyUser / widget.rateCurrency);
    
                              final currentcy_min = limit_min * exchange_rate;
                              final currentcy_max = (limit_max == 0 ? limit_min + 100 : limit_max) * exchange_rate;
    
                              num convertedLimitMin = currentcy_min * (widget.rateCurrencyUser / widget.rateCurrency);
                              num convertedLimitMax = currentcy_max * (widget.rateCurrencyUser / widget.rateCurrency);
                              num roundedValueMin = (convertedLimitMin * 100).ceil() / 100;
                              num roundedValueMax = (convertedLimitMax * 100).ceil() / 100;
    
                              final isSelected = selectedIndex == idx;
    
                              final isDisabled = convertedHarga < roundedValueMin || (convertedHarga > roundedValueMax);

                              final isAMEX = item['note'] != null ? item['note'].toLowerCase().contains('amex') : false;

                              return PaymentItem(
                                paymentTipe: "credit_card",
                                item: item,
                                idx: idx,

                                isSelected: isSelected,
                                isDisabled: isDisabled,

                                currencyCode: currencyCode,
                                voteCurrency: eventCurrency,

                                bahasa: bahasa,
                                formatter: formatter,

                                convertedHarga: convertedHarga,
                                roundedValueMin: roundedValueMin,
                                roundedValueMax: roundedValueMax,
                                limit_max: limit_max,

                                expDateController: expDateController,

                                onCardChanged: (val) => card_number = val,
                                onCvvChanged: (val) {
                                  cvv = val;

                                  _cvvDebounce?.cancel();
                                  if (isAMEX) {
                                    _cvvDebounce = Timer(const Duration(milliseconds: 700), () {
                                      if (val.length == 4 && _scrollController.hasClients) {
                                        _scrollController.animateTo(
                                          _scrollController.position.maxScrollExtent,
                                          duration: const Duration(milliseconds: 600),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    });
                                  } else {
                                    _cvvDebounce = Timer(const Duration(milliseconds: 700), () {
                                      if (val.length == 3 && _scrollController.hasClients) {
                                        _scrollController.animateTo(
                                          _scrollController.position.maxScrollExtent,
                                          duration: const Duration(milliseconds: 600),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    });
                                  }
                                },

                                onTap: () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = creditCard[idx]['id_metod'];
                                    currencySession = creditCard[idx]['currency_pg'];
                                  });

                                  if (item['flag_client'] == "1") {
                                    Future.delayed(const Duration(milliseconds: 200), () {
                                      _scrollController.animateTo(
                                        _scrollController.position.maxScrollExtent,
                                        duration: const Duration(milliseconds: 600),
                                        curve: Curves.easeOut,
                                      );
                                    });
                                  }

                                  var resultFee = await getFeeNew(
                                    currencyCode!,
                                    eventCurrency!,
                                    item['currency_pg'],
                                    widget.totalHargaAsli,
                                    item['fee_percent'],
                                    item['ppn'],
                                    item['fee'],
                                    item['exchange_rate_new'],
                                    null,
                                    item['rate'],
                                    widget.rateCurrency,
                                    widget.rateCurrencyUser,
                                  );

                                  setState(() {
                                    totalPayment = resultFee!['total_payment'];
                                    feeLayanan = (resultFee['fee_layanan'] * 100).ceil() / 100;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
    
                        if (virtualAkun.isNotEmpty) ... [
                          const SizedBox(height: 20),
    
                          PaymentList(
                            sectionKey: virtualAkunKey, 
                            title: "Virtual Account", 
                            isOpen: virtualAkunClicked, 
                            onTap: () {
                              setState(() {
                                bool willOpen = !virtualAkunClicked;

                                virtualAkunClicked = !virtualAkunClicked;

                                creditCardClicked = false;
                                paymentBankClicked = false;
                                eWalletClicked = false;
                                retailClicked = false;
                                konterClicked = false;
                                qrCodeClicked = false;
                                debitClicked = false;

                                if (willOpen) scrollTo(virtualAkunKey);
                              });
                            }, 
                            children: virtualAkun.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length 
                                + entry.key;
                              final item = entry.value;
                              
                              final exchange_rate = item['exchange_rate_new'];
                              final limit_min = item['limit_min']; 
                              final limit_max = item['limit_max'];
    
                              final convertedHarga = widget.totalHargaAsli * (widget.rateCurrencyUser / widget.rateCurrency);
    
                              final currentcy_min = limit_min * exchange_rate;
                              final currentcy_max = (limit_max == 0 ? limit_min + 100 : limit_max) * exchange_rate;
    
                              num convertedLimitMin = currentcy_min * (widget.rateCurrencyUser / widget.rateCurrency);
                              num convertedLimitMax = currentcy_max * (widget.rateCurrencyUser / widget.rateCurrency);
                              num roundedValueMin = (convertedLimitMin * 100).ceil() / 100;
                              num roundedValueMax = (convertedLimitMax * 100).ceil() / 100;
    
                              final isSelected = selectedIndex == idx;
    
                              final isDisabled = convertedHarga < roundedValueMin || (convertedHarga > roundedValueMax);

                              return PaymentItem(
                                paymentTipe: "virtual_akun",
                                item: item,
                                idx: idx,

                                isSelected: isSelected,
                                isDisabled: isDisabled,

                                currencyCode: currencyCode,
                                voteCurrency: eventCurrency,

                                bahasa: bahasa,
                                formatter: formatter,

                                convertedHarga: convertedHarga,
                                roundedValueMin: roundedValueMin,
                                roundedValueMax: roundedValueMax,
                                limit_max: limit_max,

                                onTap: () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = virtualAkun[index]['id_metod'];
                                    currencySession = virtualAkun[index]['currency_pg'];
                                  });
                                  
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                    _scrollController.animateTo(
                                      _scrollController.position.maxScrollExtent,
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeOut,
                                    );
                                  });
  
                                  // final resultFee = await getFee(voteCurrency!, item['currency_pg'], widget.totalHargaAsli, item['fee_percent'], item['ppn'], item['fee'], item['exchange_rate_new'], widget.counts_finalis);
                                  var resultFee = await getFeeNew(
                                    currencyCode!,
                                    eventCurrency!, 
                                    item['currency_pg'], 
                                    widget.totalHargaAsli, 
                                    item['fee_percent'], 
                                    item['ppn'], 
                                    item['fee'], 
                                    item['exchange_rate_new'], 
                                    null,
                                    item['rate'], 
                                    widget.rateCurrency, 
                                    widget.rateCurrencyUser);
                                  
                                  setState(() {
                                    totalPayment = resultFee!['total_payment'];
                                    feeLayanan = (resultFee['fee_layanan'] * 100).ceil() / 100;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],

                        if (paymentBank.isNotEmpty) ... [
                          const SizedBox(height: 20),

                          PaymentList(
                            sectionKey: paymentBankKey, 
                            title: "Payment Bank",
                            isOpen: paymentBankClicked, 
                            onTap: () {
                              setState(() {
                                bool willOpen = !paymentBankClicked;

                                paymentBankClicked = !paymentBankClicked;

                                creditCardClicked = false;
                                virtualAkunClicked = false;
                                eWalletClicked = false;
                                retailClicked = false;
                                konterClicked = false;
                                qrCodeClicked = false;
                                debitClicked = false;

                                if (willOpen) {
                                  scrollTo(paymentBankKey);
                                }
                              });
                            },
                            children: paymentBank.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length 
                                + virtualAkun.length 
                                + entry.key;
                              final item = entry.value;

                              final exchange_rate = item['exchange_rate_new'];
                              final limit_min = item['limit_min']; 
                              final limit_max = item['limit_max'];
    
                              final convertedHarga = widget.totalHargaAsli * (widget.rateCurrencyUser / widget.rateCurrency);
    
                              final currentcy_min = limit_min * exchange_rate;
                              final currentcy_max = limit_max * exchange_rate;
    
                              num convertedLimitMin = currentcy_min * (widget.rateCurrencyUser / widget.rateCurrency);
                              num convertedLimitMax = currentcy_max * (widget.rateCurrencyUser / widget.rateCurrency);
                              num roundedValueMin = (convertedLimitMin * 100).ceil() / 100;
                              num roundedValueMax = (convertedLimitMax * 100).ceil() / 100;
    
                              final isSelected = selectedIndex == idx;
    
                              final isDisabled = convertedHarga < roundedValueMin || (limit_max != 0 && convertedHarga > roundedValueMax);

                              return PaymentItem(
                                paymentTipe: "payment_bank",
                                item: item, 
                                idx: idx, 

                                isSelected: isSelected, 
                                isDisabled: isDisabled, 

                                currencyCode: currencyCode, 
                                voteCurrency: eventCurrency, 
                                bahasa: bahasa, 
                                formatter: formatter, 

                                convertedHarga: convertedHarga, 
                                roundedValueMin: roundedValueMin, 
                                roundedValueMax: roundedValueMax, 
                                limit_max: limit_max, 

                                onTap: () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = paymentBank[index]['id_metod'];
                                    currencySession = paymentBank[index]['currency_pg'];
                                  });
                                  
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                    _scrollController.animateTo(
                                      _scrollController.position.maxScrollExtent,
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeOut,
                                    );
                                  });
  
                                  // final resultFee = await getFee(voteCurrency!, item['currency_pg'], widget.totalHargaAsli, item['fee_percent'], item['ppn'], item['fee'], item['exchange_rate_new'], widget.counts_finalis);
                                  var resultFee = await getFeeNew(
                                    currencyCode!,
                                    eventCurrency!, 
                                    item['currency_pg'], 
                                    widget.totalHargaAsli, 
                                    item['fee_percent'], 
                                    item['ppn'], 
                                    item['fee'], 
                                    item['exchange_rate_new'], 
                                    null,
                                    item['rate'], 
                                    widget.rateCurrency, 
                                    widget.rateCurrencyUser);
                                  
                                  setState(() {
                                    totalPayment = resultFee!['total_payment'];
                                    feeLayanan = (resultFee['fee_layanan'] * 100).ceil() / 100;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],

                        if (eWallet.isNotEmpty) ... [
                          const SizedBox(height: 20),

                          PaymentList(
                            sectionKey: eWalletKey, 
                            title: "E-Wallet",
                            isOpen: eWalletClicked, 
                            onTap: () {
                              setState(() {
                                bool willOpen = !eWalletClicked;

                                eWalletClicked = !eWalletClicked;

                                creditCardClicked = false;
                                virtualAkunClicked = false;
                                paymentBankClicked = false;
                                retailClicked = false;
                                konterClicked = false;
                                qrCodeClicked = false;
                                debitClicked = false;

                                if (willOpen) {
                                  scrollTo(eWalletKey);
                                }
                              });
                            },
                            children: eWallet.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length
                                + virtualAkun.length 
                                + paymentBank.length 
                                + entry.key;
                              final item = entry.value;

                              final exchange_rate = item['exchange_rate_new'];
                              final limit_min = item['limit_min']; 
                              final limit_max = item['limit_max'];
    
                              final convertedHarga = widget.totalHargaAsli * (widget.rateCurrencyUser / widget.rateCurrency);
    
                              final currentcy_min = limit_min * exchange_rate;
                              final currentcy_max = limit_max * exchange_rate;
    
                              num convertedLimitMin = currentcy_min * (widget.rateCurrencyUser / widget.rateCurrency);
                              num convertedLimitMax = currentcy_max * (widget.rateCurrencyUser / widget.rateCurrency);
                              num roundedValueMin = (convertedLimitMin * 100).ceil() / 100;
                              num roundedValueMax = (convertedLimitMax * 100).ceil() / 100;
    
                              final isSelected = selectedIndex == idx;
    
                              final isDisabled = convertedHarga < roundedValueMin || (limit_max != 0 && convertedHarga > roundedValueMax);

                              return PaymentItem(
                                paymentTipe: "e_wallet",
                                item: item, 
                                idx: idx, 

                                isSelected: isSelected, 
                                isDisabled: isDisabled, 

                                currencyCode: currencyCode, 
                                voteCurrency: eventCurrency, 
                                bahasa: bahasa, 
                                formatter: formatter, 

                                convertedHarga: convertedHarga, 
                                roundedValueMin: roundedValueMin, 
                                roundedValueMax: roundedValueMax, 
                                limit_max: limit_max, 

                                onTap: () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = eWallet[index]['id_metod'];
                                    currencySession = eWallet[index]['currency_pg'];
                                  });
                                  
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                    _scrollController.animateTo(
                                      _scrollController.position.maxScrollExtent,
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeOut,
                                    );
                                  });
  
                                  // final resultFee = await getFee(voteCurrency!, item['currency_pg'], widget.totalHargaAsli, item['fee_percent'], item['ppn'], item['fee'], item['exchange_rate_new'], widget.counts_finalis);
                                  var resultFee = await getFeeNew(
                                    currencyCode!,
                                    eventCurrency!, 
                                    item['currency_pg'], 
                                    widget.totalHargaAsli, 
                                    item['fee_percent'], 
                                    item['ppn'], 
                                    item['fee'], 
                                    item['exchange_rate_new'], 
                                    null,
                                    item['rate'], 
                                    widget.rateCurrency, 
                                    widget.rateCurrencyUser);
                                  
                                  setState(() {
                                    totalPayment = resultFee!['total_payment'];
                                    feeLayanan = (resultFee['fee_layanan'] * 100).ceil() / 100;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],

                        if (retail.isNotEmpty) ... [
                          const SizedBox(height: 20),

                          PaymentList(
                            sectionKey: retailKey, 
                            title: "Retail",
                            isOpen: retailClicked, 
                            onTap: () {
                              setState(() {
                                bool willOpen = !retailClicked;

                                retailClicked = !retailClicked;

                                creditCardClicked = false;
                                virtualAkunClicked = false;
                                paymentBankClicked = false;
                                eWalletClicked = false;
                                konterClicked = false;
                                qrCodeClicked = false;
                                debitClicked = false;

                                if (willOpen) {
                                  scrollTo(retailKey);
                                }
                              });
                            },
                            children: retail.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length 
                                + virtualAkun.length 
                                + paymentBank.length 
                                + eWallet.length 
                                + entry.key;
                              final item = entry.value;

                              final exchange_rate = item['exchange_rate_new'];
                              final limit_min = item['limit_min']; 
                              final limit_max = item['limit_max'];
    
                              final convertedHarga = widget.totalHargaAsli * (widget.rateCurrencyUser / widget.rateCurrency);
    
                              final currentcy_min = limit_min * exchange_rate;
                              final currentcy_max = limit_max * exchange_rate;
    
                              num convertedLimitMin = currentcy_min * (widget.rateCurrencyUser / widget.rateCurrency);
                              num convertedLimitMax = currentcy_max * (widget.rateCurrencyUser / widget.rateCurrency);
                              num roundedValueMin = (convertedLimitMin * 100).ceil() / 100;
                              num roundedValueMax = (convertedLimitMax * 100).ceil() / 100;
    
                              final isSelected = selectedIndex == idx;
    
                              final isDisabled = convertedHarga < roundedValueMin || (limit_max != 0 && convertedHarga > roundedValueMax);

                              return PaymentItem(
                                paymentTipe: "retail",
                                item: item, 
                                idx: idx, 

                                isSelected: isSelected, 
                                isDisabled: isDisabled, 

                                currencyCode: currencyCode, 
                                voteCurrency: eventCurrency, 
                                bahasa: bahasa, 
                                formatter: formatter, 

                                convertedHarga: convertedHarga, 
                                roundedValueMin: roundedValueMin, 
                                roundedValueMax: roundedValueMax, 
                                limit_max: limit_max, 

                                onTap: () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = retail[index]['id_metod'];
                                    currencySession = retail[index]['currency_pg'];
                                  });
                                  
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                    _scrollController.animateTo(
                                      _scrollController.position.maxScrollExtent,
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeOut,
                                    );
                                  });
  
                                  // final resultFee = await getFee(voteCurrency!, item['currency_pg'], widget.totalHargaAsli, item['fee_percent'], item['ppn'], item['fee'], item['exchange_rate_new'], widget.counts_finalis);
                                  var resultFee = await getFeeNew(
                                    currencyCode!,
                                    eventCurrency!, 
                                    item['currency_pg'], 
                                    widget.totalHargaAsli, 
                                    item['fee_percent'], 
                                    item['ppn'], 
                                    item['fee'], 
                                    item['exchange_rate_new'], 
                                    null,
                                    item['rate'], 
                                    widget.rateCurrency, 
                                    widget.rateCurrencyUser);
                                  
                                  setState(() {
                                    totalPayment = resultFee!['total_payment'];
                                    feeLayanan = (resultFee['fee_layanan'] * 100).ceil() / 100;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],

                        if (konter.isNotEmpty) ... [
                          const SizedBox(height: 20),

                          PaymentList(
                            sectionKey: konterKey, 
                            title: "Counter",
                            isOpen: konterClicked, 
                            onTap: () {
                              setState(() {
                                bool willOpen = !konterClicked;

                                konterClicked = !konterClicked;

                                creditCardClicked = false;
                                virtualAkunClicked = false;
                                paymentBankClicked = false;
                                eWalletClicked = false;
                                retailClicked = false;
                                qrCodeClicked = false;
                                qrCodeClicked = false;
                                debitClicked = false;

                                if (willOpen) {
                                  scrollTo(konterKey);
                                }
                              });
                            },
                            children: konter.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length 
                                + virtualAkun.length 
                                + paymentBank.length 
                                + eWallet.length 
                                + retail.length
                                + entry.key;
                              final item = entry.value;

                              final exchange_rate = item['exchange_rate_new'];
                              final limit_min = item['limit_min']; 
                              final limit_max = item['limit_max'];
    
                              final convertedHarga = widget.totalHargaAsli * (widget.rateCurrencyUser / widget.rateCurrency);
    
                              final currentcy_min = limit_min * exchange_rate;
                              final currentcy_max = limit_max * exchange_rate;
    
                              num convertedLimitMin = currentcy_min * (widget.rateCurrencyUser / widget.rateCurrency);
                              num convertedLimitMax = currentcy_max * (widget.rateCurrencyUser / widget.rateCurrency);
                              num roundedValueMin = (convertedLimitMin * 100).ceil() / 100;
                              num roundedValueMax = (convertedLimitMax * 100).ceil() / 100;
    
                              final isSelected = selectedIndex == idx;
    
                              final isDisabled = convertedHarga < roundedValueMin || (limit_max != 0 && convertedHarga > roundedValueMax);

                              return PaymentItem(
                                paymentTipe: "konter",
                                item: item, 
                                idx: idx, 

                                isSelected: isSelected, 
                                isDisabled: isDisabled, 

                                currencyCode: currencyCode, 
                                voteCurrency: eventCurrency, 
                                bahasa: bahasa, 
                                formatter: formatter, 

                                convertedHarga: convertedHarga, 
                                roundedValueMin: roundedValueMin, 
                                roundedValueMax: roundedValueMax, 
                                limit_max: limit_max, 

                                onTap: () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = konter[index]['id_metod'];
                                    currencySession = konter[index]['currency_pg'];
                                  });
                                  
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                    _scrollController.animateTo(
                                      _scrollController.position.maxScrollExtent,
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeOut,
                                    );
                                  });
  
                                  // final resultFee = await getFee(voteCurrency!, item['currency_pg'], widget.totalHargaAsli, item['fee_percent'], item['ppn'], item['fee'], item['exchange_rate_new'], widget.counts_finalis);
                                  var resultFee = await getFeeNew(
                                    currencyCode!,
                                    eventCurrency!, 
                                    item['currency_pg'], 
                                    widget.totalHargaAsli, 
                                    item['fee_percent'], 
                                    item['ppn'], 
                                    item['fee'], 
                                    item['exchange_rate_new'], 
                                    null,
                                    item['rate'], 
                                    widget.rateCurrency, 
                                    widget.rateCurrencyUser);
                                  
                                  setState(() {
                                    totalPayment = resultFee!['total_payment'];
                                    feeLayanan = (resultFee['fee_layanan'] * 100).ceil() / 100;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],

                        if (qrCode.isNotEmpty) ... [
                          const SizedBox(height: 20),

                          PaymentList(
                            sectionKey: qrCodeKey, 
                            title: "QR Codes",
                            isOpen: qrCodeClicked, 
                            onTap: () {
                              setState(() {
                                bool willOpen = !qrCodeClicked;

                                qrCodeClicked = !qrCodeClicked;

                                creditCardClicked = false;
                                virtualAkunClicked = false;
                                paymentBankClicked = false;
                                eWalletClicked = false;
                                retailClicked = false;
                                konterClicked = false;
                                debitClicked = false;

                                if (willOpen) {
                                  scrollTo(qrCodeKey);
                                }
                              });
                            },
                            children: qrCode.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length 
                                + virtualAkun.length 
                                + paymentBank.length 
                                + eWallet.length 
                                + retail.length
                                + konter.length
                                + entry.key;
                              final item = entry.value;

                              final exchange_rate = item['exchange_rate_new'];
                              final limit_min = item['limit_min']; 
                              final limit_max = item['limit_max'];
    
                              final convertedHarga = widget.totalHargaAsli * (widget.rateCurrencyUser / widget.rateCurrency);
    
                              final currentcy_min = limit_min * exchange_rate;
                              final currentcy_max = limit_max * exchange_rate;
    
                              num convertedLimitMin = currentcy_min * (widget.rateCurrencyUser / widget.rateCurrency);
                              num convertedLimitMax = currentcy_max * (widget.rateCurrencyUser / widget.rateCurrency);
                              num roundedValueMin = (convertedLimitMin * 100).ceil() / 100;
                              num roundedValueMax = (convertedLimitMax * 100).ceil() / 100;
    
                              final isSelected = selectedIndex == idx;
    
                              final isDisabled = convertedHarga < roundedValueMin || (limit_max != 0 && convertedHarga > roundedValueMax);

                              return PaymentItem(
                                paymentTipe: "qr_code",
                                item: item, 
                                idx: idx, 

                                isSelected: isSelected, 
                                isDisabled: isDisabled, 

                                currencyCode: currencyCode, 
                                voteCurrency: eventCurrency, 
                                bahasa: bahasa, 
                                formatter: formatter, 

                                convertedHarga: convertedHarga, 
                                roundedValueMin: roundedValueMin, 
                                roundedValueMax: roundedValueMax, 
                                limit_max: limit_max, 

                                onTap: () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = qrCode[index]['id_metod'];
                                    currencySession = qrCode[index]['currency_pg'];
                                  });
                                  
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                    _scrollController.animateTo(
                                      _scrollController.position.maxScrollExtent,
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeOut,
                                    );
                                  });
  
                                  // final resultFee = await getFee(voteCurrency!, item['currency_pg'], widget.totalHargaAsli, item['fee_percent'], item['ppn'], item['fee'], item['exchange_rate_new'], widget.counts_finalis);
                                  var resultFee = await getFeeNew(
                                    currencyCode!,
                                    eventCurrency!, 
                                    item['currency_pg'], 
                                    widget.totalHargaAsli, 
                                    item['fee_percent'], 
                                    item['ppn'], 
                                    item['fee'], 
                                    item['exchange_rate_new'], 
                                    null,
                                    item['rate'], 
                                    widget.rateCurrency, 
                                    widget.rateCurrencyUser);
                                  
                                  setState(() {
                                    totalPayment = resultFee!['total_payment'];
                                    feeLayanan = (resultFee['fee_layanan'] * 100).ceil() / 100;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],

                        if (debit.isNotEmpty) ... [
                          const SizedBox(height: 20),

                          PaymentList(
                            sectionKey: debitKey, 
                            title: "Direct Debit",
                            isOpen: debitClicked, 
                            onTap: () {
                              setState(() {
                                bool willOpen = !debitClicked;

                                debitClicked = !debitClicked;

                                creditCardClicked = false;
                                virtualAkunClicked = false;
                                paymentBankClicked = false;
                                eWalletClicked = false;
                                retailClicked = false;
                                konterClicked = false;
                                qrCodeClicked = false;

                                if (willOpen) {
                                  scrollTo(debitKey);
                                }
                              });
                            },
                            children: debit.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length 
                                + virtualAkun.length 
                                + paymentBank.length 
                                + eWallet.length 
                                + retail.length
                                + konter.length
                                + qrCode.length
                                + entry.key;
                              final item = entry.value;

                              final exchange_rate = item['exchange_rate_new'];
                              final limit_min = item['limit_min']; 
                              final limit_max = item['limit_max'];
    
                              final convertedHarga = widget.totalHargaAsli * (widget.rateCurrencyUser / widget.rateCurrency);
    
                              final currentcy_min = limit_min * exchange_rate;
                              final currentcy_max = limit_max * exchange_rate;
    
                              num convertedLimitMin = currentcy_min * (widget.rateCurrencyUser / widget.rateCurrency);
                              num convertedLimitMax = currentcy_max * (widget.rateCurrencyUser / widget.rateCurrency);
                              num roundedValueMin = (convertedLimitMin * 100).ceil() / 100;
                              num roundedValueMax = (convertedLimitMax * 100).ceil() / 100;
    
                              final isSelected = selectedIndex == idx;
    
                              final isDisabled = convertedHarga < roundedValueMin || (limit_max != 0 && convertedHarga > roundedValueMax);

                              return PaymentItem(
                                paymentTipe: "debit",
                                item: item, 
                                idx: idx, 

                                isSelected: isSelected, 
                                isDisabled: isDisabled, 

                                currencyCode: currencyCode, 
                                voteCurrency: eventCurrency, 
                                bahasa: bahasa, 
                                formatter: formatter, 

                                convertedHarga: convertedHarga, 
                                roundedValueMin: roundedValueMin, 
                                roundedValueMax: roundedValueMax, 
                                limit_max: limit_max, 

                                onTap: () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = debit[index]['id_metod'];
                                    currencySession = debit[index]['currency_pg'];
                                  });

                                  if (item['flag_client'] == "1") {
                                    Future.delayed(const Duration(milliseconds: 200), () {
                                      _scrollController.animateTo(
                                        _scrollController.position.maxScrollExtent,
                                        duration: const Duration(milliseconds: 600),
                                        curve: Curves.easeOut,
                                      );
                                    });
                                  }
    
                                  // final resultFee = await getFee(voteCurrency!, item['currency_pg'], widget.totalHargaAsli, item['fee_percent'], item['ppn'], item['fee'], item['exchange_rate_new'], widget.counts_finalis);
                                  var resultFee = await getFeeNew(
                                    currencyCode!,
                                    eventCurrency!, 
                                    item['currency_pg'], 
                                    widget.totalHargaAsli, 
                                    item['fee_percent'], 
                                    item['ppn'], 
                                    item['fee'], 
                                    item['exchange_rate_new'], 
                                    null,
                                    item['rate'], 
                                    widget.rateCurrency, 
                                    widget.rateCurrencyUser);
                                  
                                  setState(() {
                                    totalPayment = resultFee!['total_payment'];
                                    feeLayanan = (resultFee['fee_layanan'] * 100).ceil() / 100;
                                  });
                                },

                                onPhoneChanged: (val){
                                  mobile_number = val;

                                  if (item['bank_code'] != "KTB") {
                                    _phoneDebounce?.cancel();
                                    _phoneDebounce = Timer(const Duration(milliseconds: 700), () {
                                      if (val.length >= 12 && _scrollController.hasClients) {
                                        _scrollController.animateTo(
                                          _scrollController.position.maxScrollExtent,
                                          duration: const Duration(milliseconds: 600),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    });
                                  }
                                },

                                onIDCardChanged: (val) {
                                  id_card_number = val;

                                  if (item['bank_code'] == "KTB") {
                                    _idCardDebounce?.cancel();
                                    _idCardDebounce = Timer(const Duration(milliseconds: 700), () {
                                      if (val.length == 13 && _scrollController.hasClients) {
                                        _scrollController.animateTo(
                                          _scrollController.position.maxScrollExtent,
                                          duration: const Duration(milliseconds: 600),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),

                    if (selectedIndex != null) ...[
                      const SizedBox(height: 25),
                      Text(
                        bahasa['detail_harga'], //"Detail Harga"
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 16,),
                      Column(
                        children: [
                          Column(
                            children: [
                              for (int i = 0; i < widget.names_tiket.length; i++) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("${widget.names_tiket[i]} (${widget.counts_tiket[i]}x)"),
                                    Text(
                                      currencyCode == null
                                        ? "$eventCurrency ${formatter.format(widget.counts_tiket[i] * widget.prices_tiket[i])}"
                                        : "$currencyCode ${formatter.format(widget.counts_tiket[i] * widget.prices_tiket[i])}",
                                    ),
                                  ],
                                ),
                                if (i != widget.names_tiket.length - 1)
                                  SizedBox(height: 16),
                              ],
                            ],
                          ),

                          const SizedBox(height: 16,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(bahasa['biaya_layanan']), //"Biaya Layanan"
                              Text(
                                currencyCode == null
                                  ? '$eventCurrency ${formatter.format(feeLayanan)}'
                                  : '$currencyCode ${formatter.format(feeLayanan)}',
                              )
                            ],
                          ),

                          const SizedBox(height: 6,),
                          const Divider(
                            thickness: 1,
                            color: Color.fromARGB(255, 224, 224, 224),
                          ),

                          const SizedBox(height: 6,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              //"Total Bayar",
                              Text(bahasa['total_bayar'], style: TextStyle(fontWeight: FontWeight.bold),),
                              Text(
                                currencyCode == null
                                  ? "$eventCurrency ${formatter.format(totalPayment)}"
                                  : "$currencyCode ${formatter.format(totalPayment)}",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )
                            ],
                          ),

                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        bahasa['batal'],
                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: isConfirmLoading ? null : handleConfirm,
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isConfirmLoading ? Colors.red.shade300 : Colors.red,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: isConfirmLoading
                                        ? SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            bahasa['konfirmasi'],
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            )
          ),
        ],
      ),
    );
  }

  void scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;

    Future.delayed(const Duration(milliseconds: 120), () {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    });
  }
}