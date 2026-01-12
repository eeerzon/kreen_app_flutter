// ignore_for_file: non_constant_identifier_names, prefer_typing_uninitialized_variables, use_build_context_synchronously, deprecated_member_use

import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/helper/get_geo_location.dart';
import 'package:kreen_app_flutter/modal/payment/get_fee_new.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/pages/vote/add_support.dart';
import 'package:kreen_app_flutter/pages/vote/waiting_order_page.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

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
    
  final formatter = NumberFormat.decimalPattern("id_ID");
  final ScrollController _scrollController = ScrollController();

  final TextEditingController expDateController = TextEditingController();
  bool _isEditing = false;

  bool isLoading = true;

  String? langCode, currencyCode, token;
  Map<String, dynamic> paymentLang = {};
  Map<String, dynamic> detailVoteLang = {};
  Map<String, dynamic> eventLang = {};
  String? namaLengkapLabel, namaLengkapHint;
  String? phoneLabel, phoneHint;
  String? cobaLagi;

  Timer? _phoneDebounce;

  String? currencySession;

  String? notLoginText, notLoginDesc, login;

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
      await loadData();

      user_id = widget.idUser;
    });

    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  Future<void> loadData() async {

    answers = List.filled(indikator.length, '');
    ids_indikator = List.filled(indikator.length, '');
    answerControllers = List.generate(
      indikator.length,
      (index) => TextEditingController(),
    );

    setState(() {
      isLoading = false;
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
    final tempeventLang = await LangService.getJsonData(langCode!, "event");

    setState(() {
      paymentLang = tempPayment;
      namaLengkapLabel = tempnamalabel;
      namaLengkapHint = tempnamahint;
      phoneLabel = tempnohplabel;
      phoneHint = tempnohphint;
      cobaLagi = tempcobalagi;

      detailVoteLang = tempdetailvote;
      eventLang = tempeventLang;
    });
  }

  Future<void> _getCurrency() async {
    final currency = await StorageService.getCurrency();
    setState(() => currencyCode = currency);
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
      selectedGender = gender.toLowerCase() == 'male' ? paymentLang['gender_1'] : paymentLang['gender_2'];
    }

    final detailResp = await ApiService.get("/vote/$idVote", xLanguage: langCode, xCurrency: currencyCode);
    final paymentResp = await ApiService.get("/vote/$idVote/payment-methods");

    detailVote = detailResp?['data'] ?? {};
    voteCurrency = detailVote['currency'];

    payment = paymentResp?['data'] ?? {};

    indikator = detailVote['indikator_vote'] ?? [];
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
      backgroundColor: Colors.white,
      body: isLoading 
      ? const Center(child: CircularProgressIndicator(color: Colors.red,)) 
      : AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: widget.flag_login == '1' 
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
                
                final getUser = await StorageService.getUser();
                if (mounted) {
                  setState(() {
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
          "email_voter": email,
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

        var resultVoteOrder = await ApiService.post("/order/vote/checkout", body: body);

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
          } else if (resultVoteOrder['rc'] == 500) {
            AwesomeDialog(
              context: context,
              dialogType: DialogType.error,
              animType: AnimType.topSlide,
              title: 'Oops!',
              desc: "${resultVoteOrder['message']}\n${paymentLang['another_payment']}",
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
          "email_voter": email,
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

        var resultVoteOrder = await ApiService.post("/order/vote/checkout", body: body);

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
              desc: "${resultVoteOrder['message']}\n${paymentLang['another_payment']}",
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

    final genders = [
      {'label': paymentLang['gender_1'], 'icon': '$baseUrl/image/male.png'},
      {'label': paymentLang['gender_2'], 'icon': '$baseUrl/image/female.png'},
    ];
    
    final creditCard = payment['Credit Card'] ?? [];
    final virtualAkun = payment['Virtual Account'] ?? [];
    final paymentBank = payment['Payment Bank'] ?? [];
    final eWallet = payment['E-Wallet'] ?? [];
    final retail = payment['Retail'] ?? [];
    final konter = payment['Counter'] ?? [];
    final qrCode = payment['QR Codes'] ?? [];
    final debit = payment['Direct Debit'] ?? [];

    return Padding(
      padding: EdgeInsets.only(top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: kGlobalPadding,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  paymentLang['header'],
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
                      paymentLang['sub_titel_1'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      paymentLang['sub_titel_2'],
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
                          paymentLang['nama_lengkap_error'],
                          style: TextStyle(color: Colors.red),
                        ),
                      ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          paymentLang['gender_label']
                        ),
                        Text(
                          "*", style: TextStyle(color: Colors.red)
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
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
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
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
                    if (_showError && selectedGender == null)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          paymentLang['gender_error'],
                          style: TextStyle(color: Colors.red),
                        ),
                      ),

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
                            onChanged: (value) {
                              // answerControllers[idx].text = value;
                              answers[idx] = value;
                            },
                            keyboardType: typeInput == 'number'
                                ? TextInputType.number
                                : TextInputType.text,
                            decoration: InputDecoration(
                              hintText: "${paymentLang['hint_label_indikator_1']} $label ${paymentLang['hint_label_indikator_2']}",
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
                                  paymentLang['warning_indikator_phone'],
                                  style: TextStyle(color: Colors.blue),
                                )
                              ],
                            ),
                            if (_showError && _phoneController.text.trim().isEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  paymentLang['error_indikator_phone'],
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                          ] else if (isEmailField) ... [
                            if (_showError && _emailController.text.trim().isEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  eventLang['error_email_3'],
                                  style: TextStyle(color: Colors.red),
                                ),
                            )                    
                          ] else ... [
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                eventLang['tiket_template_answer_error'],
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          ]
                        ],
                      );
                    }),

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
                        paymentLang['pilih_payment'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        paymentLang['sub_pilih_payment'],
                      ),

                      const SizedBox(height: 12,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (creditCard.isNotEmpty) ... [
                            const Text(
                              "International Payments",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),

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
                                            border: Border.all(color: Colors.grey.shade300),
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
                                                                ? "${paymentLang['limit_min']} $voteCurrency ${formatter.format((roundedValueMin + 1000))}"
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
                                                                ? "${paymentLang['limit_max']} $voteCurrency ${formatter.format((roundedValueMax + 1000))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}"
                                                              : currencyCode == null
                                                                ? "${paymentLang['limit_max']} $voteCurrency ${formatter.format((roundedValueMax))}"
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
                                                      paymentLang['kartu_credit'],
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

                          if (virtualAkun.isNotEmpty) ... [
                            const SizedBox(height: 20),

                            const Text(
                              "Virtual Account",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),

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
                                            border: Border.all(color: Colors.grey.shade300),
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
                                                                ? "${paymentLang['limit_min']} $voteCurrency ${formatter.format((roundedValueMin + 1000))}"
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
                                                                ? "${paymentLang['limit_max']} $voteCurrency ${formatter.format((roundedValueMax + 1000))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}"
                                                              : currencyCode == null
                                                                ? "${paymentLang['limit_max']} $voteCurrency ${formatter.format((roundedValueMax))}"
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

                          if (paymentBank.isNotEmpty) ... [
                            const SizedBox(height: 20),

                            const Text(
                              "Payment Bank",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),

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
                                            border: Border.all(color: Colors.grey.shade300),
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
                                                                ? "${paymentLang['limit_min']} $voteCurrency ${formatter.format((roundedValueMin + 1000))}"
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
                                                                ? "${paymentLang['limit_max']} $voteCurrency ${formatter.format((roundedValueMax + 1000))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}"
                                                              : currencyCode == null
                                                                ? "${paymentLang['limit_max']} $voteCurrency ${formatter.format((roundedValueMax))}"
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

                          if (eWallet.isNotEmpty) ... [
                            const SizedBox(height: 20),

                            const Text(
                              "E-Wallet",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),

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
                                            border: Border.all(color: Colors.grey.shade300),
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
                                                                ? "${paymentLang['limit_min']} $voteCurrency ${formatter.format((roundedValueMin + 1000))}"
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
                                                                ? "${paymentLang['limit_max']} $voteCurrency ${formatter.format((roundedValueMax + 1000))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}"
                                                              : currencyCode == null
                                                                ? "${paymentLang['limit_max']} $voteCurrency ${formatter.format((roundedValueMax))}"
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

                          if (retail.isNotEmpty) ... [
                            const SizedBox(height: 20),

                            const Text(
                              "Retail",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),

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
                                            border: Border.all(color: Colors.grey.shade300),
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
                                                                ? "${paymentLang['limit_min']} $voteCurrency ${formatter.format((roundedValueMin + 1000))}"
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
                                                                ? "${paymentLang['limit_max']} $voteCurrency ${formatter.format((roundedValueMax + 1000))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}"
                                                              : currencyCode == null
                                                                ? "${paymentLang['limit_max']} $voteCurrency ${formatter.format((roundedValueMax))}"
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

                          if (konter.isNotEmpty) ... [
                            const SizedBox(height: 20),

                            const Text(
                              "Counter",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),

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
                                            border: Border.all(color: Colors.grey.shade300),
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
                                                                ? "${paymentLang['limit_min']} $voteCurrency ${formatter.format((roundedValueMin + 1000))}"
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
                                                                ? "${paymentLang['limit_max']} $voteCurrency ${formatter.format((roundedValueMax + 1000))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}"
                                                              : currencyCode == null
                                                                ? "${paymentLang['limit_max']} $voteCurrency ${formatter.format((roundedValueMax))}"
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

                          if (qrCode.isNotEmpty) ... [
                            const SizedBox(height: 20),

                            const Text(
                              "QR Codes",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),

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
                                            border: Border.all(color: Colors.grey.shade300),
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
                                                                ? "${paymentLang['limit_min']} $voteCurrency ${formatter.format((roundedValueMin + 1000))}"
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
                                                                ? "${paymentLang['limit_max']} $voteCurrency ${formatter.format((roundedValueMax + 1000))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}"
                                                              : currencyCode == null
                                                                ? "${paymentLang['limit_max']} $voteCurrency ${formatter.format((roundedValueMax))}"
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

                          if (debit.isNotEmpty) ... [
                            const SizedBox(height: 20),

                            const Text(
                              "Direct Debit",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),

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
                                            border: Border.all(color: Colors.grey.shade300),
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
                                                                ? "${paymentLang['limit_min']} $voteCurrency ${formatter.format((roundedValueMin + 1000))}"
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
                                                                ? "${paymentLang['limit_max']} $voteCurrency ${formatter.format((roundedValueMax + 1000))}"
                                                                : "${paymentLang['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}"
                                                              : currencyCode == null
                                                                ? "${paymentLang['limit_max']} $voteCurrency ${formatter.format((roundedValueMax))}"
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
                                                          hintText: phoneHint!,
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
                          ]
                        ],
                      ),

                      if (selectedIndex != null) ...[
                        const SizedBox(height: 25),
                        Text(
                          paymentLang['detail_harga'],
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
                            hargaVote = (100 * hargaVote).ceil() / 100;

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
                            Text(paymentLang['biaya_layanan']),
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
                            Text(paymentLang['total_bayar'], style: TextStyle(fontWeight: FontWeight.bold),),
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
                                    text: paymentLang['masalah'],
                                    style: TextStyle(color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: paymentLang['bantuan'],
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
                                  paymentLang['vote_final'],
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
                                    TextSpan(text: paymentLang['kebijakan_privasi_1']),
                                    TextSpan(
                                        text: "KREEN ",),
                                    TextSpan(
                                        text:
                                            paymentLang['kebijakan_privasi_2']),
                                    TextSpan(
                                        text: paymentLang['kebijakan_privasi_3'],
                                        style: TextStyle(color: Colors.red)),
                                    TextSpan(text: paymentLang['kebijakan_privasi_4']),
                                    TextSpan(
                                        text: paymentLang['kebijakan_privasi_5'],
                                        style: TextStyle(color: Colors.red)),
                                    TextSpan(text: paymentLang['kebijakan_privasi_6']),
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
                                      text: paymentLang['setuju_syarat'],
                                    )
                                  ]
                                )
                              ),
                            ),
                          ],
                        ),
                          
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
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(color: Colors.black),
                                  children: [
                                    TextSpan(text: paymentLang['kebijakan_privasi_7']),
                                    TextSpan(text: "$totalVotes ${detailVoteLang['text_vote']}", style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: paymentLang['kebijakan_privasi_8']),
                                    TextSpan(
                                        text: currencyCode == null
                                          ? "$voteCurrency ${formatter.format(totalPayment)}"
                                          : "$currencyCode ${formatter.format(totalPayment)}",
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(
                                        text:
                                            paymentLang['kebijakan_privasi_9']),
                                  ],
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
                              paymentLang['checkbox_error'],
                              style: TextStyle(
                                  color: Colors.red),
                            ),
                          ),

                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isChecked3 ? Colors.red : Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: handleConfirm,
                            child: Text(
                              paymentLang['konfirmasi'],
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(paymentLang['batal']),
                          ),
                        ),

                        const SizedBox(height: 12),
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
                                  TextSpan(text: paymentLang['kebijakan_privasi_1']),
                                  TextSpan(
                                      text: "KREEN ",),
                                  TextSpan(
                                      text:
                                          paymentLang['kebijakan_privasi_2']),
                                  TextSpan(
                                      text: paymentLang['kebijakan_privasi_3'],
                                      style: TextStyle(color: Colors.red)),
                                  TextSpan(text: paymentLang['kebijakan_privasi_4']),
                                  TextSpan(
                                      text: paymentLang['kebijakan_privasi_5'],
                                      style: TextStyle(color: Colors.red)),
                                  TextSpan(text: paymentLang['kebijakan_privasi_6']),
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
                                    text: paymentLang['setuju_syarat'],
                                  )
                                ]
                              )
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: handleConfirm,
                          child: Text(
                            paymentLang['konfirmasi'],
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(paymentLang['batal']),
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

    // email
    if (_emailController.text.trim().isEmpty ||
        !isValidEmail(_emailController.text)) {
      isValid = false;
    }

    // nama
    if (_nameController.text.trim().isEmpty) {
      isValid = false;
    }

    // gender
    if (selectedGender == null) {
      isValid = false;
    }

    // phone
    if (_phoneController.text.trim().isEmpty ||
        !isValidPhone(_phoneController.text)) {
      isValid = false;
    }

    // form tiket
    for (int j = 0; j < indikator.length; j++) {
      if (indikator[j]['required'] == 1 &&
          answers[j].toString().trim().isEmpty) {
        isValid = false;
      }
    }

    if (widget.totalHargaAsli != 0 && !_isChecked3) {
      isValid = false;
    }

    return isValid;
  }
}