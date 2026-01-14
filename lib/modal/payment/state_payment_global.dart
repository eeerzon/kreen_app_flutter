// ignore_for_file: non_constant_identifier_names, prefer_typing_uninitialized_variables, use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/helper/get_geo_location.dart';
import 'package:kreen_app_flutter/modal/payment/get_fee_new.dart';
import 'package:kreen_app_flutter/pages/event/waiting_order_event.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class StatePaymentGlobal extends StatefulWidget {
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
  final List<String> ids_order_form_details;
  final List<String> ids_order_form_master;
  final List<String> answers;
  final bool formGlobal;
  final bool fromDetail;
  final String jenis_participant;
  final String? idUser;
  final num rateCurrency;
  final num rateCurrencyUser;

  const StatePaymentGlobal({
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
  State<StatePaymentGlobal> createState() => _StatePaymentGlobalState();
}

class _StatePaymentGlobalState extends State<StatePaymentGlobal> {
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

  final formatter = NumberFormat.decimalPattern("en_US");
  final ScrollController _scrollController = ScrollController();
  final TextEditingController expDateController = TextEditingController();
  bool _isEditing = false;

  bool isLoading = true;

  String? langCode, currencyCode, token;
  Map<String, dynamic> paymentLang = {};
  Map<String, dynamic> detailVoteLang = {};
  String? namaLengkapLabel, namaLengkapHint;
  String? phoneLabel, phoneHint;
  String? cobaLagi;

  Timer? _phoneDebounce;

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

  Future<void> getData(String id_event) async {

    get_user = await StorageService.getUser();
    user_id = get_user['id'];
    first_name = get_user['first_name'] ?? '';
    last_name = get_user['last_name'] ?? '';
    gender = get_user['gender'] ?? '';
    phone = get_user['phone'] ?? '';
    email = get_user['email'] ?? '';

    if (gender.isNotEmpty) {
      selectedGender = gender.toLowerCase() == 'male' ? 'Laki-laki' : 'Perempuan';
    }

    final resultdetailEvent = await ApiService.get("/event/$id_event");
    final resultPayment = await ApiService.get("/event/$id_event/payment-methods");

    detailEvent = resultdetailEvent?['data'] ?? {};
    eventCurrency = detailEvent['currency'];

    payment = resultPayment?['data'] ?? {};
  }

  Future<void> getPaymentEvent(String id_event) async {

    get_user = await StorageService.getUser();
    user_id = get_user['id'];
    first_name = get_user['first_name'] ?? '';
    last_name = get_user['last_name'] ?? '';
    gender = get_user['gender'] ?? '';
    phone = get_user['phone'] ?? '';
    email = get_user['email'] ?? '';

    final body = {
      "id_event": id_event,
    };

    final resultEvent = await ApiService.post('/event/detail', body: body);
    final resultPayment = await ApiService.get("/event/$id_event/payment-methods");

    setState(() {
      detailEvent = resultEvent?['data'] ?? {};
      eventCurrency = detailEvent['event']['currency'];
      payment = resultPayment?['data'] ?? {};
      isLoading = false;
    });
  }

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

    final tempPayment = await LangService.getJsonData(langCode!, "payment");
    final tempnamalabel = await LangService.getText(langCode!, "nama_lengkap_label");
    final tempnamahint = await LangService.getText(langCode!, "nama_lengkap");
    final tempnohplabel = await LangService.getText(langCode!, "nomor_hp_label");
    final tempnohphint = await LangService.getText(langCode!, "nomor_hp");
    final tempcobalagi = await LangService.getText(langCode!, "coba_lagi");

    final tempdetailvote = await LangService.getJsonData(langCode!, "detail_vote");

    setState(() {
      paymentLang = tempPayment;
      namaLengkapLabel = tempnamalabel;
      namaLengkapHint = tempnamahint;
      phoneLabel = tempnohplabel;
      phoneHint = tempnohphint;
      cobaLagi = tempcobalagi;

      detailVoteLang = tempdetailvote;
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

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: widget.jenis_participant == "Umum"
          ? token == null 
            ? KeyedSubtree(
                key: const ValueKey('not-login'),
                child: getLoginUser(),
              )
            : KeyedSubtree(
                key: const ValueKey('logged-in'),
                child: kontenSection(),
              )
          : KeyedSubtree(
              key: const ValueKey('logged-in'),
              child: kontenSection(),
            ),
      ), 
    );
  }

  Widget getLoginUser() {
    return Container(
      padding: kGlobalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5E5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              "assets/images/img_ovo30d.png",
              height: 60,
              width: 60,
            )
          ),

          const SizedBox(height: 24),
          Text(
            notLoginText!,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),
          Text(
            notLoginDesc!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginPage(notLog: true),
                ),
              );

              if (result == true) {
                await _checkToken();

                final newToken = await StorageService.getToken();
                final getUser = await StorageService.getUser();
                if (mounted) {
                  setState(() {
                    token = newToken;
                    user_id = getUser['id'];
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              elevation: 2,
            ),
            child: Text(
              login!,
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget kontenSection() {
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

    void handleConfirm() async {
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

      for (int i = 0; i < widget.ids_tiket.length; i++) {
        final idTicket = widget.ids_tiket[i];
        final count = int.tryParse(widget.counts_tiket[i].toString()) ?? 1;

        for (int j = 0; j < count; j++) {
          String genderValue;

          final rawGender = widget.genders[j]?.toString().toLowerCase();

          if (rawGender == 'laki-laki' || rawGender == 'male') {
            genderValue = 'male';
          } else if (rawGender == 'perempuan' || rawGender == 'female') {
            genderValue = 'female';
          } else {
            genderValue = ''; // handle error
          }

          tickets.add({
            "id_ticket": idTicket,
            "first_name": widget.first_names[j].text,
            "email": widget.emails[j].text,
            "phone": widget.phones[j].text,
            "gender": genderValue
          });
        }
      }

      final body = {
        "id_event": widget.id_event,
        "id_user": user_id ?? '',
        'platform': platform,
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
        "order_form_answers_global": List.generate(
          widget.ids_order_form_master.length, (index) => {
            "id_order_form_master": widget.ids_order_form_master[index],
            "id_order_form_detail": widget.ids_order_form_details[index],
            "answer": widget.answers[index]
          },
        ),
      };

      var resultEventOrder = await ApiService.post("/order/event/checkout", body: body);

      if (resultEventOrder != null) {
        if (resultEventOrder['rc'] == 200) {
          final tempOrder = resultEventOrder['data'];

          var id_order = tempOrder['data']['id_order'];
          Navigator.pop(context);//tutup modal

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WaitingOrderEvent(id_order: id_order, formHistory: false, currency_session: currencyCode,)),
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
            desc: desc, //error message dari api
            btnOkOnPress: () {},
            btnOkColor: Colors.red,
            buttonsTextStyle: TextStyle(color: Colors.white),
            headerAnimationLoop: false,
            dismissOnTouchOutside: true,
            showCloseIcon: true,
          ).show();
        } else if (resultEventOrder['rc'] == 500) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.error,
            animType: AnimType.topSlide,
            title: 'Oops!',
            desc: "${resultEventOrder['message']}\n${paymentLang['another_payment']}",
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
          desc: cobaLagi, //"Terjadi kesalahan. Silakan coba lagi.",
          btnOkOnPress: () {},
          btnOkColor: Colors.red,
          buttonsTextStyle: TextStyle(color: Colors.white),
          headerAnimationLoop: false,
          dismissOnTouchOutside: true,
          showCloseIcon: true,
        ).show();
      }
    }
    
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.red,)),
      );
    }

    final creditCard = payment['Credit Card'] ?? [];
    final virtualAkun = payment['Virtual Account'] ?? [];
    final paymentBank = payment['Payment Bank'] ?? [];
    final eWallet = payment['E-Wallet'] ?? [];
    final retail = payment['Retail'] ?? [];
    final konter = payment['Counter'] ?? [];
    final qrCode = payment['QR Codes'] ?? [];
    final debit = payment['Direct Debit'] ?? [];

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
                  paymentLang['header'], //"Pembayaran",
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
                        border: Border.all(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Icon(FontAwesomeIcons.dollarSign),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      paymentLang['pilih_payment'], //"Pilih Metode Pembayaran",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      paymentLang['sub_pilih_payment'], //"Yuk pilih metode pembayaranmu...",
                    ),

                    const SizedBox(height: 12,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (creditCard.isNotEmpty) ... [
                          InkWell(
                            onTap: () {
                              setState(() {
                                creditCardClicked = !creditCardClicked;

                                // if (!creditCardClicked) {
                                //   selectedIndex = -1;
                                //   id_payment_method = null;
                                //   currencySession = null;
                                //   totalPayment = 0;
                                //   feeLayanan = 0;
                                //   totalVotes = 0;
                                // }
                              });
                            },
                            child: Container(
                              padding: kGlobalPadding,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "International Payments",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    creditCardClicked 
                                      ? Icons.keyboard_arrow_up 
                                      : Icons.keyboard_arrow_down
                                  )
                                ],
                              ),
                            ),
                          ),
                          
                          if (creditCardClicked) ... [
                            const SizedBox(height: 8),
                            ...creditCard.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;

                              final payment_name = item['payment_name'];
                              final id_pg_type = item['id_pg_type'];
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

                              return GestureDetector(
                                onTap: isDisabled
                                ? null 
                                : () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = creditCard[idx]['id_metod'];
                                    currencySession = creditCard[idx]['currency_pg'];
                                  });
                                  
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
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: isDisabled ? 0.6 : 1.0,
                                      child: ColorFiltered(
                                        colorFilter: isDisabled
                                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Image.network(
                                                    "$baseUrl/image/payment-method/${item['img_web']}",
                                                    height: 70,
                                                    width: 70,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        height: 70,
                                                        width: 70,
                                                      );
                                                    },
                                                  ),

                                                  const SizedBox(width: 8,),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            // Teks akan menyesuaikan ruang sisa
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(top: 8.0),
                                                                child: Text(
                                                                  "$payment_name $id_pg_type",
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  softWrap: true,
                                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(width: 6),
                                                            // Badge region
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red.shade50,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                item['region'] ?? '',
                                                                style: TextStyle(
                                                                  color: Colors.red.shade700,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(height: 6),
                                                        if (convertedHarga < roundedValueMin)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text(
                                                              currencyCode == null
                                                                ? "${paymentLang['limit_min']} $eventCurrency ${formatter.format((roundedValueMin + 1000))}"
                                                                : "${paymentLang['limit_min']} $currencyCode ${formatter.format((roundedValueMin))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),
                                                        
                                                        if (convertedHarga > roundedValueMax)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text( limit_max == 0
                                                              ? currencyCode == null
                                                                ? "${paymentLang['limit_max']} $eventCurrency ${formatter.format((roundedValueMax + 1000))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}"
                                                              : currencyCode == null
                                                                ? "${paymentLang['limit_max']} $eventCurrency ${formatter.format((roundedValueMax))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),

                                                      ],
                                                    ),
                                                  )

                                                ],
                                              ),

                                              if (isSelected) ... [
                                                const SizedBox(height: 20,),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Kartu Kredit',
                                                    ),
                                                    Container(
                                                      color: Colors.white,
                                                      width: double.infinity,
                                                      child: TextField(
                                                        autofocus: false,
                                                        onChanged: (value) {
                                                          card_number = value;
                                                        },
                                                        keyboardType: TextInputType.number,
                                                        decoration: InputDecoration(
                                                          hintText: "xxxx xxxx xxxx xxxx",
                                                          hintStyle: TextStyle(color: Colors.grey.shade400),
                                                          border: OutlineInputBorder(
                                                            borderRadius: const BorderRadius.only(
                                                              topLeft: Radius.circular(8),
                                                              topRight: Radius.circular(8),
                                                            ),
                                                          ),
                                                        ),
                                                        inputFormatters: [
                                                          LengthLimitingTextInputFormatter(16),
                                                        ],
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Container(
                                                            color: Colors.white,
                                                            child: TextField(
                                                              controller: expDateController,
                                                              autofocus: false,
                                                              decoration: InputDecoration(
                                                                hintText: "MM/YY",
                                                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                                                border: OutlineInputBorder(
                                                                  borderRadius: const BorderRadius.only(
                                                                    bottomLeft: Radius.circular(8),
                                                                  ),
                                                                ),
                                                              ),
                                                              inputFormatters: [
                                                                LengthLimitingTextInputFormatter(5),
                                                              ],
                                                            ),
                                                          )
                                                        ),

                                                        Expanded(
                                                          child: Container(
                                                            color: Colors.white,
                                                            child: TextField(
                                                              autofocus: false,
                                                              onChanged: (value) {
                                                                cvv = value;

                                                                if (value.length == 3) {
                                                                  FocusManager.instance.primaryFocus?.unfocus();
                                                                  Future.delayed(const Duration(milliseconds: 200), () {
                                                                    if (!_scrollController.hasClients) return;

                                                                    _scrollController.animateTo(
                                                                      _scrollController.position.maxScrollExtent,
                                                                      duration: const Duration(milliseconds: 600),
                                                                      curve: Curves.easeOut,
                                                                    );
                                                                  });
                                                                }
                                                              },
                                                              decoration: InputDecoration(
                                                                hintText: "CVV",
                                                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                                                border: OutlineInputBorder(
                                                                  borderRadius: const BorderRadius.only(
                                                                    bottomRight: Radius.circular(8),
                                                                  ),
                                                                ),
                                                              ),
                                                              inputFormatters: [
                                                                LengthLimitingTextInputFormatter(3),
                                                              ],
                                                              obscureText: true,
                                                            ),
                                                          )
                                                        )
                                                      ],
                                                    )
                                                  ],
                                                )
                                              ]
                                            ],
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],

                        if (virtualAkun.isNotEmpty) ... [
                          const SizedBox(height: 20),

                          InkWell(
                            onTap: () {
                              setState(() {
                                virtualAkunClicked = !virtualAkunClicked;
                              });
                            },
                            child: Container(
                              padding: kGlobalPadding,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300,),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Text(
                                    "Virtual Account",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    virtualAkunClicked 
                                      ? Icons.keyboard_arrow_up 
                                      : Icons.keyboard_arrow_down,
                                  )
                                ],
                              ),
                            ),
                          ),
                          
                          if (virtualAkunClicked) ... [
                            const SizedBox(height: 8),
                            ...virtualAkun.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length + entry.key;
                              final item = entry.value;
                              
                              final payment_name = item['payment_name'];
                              final id_pg_type = item['id_pg_type'];
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

                              return GestureDetector(
                                onTap: isDisabled
                                ? null 
                                : () async {
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
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: isDisabled ? 0.6 : 1.0,
                                      child: ColorFiltered(
                                        colorFilter: isDisabled
                                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Image.network(
                                                    "$baseUrl/image/payment-method/${item['img_web']}",
                                                    height: 70,
                                                    width: 70,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        height: 70,
                                                        width: 70,
                                                      );
                                                    },
                                                  ),

                                                  const SizedBox(width: 8,),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            // Teks akan menyesuaikan ruang sisa
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(top: 8.0),
                                                                child: Text(
                                                                  "$payment_name $id_pg_type",
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  softWrap: true,
                                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(width: 6),
                                                            // Badge region
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red.shade50,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                item['region'] ?? '',
                                                                style: TextStyle(
                                                                  color: Colors.red.shade700,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(height: 6),
                                                        if (convertedHarga < roundedValueMin)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text(
                                                              currencyCode == null
                                                                ? "${paymentLang['limit_min']} $eventCurrency ${formatter.format((roundedValueMin + 1000))}"
                                                                : "${paymentLang['limit_min']} $currencyCode ${formatter.format((roundedValueMin))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),
                                                        
                                                        if (convertedHarga > roundedValueMax)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text( limit_max == 0
                                                              ? currencyCode == null
                                                                ? "${paymentLang['limit_max']} $eventCurrency ${formatter.format((roundedValueMax + 1000))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}"
                                                              : currencyCode == null
                                                                ? "${paymentLang['limit_max']} $eventCurrency ${formatter.format((roundedValueMax))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),

                                                      ],
                                                    ),
                                                  )

                                                ],
                                              ),
                                            ],
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],

                        if (paymentBank.isNotEmpty) ... [
                          const SizedBox(height: 20),

                          InkWell(
                            onTap: () {
                              setState(() {
                                paymentBankClicked = !paymentBankClicked;
                              });
                            },
                            child: Container(
                              padding: kGlobalPadding,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300,),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Payment Bank",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Spacer(),
                                  Icon(
                                    paymentBankClicked 
                                      ? Icons.keyboard_arrow_up 
                                      : Icons.keyboard_arrow_down,
                                  )
                                ],
                              ),
                            ),
                          ),

                          if (paymentBankClicked) ... [
                            const SizedBox(height: 8),
                            ...paymentBank.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length + virtualAkun.length + entry.key;
                              final item = entry.value;
                              
                              final payment_name = item['payment_name'];
                              final id_pg_type = item['id_pg_type'];
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

                              return GestureDetector(
                                onTap: isDisabled
                                ? null 
                                : () async {
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
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: isDisabled ? 0.6 : 1.0,
                                      child: ColorFiltered(
                                        colorFilter: isDisabled
                                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Image.network(
                                                    "$baseUrl/image/payment-method/${item['img_web']}",
                                                    height: 70,
                                                    width: 70,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        height: 70,
                                                        width: 70,
                                                      );
                                                    },
                                                  ),

                                                  const SizedBox(width: 8,),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            // Teks akan menyesuaikan ruang sisa
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(top: 8.0),
                                                                child: Text(
                                                                  "$payment_name $id_pg_type",
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  softWrap: true,
                                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(width: 6),
                                                            // Badge region
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red.shade50,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                item['region'] ?? '',
                                                                style: TextStyle(
                                                                  color: Colors.red.shade700,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(height: 6),
                                                        if (convertedHarga < roundedValueMin)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text(
                                                              currencyCode == null
                                                                ? "${paymentLang['limit_min']} $eventCurrency ${formatter.format((roundedValueMin + 1000))}"
                                                                : "${paymentLang['limit_min']} $currencyCode ${formatter.format((roundedValueMin))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),
                                                        
                                                        if (convertedHarga > roundedValueMax)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text( limit_max == 0
                                                              ? currencyCode == null
                                                                ? "${paymentLang['limit_max']} $eventCurrency ${formatter.format((roundedValueMax + 1000))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}"
                                                              : currencyCode == null
                                                                ? "${paymentLang['limit_max']} $eventCurrency ${formatter.format((roundedValueMax))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),

                                                      ],
                                                    ),
                                                  )

                                                ],
                                              ),
                                            ],
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],

                        if (eWallet.isNotEmpty) ... [
                          const SizedBox(height: 20),

                          InkWell(
                            onTap: () {
                              setState(() {
                                eWalletClicked = !eWalletClicked;
                              });
                            },
                            child: Container(
                              padding: kGlobalPadding,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300,),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "E-Wallet",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Spacer(),
                                  Icon(
                                    eWalletClicked 
                                      ? Icons.keyboard_arrow_up 
                                      : Icons.keyboard_arrow_down,
                                  )
                                ],
                              ),
                            ),
                          ),
                          
                          if (eWalletClicked) ... [
                            const SizedBox(height: 8),
                            ...eWallet.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length + virtualAkun.length + paymentBank.length + entry.key;
                              final item = entry.value;
                              
                              final payment_name = item['payment_name'];
                              final id_pg_type = item['id_pg_type'];
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

                              return GestureDetector(
                                onTap: isDisabled
                                ? null 
                                : () async {
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
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: isDisabled ? 0.6 : 1.0,
                                      child: ColorFiltered(
                                        colorFilter: isDisabled
                                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Image.network(
                                                    "$baseUrl/image/payment-method/${item['img_web']}",
                                                    height: 70,
                                                    width: 70,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        height: 70,
                                                        width: 70,
                                                      );
                                                    },
                                                  ),

                                                  const SizedBox(width: 8,),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            // Teks akan menyesuaikan ruang sisa
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(top: 8.0),
                                                                child: Text(
                                                                  "$payment_name $id_pg_type",
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  softWrap: true,
                                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(width: 6),
                                                            // Badge region
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red.shade50,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                item['region'] ?? '',
                                                                style: TextStyle(
                                                                  color: Colors.red.shade700,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(height: 6),
                                                        if (convertedHarga < roundedValueMin)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text(
                                                              currencyCode == null
                                                                ? "${paymentLang['limit_min']} $eventCurrency ${formatter.format((roundedValueMin + 1000))}"
                                                                : "${paymentLang['limit_min']} $currencyCode ${formatter.format((roundedValueMin))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),
                                                        
                                                        if (convertedHarga > roundedValueMax)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text( limit_max == 0
                                                              ? currencyCode == null
                                                                ? "${paymentLang['limit_max']} $eventCurrency ${formatter.format((roundedValueMax + 1000))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}"
                                                              : currencyCode == null
                                                                ? "${paymentLang['limit_max']} $eventCurrency ${formatter.format((roundedValueMax))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),

                                                      ],
                                                    ),
                                                  )

                                                ],
                                              ),
                                            ],
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],

                        if (retail.isNotEmpty) ... [
                          const SizedBox(height: 20),

                          InkWell(
                            onTap: () {
                              setState(() {
                                retailClicked = !retailClicked;
                              });
                            },
                            child: Container(
                              padding: kGlobalPadding,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300,),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Retail",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Spacer(),
                                  Icon(
                                    retailClicked 
                                      ? Icons.keyboard_arrow_up 
                                      : Icons.keyboard_arrow_down,
                                  )
                                ],
                              )
                            ),
                          ),
                          
                          if (retailClicked) ... [
                            const SizedBox(height: 8),
                            ...retail.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length + virtualAkun.length + paymentBank.length + eWallet.length + entry.key;
                              final item = entry.value;
                              
                              final payment_name = item['payment_name'];
                              final id_pg_type = item['id_pg_type'];
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

                              return GestureDetector(
                                onTap: isDisabled
                                ? null 
                                : () async {
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
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: isDisabled ? 0.6 : 1.0,
                                      child: ColorFiltered(
                                        colorFilter: isDisabled
                                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Image.network(
                                                    "$baseUrl/image/payment-method/${item['img_web']}",
                                                    height: 70,
                                                    width: 70,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        height: 70,
                                                        width: 70,
                                                      );
                                                    },
                                                  ),

                                                  const SizedBox(width: 8,),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            // Teks akan menyesuaikan ruang sisa
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(top: 8.0),
                                                                child: Text(
                                                                  "$payment_name $id_pg_type",
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  softWrap: true,
                                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(width: 6),
                                                            // Badge region
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red.shade50,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                item['region'] ?? '',
                                                                style: TextStyle(
                                                                  color: Colors.red.shade700,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(height: 6),
                                                        if (convertedHarga < roundedValueMin)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text(
                                                              currencyCode == null
                                                                ? "${paymentLang['limit_min']} $eventCurrency ${formatter.format((roundedValueMin + 1000))}"
                                                                : "${paymentLang['limit_min']} $currencyCode ${formatter.format((roundedValueMin))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),
                                                        
                                                        if (convertedHarga > roundedValueMax)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text( limit_max == 0
                                                              ? currencyCode == null
                                                                ? "${paymentLang['limit_max']} $eventCurrency ${formatter.format((roundedValueMax + 1000))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}"
                                                              : currencyCode == null
                                                                ? "${paymentLang['limit_max']} $eventCurrency ${formatter.format((roundedValueMax))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),

                                                      ],
                                                    ),
                                                  )

                                                ],
                                              ),
                                            ],
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],

                        if (konter.isNotEmpty) ... [
                          const SizedBox(height: 20),

                          InkWell(
                            onTap: () {
                              setState(() {
                                konterClicked = !konterClicked;
                              });
                            },
                            child: Container(
                              padding: kGlobalPadding,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300,),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Counter",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Spacer(),
                                  Icon(
                                    konterClicked 
                                      ? Icons.keyboard_arrow_up 
                                      : Icons.keyboard_arrow_down,
                                  )
                                ],
                              ),
                            ),
                          ),
                          
                          if (konterClicked) ... [
                            const SizedBox(height: 8),
                            ...konter.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length + virtualAkun.length + paymentBank.length + eWallet.length + retail.length + entry.key;
                              final item = entry.value;
                              
                              final payment_name = item['payment_name'];
                              final id_pg_type = item['id_pg_type'];
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

                              return GestureDetector(
                                onTap: isDisabled
                                ? null 
                                : () async {
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
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: isDisabled ? 0.6 : 1.0,
                                      child: ColorFiltered(
                                        colorFilter: isDisabled
                                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Image.network(
                                                    "$baseUrl/image/payment-method/${item['img_web']}",
                                                    height: 70,
                                                    width: 70,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        height: 70,
                                                        width: 70,
                                                      );
                                                    },
                                                  ),

                                                  const SizedBox(width: 8,),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            // Teks akan menyesuaikan ruang sisa
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(top: 8.0),
                                                                child: Text(
                                                                  "$payment_name $id_pg_type",
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  softWrap: true,
                                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(width: 6),
                                                            // Badge region
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red.shade50,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                item['region'] ?? '',
                                                                style: TextStyle(
                                                                  color: Colors.red.shade700,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(height: 6),
                                                        if (convertedHarga < roundedValueMin)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text(
                                                              currencyCode == null
                                                                ? "${paymentLang['limit_min']} $eventCurrency ${formatter.format((roundedValueMin + 1000))}"
                                                                : "${paymentLang['limit_min']} $currencyCode ${formatter.format((roundedValueMin))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),
                                                        
                                                        if (convertedHarga > roundedValueMax)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text( limit_max == 0
                                                              ? currencyCode == null
                                                                ? "${paymentLang['limit_max']} $eventCurrency ${formatter.format((roundedValueMax + 1000))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}"
                                                              : currencyCode == null
                                                                ? "${paymentLang['limit_max']} $eventCurrency ${formatter.format((roundedValueMax))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),

                                                      ],
                                                    ),
                                                  )

                                                ],
                                              ),
                                            ],
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],

                        if (qrCode.isNotEmpty) ... [
                          const SizedBox(height: 20),

                          InkWell(
                            onTap: () {
                              setState(() {
                                qrCodeClicked = !qrCodeClicked;
                              });
                            },
                            child: Container(
                              padding: kGlobalPadding,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300,),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "QR Codes",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Spacer(),
                                  Icon(
                                    qrCodeClicked 
                                      ? Icons.keyboard_arrow_up 
                                      : Icons.keyboard_arrow_down
                                  )
                                ],
                              ),
                            ),
                          ),
                          
                          if (qrCodeClicked) ... [
                            const SizedBox(height: 8),
                            ...qrCode.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length + virtualAkun.length + paymentBank.length + eWallet.length + retail.length + konter.length + entry.key;
                              final item = entry.value;
                              
                              final payment_name = item['payment_name'];
                              final id_pg_type = item['id_pg_type'];
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

                              return GestureDetector(
                                onTap: isDisabled
                                ? null 
                                : () async {
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
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: isDisabled ? 0.6 : 1.0,
                                      child: ColorFiltered(
                                        colorFilter: isDisabled
                                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Image.network(
                                                    "$baseUrl/image/payment-method/${item['img_web']}",
                                                    height: 70,
                                                    width: 70,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        height: 70,
                                                        width: 70,
                                                      );
                                                    },
                                                  ),

                                                  const SizedBox(width: 8,),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            // Teks akan menyesuaikan ruang sisa
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(top: 8.0),
                                                                child: Text(
                                                                  "$payment_name $id_pg_type",
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  softWrap: true,
                                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(width: 6),
                                                            // Badge region
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red.shade50,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                item['region'] ?? '',
                                                                style: TextStyle(
                                                                  color: Colors.red.shade700,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(height: 6),
                                                        if (convertedHarga < roundedValueMin)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text(
                                                              currencyCode == null
                                                                ? "${paymentLang['limit_min']} $eventCurrency ${formatter.format((roundedValueMin + 1000))}"
                                                                : "${paymentLang['limit_min']} $currencyCode ${formatter.format((roundedValueMin))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),
                                                        
                                                        if (convertedHarga > roundedValueMax)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text( limit_max == 0
                                                              ? currencyCode == null
                                                                ? "${paymentLang['limit_max']} $eventCurrency ${formatter.format((roundedValueMax + 1000))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}"
                                                              : currencyCode == null
                                                                ? "${paymentLang['limit_max']} $eventCurrency ${formatter.format((roundedValueMax))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),

                                                      ],
                                                    ),
                                                  )

                                                ],
                                              ),
                                            ],
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],

                        if (debit.isNotEmpty) ... [
                          const SizedBox(height: 20),

                          InkWell(
                            onTap: () {
                              setState(() {
                                debitClicked = !debitClicked;
                              });
                            },
                            child: Container(
                              padding: kGlobalPadding,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300,),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Direct Debit",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Spacer(),
                                  Icon(
                                    debitClicked 
                                      ? Icons.keyboard_arrow_up 
                                      : Icons.keyboard_arrow_down
                                  )
                                ],
                              ),
                            ),
                          ),
                          
                          if (debitClicked) ... [
                            const SizedBox(height: 8),
                            ...debit.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length + virtualAkun.length + paymentBank.length + eWallet.length + retail.length + konter.length + qrCode.length + entry.key;
                              final item = entry.value;
                              
                              final payment_name = item['payment_name'];
                              final id_pg_type = item['id_pg_type'];
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

                              return GestureDetector(
                                onTap: isDisabled
                                ? null 
                                : () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = debit[index]['id_metod'];
                                    currencySession = debit[index]['currency_pg'];
                                  });
                                  
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
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: isDisabled ? 0.6 : 1.0,
                                      child: ColorFiltered(
                                        colorFilter: isDisabled
                                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Image.network(
                                                    "$baseUrl/image/payment-method/${item['img_web']}",
                                                    height: 70,
                                                    width: 70,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        height: 70,
                                                        width: 70,
                                                      );
                                                    },
                                                  ),

                                                  const SizedBox(width: 8,),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            // Teks akan menyesuaikan ruang sisa
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(top: 8.0),
                                                                child: Text(
                                                                  "$payment_name $id_pg_type",
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  softWrap: true,
                                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(width: 6),
                                                            // Badge region
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red.shade50,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                item['region'] ?? '',
                                                                style: TextStyle(
                                                                  color: Colors.red.shade700,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(height: 6),
                                                        if (convertedHarga < roundedValueMin)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text(
                                                              currencyCode == null
                                                                ? "${paymentLang['limit_min']} $eventCurrency ${formatter.format((roundedValueMin + 1000))}"
                                                                : "${paymentLang['limit_min']} $currencyCode ${formatter.format((roundedValueMin))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),
                                                        
                                                        if (convertedHarga > roundedValueMax)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text( limit_max == 0
                                                              ? currencyCode == null
                                                                ? "${paymentLang['limit_max']} $eventCurrency ${formatter.format((roundedValueMax + 1000))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}"
                                                              : currencyCode == null
                                                                ? "${paymentLang['limit_max']} $eventCurrency ${formatter.format((roundedValueMax))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),

                                                      ],
                                                    ),
                                                  )

                                                ],
                                              ),

                                              if (isSelected) ... [
                                                const SizedBox(height: 20,),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      color: Colors.white,
                                                      width: double.infinity,
                                                      child: TextField(
                                                        autofocus: false,
                                                        onChanged: (value) {
                                                          mobile_number = value;

                                                          _phoneDebounce?.cancel();
                                                          _phoneDebounce = Timer(const Duration(milliseconds: 700), () {
                                                            if (value.length >= 12 && _scrollController.hasClients) {
                                                              _scrollController.animateTo(
                                                                _scrollController.position.maxScrollExtent,
                                                                duration: const Duration(milliseconds: 600),
                                                                curve: Curves.easeOut,
                                                              );
                                                            }
                                                          });
                                                        },
                                                        keyboardType: TextInputType.number,
                                                        decoration: InputDecoration(
                                                          hintText: phoneHint!, //"Nomor Telepon"
                                                          hintStyle: TextStyle(color: Colors.grey.shade400),
                                                          border: OutlineInputBorder(
                                                            borderRadius: const BorderRadius.only(
                                                              topLeft: Radius.circular(8),
                                                              topRight: Radius.circular(8),
                                                            ),
                                                          ),
                                                        ),
                                                        inputFormatters: [
                                                          LengthLimitingTextInputFormatter(16),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              ]
                                            ],
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ]
                      ],
                    ),

                    if (selectedIndex != null) ...[
                      const SizedBox(height: 25),
                      Text(
                        paymentLang['detail_harga'], //"Detail Harga"
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
                              Text(paymentLang['biaya_layanan']), //"Biaya Layanan"
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
                              //"Total Bayar"
                              Text(paymentLang['total_bayar'], style: TextStyle(fontWeight: FontWeight.bold),),
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
                                        paymentLang['batal'],
                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: handleConfirm,
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        paymentLang['konfirmasi'],
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
}