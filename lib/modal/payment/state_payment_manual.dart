// ignore_for_file: non_constant_identifier_names, prefer_typing_uninitialized_variables, use_build_context_synchronously, deprecated_member_use

import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/constants.dart';
import 'package:kreen_app_flutter/helper/get_geo_location.dart';
import 'package:kreen_app_flutter/helper/get_fee_new.dart';
import 'package:kreen_app_flutter/helper/get_login_user.dart';
import 'package:kreen_app_flutter/helper/payment/payment_item.dart';
import 'package:kreen_app_flutter/modal/payment/payment_list.dart';
import 'package:kreen_app_flutter/pages/content_info/privacy_policy.dart';
import 'package:kreen_app_flutter/pages/content_info/snk_page.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/pages/vote/add_support.dart';
import 'package:kreen_app_flutter/pages/order/waiting_order_page.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:flutter/gestures.dart';

class StatePaymentManual extends StatefulWidget {
  final String id_vote;
  final List<String> ids_finalis; 
  final List<String> names_finalis; 
  final List<int> counts_finalis;
  final num totalHarga;
  final num totalHargaAsli;
  final num price;
  final bool fromDetail;
  final String? idUser;
  final String flag_login;
  final num rateCurrency;
  final num rateCurrencyUser;

  const StatePaymentManual({
    super.key,
    required this.id_vote,
    required this.ids_finalis,
    required this.names_finalis,
    required this.counts_finalis,
    required this.totalHarga,
    required this.totalHargaAsli,
    required this.price,
    required this.fromDetail,
    this.idUser,
    required this.flag_login,
    required this.rateCurrency,
    required this.rateCurrencyUser
  });

  @override
  State<StatePaymentManual> createState() => _StatePaymentManualState();
}

class _StatePaymentManualState extends State<StatePaymentManual> {
  var get_user;
  var user_id;
  var firstName;
  var lastName;
  var gender;
  var phone;
  var email;

  String? inputNama;

  Map<String, dynamic> detailVote = {};
  Map<String, dynamic> detailEvent = {};
  Map<String, dynamic> payment = {};
  List<dynamic> indikator = [];
  String? voteCurrency, eventCurrency;
  var totalPayment, feeLayanan, totalVotes;

  String? id_payment_method, mobile_number, id_card_number, card_number, expiry_month, expiry_year, cvv;

  String? id_indikator, answer;
  String? selectedGender;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  late List<TextEditingController> answerControllers;

  final bool _isChecked1 = true;
  final bool _isChecked2 = true;
  bool _isChecked3 = false;
  bool _showError = false;

  List<String> answers = [];
  List<String> ids_indikator = [];

  int? selectedIndex;
    
  final formatter = NumberFormat.decimalPattern("en_US");
  final ScrollController _scrollController = ScrollController();

  final TextEditingController expDateController = TextEditingController();
  bool _isEditing = false;

  bool isLoading = true;

  String? langCode, currencyCode, token;
  Map<String, dynamic> bahasa = {};
  String? namaLengkapLabel, namaLengkapHint;
  String? phoneLabel, phoneHint;
  String? cobaLagi, emailHint;

  Timer? _cvvDebounce, _phoneDebounce;

  String? currencySession;

  String? notLoginText, notLoginDesc, login;
  
  bool _emailTouched = false;

  bool creditCardClicked = false;
  bool virtualAkunClicked = false;
  bool paymentBankClicked = false;
  bool eWalletClicked = false;
  bool retailClicked = false;
  bool konterClicked = false;
  bool qrCodeClicked = false;
  bool debitClicked = false;

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  late List<FocusNode> indikatorFocus;
  double _genderOffset = 0;

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

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  bool isValidPhone(String phone) {
    final regex = RegExp(r'^08[0-9]{8,11}$');
    return regex.hasMatch(phone);
  }
  
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _getCurrency();
      await _checkToken();
      await getData(widget.id_vote);

      user_id = widget.idUser;
    });

    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  Future<void> _getBahasa() async {
    final lang = await StorageService.getLanguage();
    setState(() => langCode = lang);

    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");

    setState(() {
      bahasa = tempbahasa;
      namaLengkapLabel = bahasa['nama_lengkap_label'];
      namaLengkapHint = bahasa['nama_lengkap'];
      phoneLabel = bahasa['nomor_hp_label'];
      phoneHint = bahasa['nomor_hp'];
      cobaLagi = bahasa['coba_lagi'];

      emailHint = bahasa['input_email'];
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

  Future<void> getData(String idVote) async {
    final getUser = await StorageService.getUser();

    firstName = getUser['first_name'] ?? '';
    lastName = getUser['last_name'] ?? '';
    gender = getUser['gender'] ?? '';
    phone = getUser['phone'] ?? '';
    email = getUser['email'] ?? '';
    user_id = getUser['id'] ?? '';

    _nameController.text = "$firstName $lastName".trim();
    _phoneController.text = phone;
    _emailController.text = email;

    if (gender.isNotEmpty) {
      selectedGender = gender.toLowerCase() == 'male' ? bahasa['gender_1'] : bahasa['gender_2'];
    }

    final detailResp = await ApiService.get("/vote/$idVote", xLanguage: langCode, xCurrency: currencyCode);
    if (detailResp == null || detailResp['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = detailResp?['message'];
      });
      return;
    }

    final paymentResp = await ApiService.get("/vote/$idVote/payment-methods", xLanguage: langCode, xCurrency: currencyCode);
    if (paymentResp == null || paymentResp['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = paymentResp?['message'];
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      detailVote = detailResp['data'] ?? {};
      voteCurrency = detailVote['currency'];

      payment = paymentResp['data'] ?? {};

      indikator = detailVote['indikator_vote'] ?? [];
      
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

      answers = List.filled(indikator.length, '');
      ids_indikator = List.filled(indikator.length, '');
      answerControllers = List.generate(
        indikator.length,
        (index) => TextEditingController(),
      );
      indikatorFocus = List.generate(
        indikator.length,
        (_) => FocusNode(),
      );
  }
  
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isLoading
              ? const Center(
                  key: ValueKey('loading'),
                  child: CircularProgressIndicator(color: Colors.red),
                )
              : widget.flag_login == '1' 
                ? token == null 
                  ? KeyedSubtree(
                      key: const ValueKey('not-login'),
                      child: LoginPrompt(
                        bahasa: bahasa,
                        onLoginSuccess: (userId) {
                          setState(() {
                            user_id = userId;
                          });
                        },
                      ),
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

    Future<void> doConfirmProcess() async {
      
      final position = await getCurrentLocationWithValidation(context);

      if (position == null) {
        // Stop, jangan lanjut submit
        return;
      }

      final latitude = position.latitude;
      final longitude = position.longitude;
      
      bool isNameEmpty = _nameController.text.trim().isEmpty;
      bool isGenderEmpty = selectedGender == null;
      bool isCheckboxUnchecked = !_isChecked3;

      if (widget.totalHargaAsli != 0) {
        if (isNameEmpty || isGenderEmpty || isCheckboxUnchecked) {
          setState(() {
            _showError = true;
          });
          return;
        }
      } else {
        if (isNameEmpty || isGenderEmpty ) {
          setState(() {
            _showError = true;
          });
          return;
        }
      }

      // lanjutkan aksi konfirmasi
      if (widget.totalHargaAsli != 0) {

        String genderValue;
        final rawGender = selectedGender.toString().toLowerCase();

        if (rawGender == 'laki-laki' || rawGender == 'male') {
          genderValue = 'male';
        } else if (rawGender == 'perempuan' || rawGender == 'female') {
          genderValue = 'female';
        } else {
          genderValue = ''; // handle error
        }

        final body = {
          "id_vote": widget.id_vote, //  free: 65aa23e7eea47 // paid: 65aa22cda9ec2
          "id_user": user_id ?? '',
          "id_paket": '',
          "nama_voter": _nameController.text.trim(),
          "email_voter": email ?? _emailController.text.trim(),
          "gender": genderValue,
          "latitude": latitude,
          "longitude": longitude,
          "finalis": List.generate(
            widget.ids_finalis.length,
            (index) => {
              "id_finalis": widget.ids_finalis[index],
              "qty": widget.counts_finalis[index],
            },
          ),
          "payment_method": {
            "id_payment_method": id_payment_method,
            "mobile_number": mobile_number,
            "id_card_number": id_card_number,
            "card_number": card_number,
            "expiry_month": expiry_month,
            "expiry_year": expiry_year,
            "cvv": cvv
          },
          "indikator": List.generate(
            ids_indikator.length, (index) => {
              "id_indikator": ids_indikator[index],
              "answer": answers[index]
            },
          ),
        };

        var resultVoteOrder = await ApiService.post("/order/vote/checkout", body: body, xLanguage: langCode);

        if (resultVoteOrder != null) {
          if (resultVoteOrder['rc'] == 200) {
            final tempOrder = resultVoteOrder['data'];

            var id_order = tempOrder['id_order'];
            Navigator.pop(context);//tutup modal

            if (widget.fromDetail) {
              Navigator.pop(context);//tutup page detail finalis
            }

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => WaitingOrderPage(id_order: id_order, formHistory: false, currency_session: currencyCode)),
            );
          } else if (resultVoteOrder['rc'] == 422) {
            final data = resultVoteOrder['data'];
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
          } else if (resultVoteOrder['rc'] == 400) {
            AwesomeDialog(
              context: context,
              dialogType: DialogType.error,
              animType: AnimType.topSlide,
              title: 'Oops!',
              desc: "${resultVoteOrder['message']}",
              btnOkOnPress: () {},
              btnOkColor: Colors.red,
              buttonsTextStyle: TextStyle(color: Colors.white),
              headerAnimationLoop: false,
              dismissOnTouchOutside: true,
              showCloseIcon: true,
            ).show();
          } else if (resultVoteOrder['rc'] == 500) {
            AwesomeDialog(
              context: context,
              dialogType: DialogType.error,
              animType: AnimType.topSlide,
              title: 'Oops!',
              desc: "${resultVoteOrder['message']}\n${bahasa['another_payment']}",
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
            buttonsTextStyle: TextStyle(color: Colors.white),
            headerAnimationLoop: false,
            dismissOnTouchOutside: true,
            showCloseIcon: true,
          ).show();
        }
      } else {

        String genderValue;
        final rawGender = selectedGender.toString().toLowerCase();

        if (rawGender == 'laki-laki' || rawGender == 'male') {
          genderValue = 'male';
        } else if (rawGender == 'perempuan' || rawGender == 'female') {
          genderValue = 'female';
        } else {
          genderValue = ''; // handle error
        }

        final body = {
          "id_vote": widget.id_vote, //  free: 65aa23e7eea47 // paid: 65aa22cda9ec2
          "id_user": user_id ?? '',
          "id_paket": '',
          "nama_voter": _nameController.text.trim(),
          "email_voter": email ?? _emailController.text.trim(),
          "gender": genderValue,
          "latitude": latitude,
          "longitude": longitude,
          "finalis": List.generate(
            widget.ids_finalis.length,
            (index) => {
              "id_finalis": widget.ids_finalis[index],
              "qty": widget.counts_finalis[index],
            },
          ),
          "indikator": List.generate(
            ids_indikator.length, (index) => {
              "id_indikator": ids_indikator[index],
              "answer": answers[index]
            },
          ),
        };

        var resultVoteOrder = await ApiService.post("/order/vote/checkout", body: body, xLanguage: langCode);
        if (resultVoteOrder == null || resultVoteOrder['rc'] != 200) {
          setState(() {
            showErrorBar = true;
            errorMessage = resultVoteOrder?['message'];
          });
        }

        if (resultVoteOrder != null) {
          if (resultVoteOrder['rc'] == 200) {
            final tempOrder = resultVoteOrder['data'];

            var id_order = tempOrder['id_order'];
            Navigator.pop(context);//tutup modal

            if (widget.fromDetail) {
              Navigator.pop(context);//tutup page detail finalis
            }

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddSupportPage(id_order: id_order, id_vote: widget.id_vote, nama: _nameController.text,)),
            );
          } else if (resultVoteOrder['rc'] == 422) {
            final data = resultVoteOrder['data'];
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
          }  else if (resultVoteOrder['rc'] == 500) {
            AwesomeDialog(
              context: context,
              dialogType: DialogType.error,
              animType: AnimType.topSlide,
              title: 'Oops!',
              desc: "${resultVoteOrder['message']}\n${bahasa['another_payment']}",
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
            buttonsTextStyle: TextStyle(color: Colors.white),
            headerAnimationLoop: false,
            dismissOnTouchOutside: true,
            showCloseIcon: true,
          ).show();
        }
      } 
    }

    void handleConfirm() async {
      if (isConfirmLoading) return;

      setState(() {
        _showError = true;
      });

      final isValid = _validateAllForm();

      for (var i = 0; i < indikator.length; i++) {
        if (indikator[i]['type_form'] != 'file') {
          answers[i] = answerControllers[i].text.trim();
        }
      }

      if (!isValid) {
        return;
      }

      setState(() {
        isConfirmLoading = true;
      });

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

    final genders = [
      {'label': bahasa['gender_1'], 'icon': '$baseUrl/image/male.png'},
      {'label': bahasa['gender_2'], 'icon': '$baseUrl/image/female.png'},
    ];

    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        child: SafeArea(
          child: SizedBox(
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
        ),
      ),

      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bahasa['header'],
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
                  child: Container(
                    color: Colors.white,
                    padding: kGlobalPadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
          
                        const SizedBox(height: 4),
                        //konten
                        Text(
                          bahasa['sub_titel_1'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          bahasa['sub_titel_2'],
                        ),
          
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              namaLengkapLabel!
                            ),
                            Text(
                              "*", style: TextStyle(color: Colors.red)
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _nameController,
                          onChanged: (value) {
                            // _nameController.text = value;
                            inputNama = value;
                          },
                          autofocus: false,
                          focusNode: _nameFocus,
                          decoration: InputDecoration(
                            hintText: namaLengkapHint!,
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: _border(_nameController.text.isNotEmpty),
                            focusedBorder: _border(true),
                          ),
                        ),
                        if (_showError && _nameController.text.trim().isEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              bahasa['nama_lengkap_error'],
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
          
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              bahasa['gender_label']
                            ),
                            Text(
                              "*", style: TextStyle(color: Colors.red)
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final box = context.findRenderObject() as RenderBox?;
                              if (box != null) {
                                final position = box.localToGlobal(Offset.zero);
                                _genderOffset = position.dy + _scrollController.offset;
                              }
                            });
          
                            return Row(
                              children: List.generate(genders.length, (index) {
                                final item = genders[index];
                                final isSelectedGender = selectedGender == item['label'];
          
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedGender = item['label'];
                                        gender = item['label'];
                                      });
                                    },
                                    child: Container(
                                      height: 120,
                                      margin: EdgeInsets.only(
                                        right: index == 0 ? 8 : 0,
                                        left: index == 1 ? 8 : 0,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade300),
                                        color: isSelectedGender ? Colors.green.withOpacity(0.1) : Colors.white,
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
                                                width: 50,
                                                height: 50,
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
                            );
                          }
                        ),
          
                        if (_showError && selectedGender == null)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              bahasa['gender_error'],
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
          
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              "Email",
                            ),
                            Text(
                              indikator.any((e) => e['id_indikator_vote'] == 12) ? '*' : '',
                              style: TextStyle(color: Colors.red)
                            ),
                          ],
                        ),
          
                        const SizedBox(height: 4),
                        TextField(
                          autofocus: false,
                          controller: _emailController,
                          focusNode: _emailFocus,
                          onChanged: (value) {
                            if (!_emailTouched) {
                              setState(() => _emailTouched = true);
                            } else {
                              setState(() {});
                            }
                            _emailController.text = value;
                          },
                          decoration: InputDecoration(
                            hintText: emailHint!,
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: _border(_emailController.text.isNotEmpty),
                            focusedBorder: _border(true),
                            errorText: _emailTouched && !isValidEmail(_emailController.text)
                              ? bahasa['error_email_1']
                              : null,
                          ),
                        ),
          
                        if (_showError && indikator.any((e) => e['id_indikator_vote'] == 12) && _emailController.text.trim().isEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              bahasa['error_email_3'],
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
          
                        if (indikator.isEmpty || indikatorFocus.length != indikator.length) ... [
                          SizedBox(),
                        ] else ... [
                          const SizedBox(height: 12),
                          ...List.generate(indikator.length, (idx) {
                            final item = indikator[idx];
                            final label = item['indikator_vote'] ?? '';
                            final typeInput = item['type_input'] ?? 'text';
                            final isPhoneField = label.toLowerCase().contains('hp');
                            final isEmailField = label.toLowerCase().contains('email');
                            final id_indikator_vote = item['id_indikator_vote'];
                            ids_indikator[idx] = id_indikator_vote.toString();
                            if (ids_indikator[idx] == '1') {
                              answers[idx] = _phoneController.text;
                            } else if (ids_indikator[idx] == '12') {
                              answers[idx] = _emailController.text;
                            } else {
                              answers[idx] = answerControllers[idx].text;
                            }
            
                            if (id_indikator_vote == 12) {
                              return const SizedBox.shrink();
                            }
            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(label),
                                    const Text(
                                      "*",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
            
                                const SizedBox(height: 4),
                                TextField(
                                  autofocus: false,
                                  controller: isPhoneField 
                                    ? _phoneController 
                                    : isEmailField 
                                      ? _emailController 
                                      : answerControllers[idx],
                                  focusNode: isPhoneField 
                                    ? _phoneFocus 
                                    : isEmailField 
                                      ? _emailFocus 
                                      : indikatorFocus[idx],
                                  onChanged: (value) {
                                    // answerControllers[idx].text = value;
                                    answers[idx] = value;
                                  },
                                  keyboardType: typeInput == 'number'
                                      ? TextInputType.number
                                      : TextInputType.text,
                                  decoration: InputDecoration(
                                    hintText: "${bahasa['hint_label_indikator_1']} $label ${bahasa['hint_label_indikator_2']}",
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
            
                                if (isPhoneField) ... [
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.blue,),
                                      Text(
                                        bahasa['warning_indikator_phone'],
                                        style: TextStyle(color: Colors.blue),
                                      )
                                    ],
                                  ),
                                  if (_showError && _phoneController.text.trim().isEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        bahasa['error_indikator_phone'],
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                ] else if (isEmailField) ... [
                                  if (_showError && _emailController.text.trim().isEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        bahasa['error_email_3'],
                                        style: TextStyle(color: Colors.red),
                                      ),
                                  )                    
                                ] else ... [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      bahasa['tiket_template_answer_error'],
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  )
                                ]
                              ],
                            );
                          }),
                        ],
          
                        const SizedBox(height: 20,),
                        const Divider(
                          thickness: 1,
                          color: Color.fromARGB(255, 224, 224, 224),
                        ),
          
                        //pembayaran
                        if (widget.totalHargaAsli != 0) ...[
                          const SizedBox(height: 20,),
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
                            bahasa['pilih_payment'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            bahasa['sub_pilih_payment'],
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

                                    return PaymentItem(
                                      paymentTipe: "credit_card",
                                      item: item,
                                      idx: idx,

                                      isSelected: isSelected,
                                      isDisabled: isDisabled,

                                      currencyCode: currencyCode,
                                      voteCurrency: voteCurrency,

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
                                        _cvvDebounce = Timer(const Duration(milliseconds: 700), () {
                                          if (val.length == 3 && _scrollController.hasClients) {
                                            _scrollController.animateTo(
                                              _scrollController.position.maxScrollExtent,
                                              duration: const Duration(milliseconds: 600),
                                              curve: Curves.easeOut,
                                            );
                                          }
                                        });
                                      },

                                      onTap: () async {
                                        setState(() {
                                          selectedIndex = idx;
                                          id_payment_method = creditCard[idx]['id_metod'];
                                          currencySession = creditCard[idx]['currency_pg'];
                                        });

                                        var resultFee = await getFeeNew(
                                          currencyCode!,
                                          voteCurrency!,
                                          item['currency_pg'],
                                          widget.totalHargaAsli,
                                          item['fee_percent'],
                                          item['ppn'],
                                          item['fee'],
                                          item['exchange_rate_new'],
                                          widget.counts_finalis,
                                          item['rate'],
                                          widget.rateCurrency,
                                          widget.rateCurrencyUser,
                                        );

                                        setState(() {
                                          totalPayment = resultFee!['total_payment'];
                                          feeLayanan = (resultFee['fee_layanan'] * 100).ceil() / 100;
                                          totalVotes = resultFee['total_votes'];
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
                                      voteCurrency: voteCurrency,

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
                                          voteCurrency!, 
                                          item['currency_pg'], 
                                          widget.totalHargaAsli, 
                                          item['fee_percent'], 
                                          item['ppn'], 
                                          item['fee'], 
                                          item['exchange_rate_new'], 
                                          widget.counts_finalis, 
                                          item['rate'], 
                                          widget.rateCurrency, 
                                          widget.rateCurrencyUser);
                                        
                                        setState(() {
                                          totalPayment = resultFee!['total_payment'];
                                          feeLayanan = (resultFee['fee_layanan'] * 100).ceil() / 100;
                                          totalVotes = resultFee['total_votes'];
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
                                      voteCurrency: voteCurrency, 
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
                                          voteCurrency!, 
                                          item['currency_pg'], 
                                          widget.totalHargaAsli, 
                                          item['fee_percent'], 
                                          item['ppn'], 
                                          item['fee'], 
                                          item['exchange_rate_new'], 
                                          widget.counts_finalis, 
                                          item['rate'], 
                                          widget.rateCurrency, 
                                          widget.rateCurrencyUser);
                                        
                                        setState(() {
                                          totalPayment = resultFee!['total_payment'];
                                          feeLayanan = (resultFee['fee_layanan'] * 100).ceil() / 100;
                                          totalVotes = resultFee['total_votes'];
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
                                      voteCurrency: voteCurrency, 
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
                                          voteCurrency!, 
                                          item['currency_pg'], 
                                          widget.totalHargaAsli, 
                                          item['fee_percent'], 
                                          item['ppn'], 
                                          item['fee'], 
                                          item['exchange_rate_new'], 
                                          widget.counts_finalis, 
                                          item['rate'], 
                                          widget.rateCurrency, 
                                          widget.rateCurrencyUser);
                                        
                                        setState(() {
                                          totalPayment = resultFee!['total_payment'];
                                          feeLayanan = (resultFee['fee_layanan'] * 100).ceil() / 100;
                                          totalVotes = resultFee['total_votes'];
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
                                      voteCurrency: voteCurrency, 
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
                                          voteCurrency!, 
                                          item['currency_pg'], 
                                          widget.totalHargaAsli, 
                                          item['fee_percent'], 
                                          item['ppn'], 
                                          item['fee'], 
                                          item['exchange_rate_new'], 
                                          widget.counts_finalis, 
                                          item['rate'], 
                                          widget.rateCurrency, 
                                          widget.rateCurrencyUser);
                                        
                                        setState(() {
                                          totalPayment = resultFee!['total_payment'];
                                          feeLayanan = (resultFee['fee_layanan'] * 100).ceil() / 100;
                                          totalVotes = resultFee['total_votes'];
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
                                      voteCurrency: voteCurrency, 
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
                                          voteCurrency!, 
                                          item['currency_pg'], 
                                          widget.totalHargaAsli, 
                                          item['fee_percent'], 
                                          item['ppn'], 
                                          item['fee'], 
                                          item['exchange_rate_new'], 
                                          widget.counts_finalis, 
                                          item['rate'], 
                                          widget.rateCurrency, 
                                          widget.rateCurrencyUser);
                                        
                                        setState(() {
                                          totalPayment = resultFee!['total_payment'];
                                          feeLayanan = (resultFee['fee_layanan'] * 100).ceil() / 100;
                                          totalVotes = resultFee['total_votes'];
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
                                      voteCurrency: voteCurrency, 
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
                                          voteCurrency!, 
                                          item['currency_pg'], 
                                          widget.totalHargaAsli, 
                                          item['fee_percent'], 
                                          item['ppn'], 
                                          item['fee'], 
                                          item['exchange_rate_new'], 
                                          widget.counts_finalis, 
                                          item['rate'], 
                                          widget.rateCurrency, 
                                          widget.rateCurrencyUser);
                                        
                                        setState(() {
                                          totalPayment = resultFee!['total_payment'];
                                          feeLayanan = (resultFee['fee_layanan'] * 100).ceil() / 100;
                                          totalVotes = resultFee['total_votes'];
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
                                      voteCurrency: voteCurrency, 
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
          
                                        // final resultFee = await getFee(voteCurrency!, item['currency_pg'], widget.totalHargaAsli, item['fee_percent'], item['ppn'], item['fee'], item['exchange_rate_new'], widget.counts_finalis);
                                        var resultFee = await getFeeNew(
                                          currencyCode!,
                                          voteCurrency!, 
                                          item['currency_pg'], 
                                          widget.totalHargaAsli, 
                                          item['fee_percent'], 
                                          item['ppn'], 
                                          item['fee'], 
                                          item['exchange_rate_new'], 
                                          widget.counts_finalis, 
                                          item['rate'], 
                                          widget.rateCurrency, 
                                          widget.rateCurrencyUser);
                                        
                                        setState(() {
                                          totalPayment = resultFee!['total_payment'];
                                          feeLayanan = (resultFee['fee_layanan'] * 100).ceil() / 100;
                                          totalVotes = resultFee['total_votes'];
                                        });
                                      },
                                      onPhoneChanged: (val){
                                        mobile_number = val;
          
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
                              bahasa['detail_harga'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
          
                            const SizedBox(height: 16,),
                            ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: widget.names_finalis.length,
                              itemBuilder: (context, index) {
                                final int count = widget.counts_finalis[index];
                                num hargaVote = count * widget.price;
                                hargaVote = hargaVote * (widget.rateCurrencyUser / widget.rateCurrency);
                                if (currencyCode == "IDR") {
                                  hargaVote = hargaVote.ceil();
                                } else {
                                  hargaVote = (100 * hargaVote).ceil() / 100;
                                }
          
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index == widget.names_finalis.length - 1 ? 0 : 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${widget.names_finalis[index]} ($count vote(s)",
                                      ),
                                      Text(
                                        currencyCode == null
                                            ? "$voteCurrency ${formatter.format(hargaVote)}"
                                            : "$currencyCode ${formatter.format(hargaVote)}",
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
          
                            const SizedBox(height: 16,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(bahasa['biaya_layanan']),
                                Text(
                                  currencyCode == null
                                  ? '$voteCurrency ${formatter.format(feeLayanan)}'
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
                                Text(bahasa['total_bayar'], style: TextStyle(fontWeight: FontWeight.bold),),
                                Text(
                                  currencyCode == null
                                  ? "$voteCurrency ${formatter.format(totalPayment)}"
                                  : "$currencyCode ${formatter.format(totalPayment)}", 
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
          
                            const SizedBox(height: 20,),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade300),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.help, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        text: bahasa['masalah'],
                                        style: TextStyle(color: Colors.black),
                                        children: [
                                          TextSpan(
                                            text: bahasa['bantuan'],
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
          
                            const SizedBox(height: 16,),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                border: Border.all(color: Colors.red.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      bahasa['vote_final'],
                                      style: TextStyle(
                                        color: Colors.red.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
          
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _isChecked1,
                                  onChanged: null,
                                  activeColor: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
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
                                  ),
                                ),
                              ],
                            ),
          
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _isChecked2,
                                  onChanged: null,
                                  activeColor: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    selectionColor: Colors.black,
                                    text: TextSpan(
                                      style: TextStyle(color: Colors.black),
                                      children: [
                                        TextSpan(
                                          text: bahasa['setuju_syarat'],
                                        )
                                      ]
                                    )
                                  ),
                                ),
                              ],
                            ),
                              
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _isChecked3,
                                  onChanged: (value) {
                                    setState(() {
                                      _isChecked3 = value ?? false;
                                      if (_isChecked3) _showError = false;
                                    });
                                  },
                                  activeColor: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isChecked3 = !_isChecked3;
                                      });
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(color: Colors.black),
                                        children: [
                                          TextSpan(text: bahasa['kebijakan_privasi_7']),
                                          TextSpan(text: "$totalVotes ${bahasa['text_vote']}", style: TextStyle(fontWeight: FontWeight.bold)),
                                          TextSpan(text: bahasa['kebijakan_privasi_8']),
                                          TextSpan(
                                              text: currencyCode == null
                                                ? "$voteCurrency ${formatter.format(totalPayment)}"
                                                : "$currencyCode ${formatter.format(totalPayment)}",
                                              style: TextStyle(fontWeight: FontWeight.bold)),
                                          TextSpan(
                                              text:
                                                  bahasa['kebijakan_privasi_9']),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
          
                            const SizedBox(height: 4),
                            if (_showError && !_isChecked3)
                              Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  bahasa['checkbox_error'],
                                  style: TextStyle(
                                      color: Colors.red),
                                ),
                              ),
          
                          // dulunya posisi button konfirmasi di sini
                          ]
                        ]
          
                        else ... [
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _isChecked1,
                                onChanged: null,
                                activeColor: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
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
                                ),
                              ),
                            ],
                          ),
          
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _isChecked2,
                                onChanged: null,
                                activeColor: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  selectionColor: Colors.black,
                                  text: TextSpan(
                                    style: TextStyle(color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: bahasa['setuju_syarat'],
                                      )
                                    ]
                                  )
                                ),
                              ),
                            ],
                          ),
                          // dulunya posisi button konfirmasi di sini
                        ],
          
                        const SizedBox(height: 4),
                        if (widget.totalHargaAsli != 0) ... [
                          if (_showError && selectedIndex == null)
                            Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                bahasa['checkbox_error'],
                                style: TextStyle(
                                    color: Colors.red),
                              ),
                            ),
                        ]
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  
  OutlineInputBorder _border(bool isFilled) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300,),
    );
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    for (var f in indikatorFocus) {
      f.dispose();
    }
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();

    for (var c in answerControllers) {
      c.dispose();
    }

    super.dispose();
  }

  bool _validateAllForm() {
    bool isValid = true;
    FocusNode? firstErrorFocus;
    bool genderError = false;
    bool agreementError = false;
    bool paymentError = false;

    // nama
    if (_nameController.text.trim().isEmpty) {
      isValid = false;
      firstErrorFocus ??= _nameFocus;
    }

    // gender
    if (selectedGender == null) {
      isValid = false;
      genderError = true;
    }
    

    if (indikator.isNotEmpty) {

      // email
      if (_emailController.text.trim().isEmpty ||
          !isValidEmail(_emailController.text)) {
        isValid = false;
        firstErrorFocus ??= _emailFocus;
      }

      // phone
      if (_phoneController.text.trim().isEmpty ||
          !isValidPhone(_phoneController.text)) {
        isValid = false;
        firstErrorFocus ??= _phoneFocus;
      }
    }

    // form indokator
    for (int j = 0; j < indikator.length; j++) {
      if (indikator[j]['required'] == 1 &&
          answers[j].toString().trim().isEmpty) {
        isValid = false;
        firstErrorFocus ??= indikatorFocus[j];
        break;
      }
    }

    if (widget.totalHargaAsli != 0) {
      if (selectedIndex == null) {
        isValid = false;
        paymentError = true;
      }
    }

    if (widget.totalHargaAsli != 0 && !_isChecked3) {
      isValid = false;
      agreementError = true;
    }

    if (!isValid) {
      if (firstErrorFocus != null) {
        _scrollToFocus(firstErrorFocus);
      } 
      else if (genderError) {
        _scrollController.animateTo(
          _genderOffset - 80,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } 
      else if (paymentError) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
      else if (agreementError) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    }

    return isValid;
  }

  void _scrollToFocus(FocusNode node) {
    node.requestFocus();

    final context = node.context;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
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