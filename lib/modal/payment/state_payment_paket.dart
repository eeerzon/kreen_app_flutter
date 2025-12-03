// ignore_for_file: non_constant_identifier_names, prefer_typing_uninitialized_variables, use_build_context_synchronously, deprecated_member_use

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/helper/get_geo_location.dart';
import 'package:kreen_app_flutter/pages/vote/add_support.dart';
import 'package:kreen_app_flutter/pages/vote/waiting_order_page.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class StatePaymentPaket extends StatefulWidget {
  final String id_vote;
  final String id_finalis;
  final String nama_finalis;
  final int counts;
  final num totalHarga;
  final String id_paket;
  final bool fromDetail;
  final String? idUser;

  const StatePaymentPaket({
    super.key,
    required this.id_vote,
    required this.id_finalis,
    required this.nama_finalis,
    required this.counts,
    required this.totalHarga,
    required this.id_paket,
    required this.fromDetail,
    this.idUser
  });

  @override
  State<StatePaymentPaket> createState() => _StatePaymentPaketState();
}

class _StatePaymentPaketState extends State<StatePaymentPaket> {
  var get_user;
  var user_id;
  var first_name;
  var last_name;
  var gender;
  var phone;
  var email;

  String? inputNama;

  Map<String, dynamic> detailVote = {};
  Map<String, dynamic> detailEvent = {};
  Map<String, dynamic> payment = {};
  List<dynamic> indikator = [];
  String? voteCurrency, eventCurrency;
  var totalPayment, feeLayanan;

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
  
  @override
  void initState() {
    super.initState();
    
    loadData();

    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  Future<void> loadData() async {
    await getData(widget.id_vote);

    answers = List.filled(indikator.length, '');
    ids_indikator = List.filled(indikator.length, '');
    answerControllers = List.generate(
      indikator.length,
      (index) => TextEditingController(),
    );

    setState(() {});
  }

  Future<void> getData(String idVote) async {
    final getUser = await StorageService.getUser();

    final firstName = getUser['first_name'] ?? '';
    final lastName = getUser['last_name'] ?? '';
    final gender = getUser['gender'] ?? '';
    final phone = getUser['phone'] ?? '';
    final email = getUser['email'] ?? '';

    _nameController.text = "$firstName $lastName".trim();
    _phoneController.text = phone;
    _emailController.text = email;

    if (gender.isNotEmpty) {
      selectedGender = gender.toLowerCase() == 'male' ? 'Laki-laki' : 'Perempuan';
    }

    final detailResp = await ApiService.get("/vote/$idVote");
    final paymentResp = await ApiService.get("/vote/$idVote/payment-methods");

    detailVote = detailResp?['data'] ?? {};
    voteCurrency = detailVote['currency'];

    payment = paymentResp?['data'] ?? {};

    indikator = detailVote['indikator_vote'] ?? [];
  }

  double ceil2(num value) {
    return (value * 100).ceil() / 100;
  }

  Future<Map<String, dynamic>?> getFee(String feeCurrency, var total_price, var feePersen, var ppn, var base_fee, var rate) async {
    var total_payment;
    var fee;

    var fee_percent_decimal = feePersen / 100;
    var ppn_decimal = ppn / 100;

    if (feeCurrency == 'IDR') {
      var fee_percent_with_ppn = fee_percent_decimal * (1 + ppn_decimal);
      var base_fee_with_ppn = base_fee * (1 + ppn_decimal);

      var grossed_total = total_price / (1 - fee_percent_with_ppn);
      var total_with_fee = grossed_total + base_fee_with_ppn;
      fee = ceil2(total_with_fee - total_price);
      total_payment = ceil2(total_with_fee);
    } else {
      var total_price_pg = total_price * rate;

      var fee_percent_with_ppn = fee_percent_decimal * (1 + ppn_decimal);
      var base_fee_with_ppn = base_fee * (1 + ppn_decimal);

      var grossed_total_pg = total_price_pg / (1 - fee_percent_with_ppn);
      var total_with_fee_pg = grossed_total_pg + base_fee_with_ppn;

      // Tambahan 1% untuk luar negeri
      var extra_fee_pg = total_price_pg * 0.01;
      total_with_fee_pg += extra_fee_pg;

      // Konversi kembali ke mata uang asli
      var total_with_fee_foreign = total_with_fee_pg / rate;

      total_payment = ceil2(total_with_fee_foreign);
      fee = ceil2(total_payment - total_price);
    }

    return {
        'total_payment': total_payment,
        'fee_layanan': fee
    };
  }
  
  @override
  Widget build(BuildContext context) {
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
      
      bool isNameEmpty = _nameController.text.trim().isEmpty;
      bool isPhoneEmpty = _phoneController.text.trim().isEmpty;
      bool isGenderEmpty = selectedGender == null;
      bool isCheckboxUnchecked = !_isChecked3;

      if (isNameEmpty || isPhoneEmpty || isGenderEmpty || isCheckboxUnchecked) {
        setState(() {
          _showError = true;
        });
        return;
      }

      // lanjutkan aksi konfirmasi
      if (widget.totalHarga != 0) {
        final body = {
          "id_vote": widget.id_vote, //  free: 65aa23e7eea47 // paid: 65aa22cda9ec2
          "id_user": widget.idUser,
          "id_paket": widget.id_paket,
          "nama_voter": _nameController.text.trim(),
          "email_voter": email,
          // "gender": selectedGender,
          "latitude": latitude,
          "longitude": longitude,
          "finalis": [
              {
                  "id_finalis": widget.id_finalis,
                  "qty": widget.counts
              }
          ],
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
          final tempOrder = resultVoteOrder['data'];

          var id_order = tempOrder['id_order'];
          Navigator.pop(context);//tutup modal

          if (widget.fromDetail) {
            Navigator.pop(context);//tutup page detail finalis
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WaitingOrderPage(id_order: id_order)),
          );
        } else {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.error,
            animType: AnimType.topSlide,
            title: 'Oops!',
            desc: 'Terjadi kesalahan. Silakan coba lagi.',
            btnOkOnPress: () {},
            headerAnimationLoop: false,
            dismissOnTouchOutside: true,
            showCloseIcon: true,
          ).show();
        }
      } else {
        final body = {
          "id_vote": widget.id_vote, //  free: 65aa23e7eea47 // paid: 65aa22cda9ec2
          "id_user": widget.idUser,
          "id_paket": widget.id_paket,
          "nama_voter": _nameController.text.trim(),
          "email_voter": email,
          // "gender": selectedGender,
          "latitude": latitude,
          "longitude": longitude,
          "finalis": [
              {
                  "id_finalis": widget.id_finalis,
                  "qty": widget.counts
              }
          ],
          "payment_method": null,
          "indikator": List.generate(
            ids_indikator.length, (index) => {
              "id_indikator": ids_indikator[index],
              "answer": answers[index]
            },
          ),
        };

        var resultVoteOrder = await ApiService.post("/order/vote/checkout", body: body);

        if (resultVoteOrder != null) {
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
        } else {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.error,
            animType: AnimType.topSlide,
            title: 'Oops!',
            desc: 'Terjadi kesalahan. Silakan coba lagi.',
            btnOkOnPress: () {},
            headerAnimationLoop: false,
            dismissOnTouchOutside: true,
            showCloseIcon: true,
          ).show();
        }
      }
    }

    final genders = [
      {'label': 'Laki-laki', 'icon': '$baseUrl/image/male.png'},
      {'label': 'Perempuan', 'icon': '$baseUrl/image/female.png'},
    ];
    
    final creditCard = payment['Credit Card'] ?? [];
    final virtualAkun = payment['Virtual Account'] ?? [];
    final paymentBank = payment['Payment Bank'] ?? [];
    final eWallet = payment['E-Wallet'] ?? [];
    final retail = payment['Retail'] ?? [];
    final konter = payment['Counter'] ?? [];
    final qrCode = payment['QR Codes'] ?? [];
    final debit = payment['Direct Debit'] ?? [];

    return Scaffold(
      body: Padding(
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
                  const Text(
                    "Pembayaran",
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
                        "Yuk Isi Data Diri Dulu....",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Lengkapi data diri untuk melanjutkan"
                      ),

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            "Nama"
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
                          hintText: "Masukkan nama lengkap",
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: _border(_nameController.text.isNotEmpty),
                          focusedBorder: _border(true),
                        ),
                      ),
                      if (_showError && _nameController.text.trim().isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            "Nama wajib diisi",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            "Jenis Kelamin"
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
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 1,
                                  ),
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
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            "Jenis kelamin wajib dipilih",
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
                                hintText: "Masukkan $label kamu",
                                hintStyle: const TextStyle(color: Colors.grey),
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
                                    "Pastikan kamu menggunakan nomor aktif",
                                    style: TextStyle(color: Colors.blue),
                                  )
                                ],
                              ),
                              if (_showError && _phoneController.text.trim().isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    "Nomor HP wajib diisi",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
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
                      if (widget.totalHarga != 0) ...[
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
                          "Pilih Metode Pembayaran",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Yuk pilih metode pembayaranmu..."
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

                                final currentcy_min = limit_min * exchange_rate;
                                final currentcy_max = limit_max * exchange_rate;
                                int roundedValue_min = currentcy_min.ceil();
                                int roundedValue_max = currentcy_max.ceil();

                                final isSelected = selectedIndex == idx;

                                final isDisabled = widget.totalHarga < limit_min || widget.totalHarga > limit_max;

                                return GestureDetector(
                                  onTap: isDisabled
                                  ? null 
                                  : () async {
                                    setState(() {
                                      selectedIndex = idx;
                                      id_payment_method = creditCard[idx]['id_metod'];
                                    });

                                    final resultFee = await getFee(voteCurrency!, widget.totalHarga, item['fee_percent'], item['ppn'], item['fee'], item['rate']);

                                    if (resultFee !=null) {
                                      setState(() {
                                        totalPayment = resultFee['total_payment'];
                                        feeLayanan = resultFee['fee_layanan'];
                                      });
                                    }
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
                                                      "$baseUrl/image/payment-method/${item['img']}",
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
                                                          if (widget.totalHarga < limit_min)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4.0),
                                                              child: Text(
                                                                "Limit minimal transaksi $voteCurrency ${formatter.format((roundedValue_min + 1000))}",
                                                                softWrap: true,
                                                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                              ),
                                                            ),
                                                          
                                                          if (widget.totalHarga > limit_max)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4.0),
                                                              child: Text( limit_max == 0
                                                                ? "Limit maksimail transaksi $voteCurrency ${formatter.format((roundedValue_max + 1000))}"
                                                                : "Limit maksimail transaksi $voteCurrency ${formatter.format((roundedValue_max))}",
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
                                                            hintStyle: const TextStyle(
                                                              color: Colors.grey,
                                                            ),
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
                                                                  hintStyle: const TextStyle(
                                                                    color: Colors.grey,
                                                                  ),
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
                                                                  hintStyle: const TextStyle(
                                                                    color: Colors.grey,
                                                                  ),
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

                                final currentcy_min = limit_min * exchange_rate;
                                final currentcy_max = limit_max * exchange_rate;
                                int roundedValue_min = currentcy_min.ceil();
                                int roundedValue_max = currentcy_max.ceil();

                                final isSelected = selectedIndex == idx;

                                final isDisabled = widget.totalHarga < limit_min || widget.totalHarga > limit_max;

                                return GestureDetector(
                                  onTap: isDisabled
                                  ? null 
                                  : () async {
                                    setState(() {
                                      selectedIndex = idx;
                                      id_payment_method = virtualAkun[index]['id_metod'];
                                    });
                                    
                                    Future.delayed(const Duration(milliseconds: 200), () {
                                        _scrollController.animateTo(
                                          _scrollController.position.maxScrollExtent,
                                          duration: const Duration(milliseconds: 600),
                                          curve: Curves.easeOut,
                                        );
                                      });

                                      final resultFee = await getFee(voteCurrency!, widget.totalHarga, item['fee_percent'], item['ppn'], item['fee'], item['rate']);

                                      if (resultFee != null) {
                                        setState(() {
                                          totalPayment = resultFee['total_payment'];
                                          feeLayanan = resultFee['fee_layanan'];
                                        });
                                      }
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
                                                      "$baseUrl/image/payment-method/${item['img']}",
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
                                                          if (widget.totalHarga < limit_min)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4.0),
                                                              child: Text(
                                                                "Limit minimal transaksi $voteCurrency ${formatter.format((roundedValue_min + 1000))}",
                                                                softWrap: true,
                                                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                              ),
                                                            ),
                                                          
                                                          if (widget.totalHarga > limit_max)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4.0),
                                                              child: Text( limit_max == 0
                                                                ? "Limit maksimail transaksi $voteCurrency ${formatter.format((roundedValue_max + 1000))}"
                                                                : "Limit maksimail transaksi $voteCurrency ${formatter.format((roundedValue_max))}",
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

                                final currentcy_min = limit_min * exchange_rate;
                                final currentcy_max = limit_max * exchange_rate;
                                int roundedValue_min = currentcy_min.ceil();
                                int roundedValue_max = currentcy_max.ceil();

                                final isSelected = selectedIndex == idx;

                                final isDisabled = widget.totalHarga < limit_min || widget.totalHarga > limit_max;

                                return GestureDetector(
                                  onTap: isDisabled
                                  ? null 
                                  : () async {
                                    setState(() {
                                      selectedIndex = idx;
                                      id_payment_method = paymentBank[index]['id_metod'];
                                    });
                                    
                                    Future.delayed(const Duration(milliseconds: 200), () {
                                        _scrollController.animateTo(
                                          _scrollController.position.maxScrollExtent,
                                          duration: const Duration(milliseconds: 600),
                                          curve: Curves.easeOut,
                                        );
                                      });

                                      final resultFee = await getFee(voteCurrency!, widget.totalHarga, item['fee_percent'], item['ppn'], item['fee'], item['rate']);

                                      if (resultFee != null) {
                                        setState(() {
                                          totalPayment = resultFee['total_payment'];
                                          feeLayanan = resultFee['fee_layanan'];
                                        });
                                      }
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
                                                      "$baseUrl/image/payment-method/${item['img']}",
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
                                                          if (widget.totalHarga < limit_min)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4.0),
                                                              child: Text(
                                                                "Limit minimal transaksi $voteCurrency ${formatter.format((roundedValue_min + 1000))}",
                                                                softWrap: true,
                                                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                              ),
                                                            ),
                                                          
                                                          if (widget.totalHarga > limit_max)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4.0),
                                                              child: Text( limit_max == 0
                                                                ? "Limit maksimail transaksi $voteCurrency ${formatter.format((roundedValue_max + 1000))}"
                                                                : "Limit maksimail transaksi $voteCurrency ${formatter.format((roundedValue_max))}",
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

                                final currentcy_min = limit_min * exchange_rate;
                                final currentcy_max = limit_max * exchange_rate;
                                int roundedValue_min = currentcy_min.ceil();
                                int roundedValue_max = currentcy_max.ceil();

                                final isSelected = selectedIndex == idx;

                                final isDisabled = widget.totalHarga < limit_min || widget.totalHarga > limit_max;

                                return GestureDetector(
                                  onTap: isDisabled
                                  ? null 
                                  : () async {
                                    setState(() {
                                      selectedIndex = idx;
                                      id_payment_method = eWallet[index]['id_metod'];
                                    });
                                    
                                    Future.delayed(const Duration(milliseconds: 200), () {
                                        _scrollController.animateTo(
                                          _scrollController.position.maxScrollExtent,
                                          duration: const Duration(milliseconds: 600),
                                          curve: Curves.easeOut,
                                        );
                                      });

                                      final resultFee = await getFee(voteCurrency!, widget.totalHarga, item['fee_percent'], item['ppn'], item['fee'], item['rate']);

                                      if (resultFee != null) {
                                        setState(() {
                                          totalPayment = resultFee['total_payment'];
                                          feeLayanan = resultFee['fee_layanan'];
                                        });
                                      }
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
                                                      "$baseUrl/image/payment-method/${item['img']}",
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
                                                          if (widget.totalHarga < limit_min)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4.0),
                                                              child: Text(
                                                                "Limit minimal transaksi $voteCurrency ${formatter.format((roundedValue_min + 1000))}",
                                                                softWrap: true,
                                                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                              ),
                                                            ),
                                                          
                                                          if (widget.totalHarga > limit_max)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4.0),
                                                              child: Text( limit_max == 0
                                                                ? "Limit maksimail transaksi $voteCurrency ${formatter.format((roundedValue_max + 1000))}"
                                                                : "Limit maksimail transaksi $voteCurrency ${formatter.format((roundedValue_max))}",
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

                                final currentcy_min = limit_min * exchange_rate;
                                final currentcy_max = limit_max * exchange_rate;
                                int roundedValue_min = currentcy_min.ceil();
                                int roundedValue_max = currentcy_max.ceil();

                                final isSelected = selectedIndex == idx;

                                final isDisabled = widget.totalHarga < limit_min || widget.totalHarga > limit_max;

                                return GestureDetector(
                                  onTap: isDisabled
                                  ? null 
                                  : () async {
                                    setState(() {
                                      selectedIndex = idx;
                                      id_payment_method = retail[index]['id_metod'];
                                    });
                                    
                                    Future.delayed(const Duration(milliseconds: 200), () {
                                        _scrollController.animateTo(
                                          _scrollController.position.maxScrollExtent,
                                          duration: const Duration(milliseconds: 600),
                                          curve: Curves.easeOut,
                                        );
                                      });

                                      final resultFee = await getFee(voteCurrency!, widget.totalHarga, item['fee_percent'], item['ppn'], item['fee'], item['rate']);

                                      if (resultFee != null) {
                                        setState(() {
                                          totalPayment = resultFee['total_payment'];
                                          feeLayanan = resultFee['fee_layanan'];
                                        });
                                      }
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
                                                      "$baseUrl/image/payment-method/${item['img']}",
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
                                                          if (widget.totalHarga < limit_min)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4.0),
                                                              child: Text(
                                                                "Limit minimal transaksi $voteCurrency ${formatter.format((roundedValue_min + 1000))}",
                                                                softWrap: true,
                                                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                              ),
                                                            ),
                                                          
                                                          if (widget.totalHarga > limit_max)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4.0),
                                                              child: Text( limit_max == 0
                                                                ? "Limit maksimail transaksi $voteCurrency ${formatter.format((roundedValue_max + 1000))}"
                                                                : "Limit maksimail transaksi $voteCurrency ${formatter.format((roundedValue_max))}",
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

                                final currentcy_min = limit_min * exchange_rate;
                                final currentcy_max = limit_max * exchange_rate;
                                int roundedValue_min = currentcy_min.ceil();
                                int roundedValue_max = currentcy_max.ceil();

                                final isSelected = selectedIndex == idx;

                                final isDisabled = widget.totalHarga < limit_min || widget.totalHarga > limit_max;

                                return GestureDetector(
                                  onTap: isDisabled
                                  ? null 
                                  : () async {
                                    setState(() {
                                      selectedIndex = idx;
                                      id_payment_method = konter[index]['id_metod'];
                                    });
                                    
                                    Future.delayed(const Duration(milliseconds: 200), () {
                                        _scrollController.animateTo(
                                          _scrollController.position.maxScrollExtent,
                                          duration: const Duration(milliseconds: 600),
                                          curve: Curves.easeOut,
                                        );
                                      });

                                      final resultFee = await getFee(voteCurrency!, widget.totalHarga, item['fee_percent'], item['ppn'], item['fee'], item['rate']);

                                      if (resultFee != null) {
                                        setState(() {
                                          totalPayment = resultFee['total_payment'];
                                          feeLayanan = resultFee['fee_layanan'];
                                        });
                                      }
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
                                                      "$baseUrl/image/payment-method/${item['img']}",
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
                                                          if (widget.totalHarga < limit_min)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4.0),
                                                              child: Text(
                                                                "Limit minimal transaksi $voteCurrency ${formatter.format((roundedValue_min + 1000))}",
                                                                softWrap: true,
                                                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                              ),
                                                            ),
                                                          
                                                          if (widget.totalHarga > limit_max)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4.0),
                                                              child: Text( limit_max == 0
                                                                ? "Limit maksimail transaksi $voteCurrency ${formatter.format((roundedValue_max + 1000))}"
                                                                : "Limit maksimail transaksi $voteCurrency ${formatter.format((roundedValue_max))}",
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

                                final currentcy_min = limit_min * exchange_rate;
                                final currentcy_max = limit_max * exchange_rate;
                                int roundedValue_min = currentcy_min.ceil();
                                int roundedValue_max = currentcy_max.ceil();

                                final isSelected = selectedIndex == idx;

                                final isDisabled = widget.totalHarga < limit_min || widget.totalHarga > limit_max;

                                return GestureDetector(
                                  onTap: isDisabled
                                  ? null 
                                  : () async {
                                    setState(() {
                                      selectedIndex = idx;
                                      id_payment_method = qrCode[index]['id_metod'];
                                    });
                                    
                                    Future.delayed(const Duration(milliseconds: 200), () {
                                        _scrollController.animateTo(
                                          _scrollController.position.maxScrollExtent,
                                          duration: const Duration(milliseconds: 600),
                                          curve: Curves.easeOut,
                                        );
                                      });

                                      final resultFee = await getFee(voteCurrency!, widget.totalHarga, item['fee_percent'], item['ppn'], item['fee'], item['rate']);

                                      if (resultFee != null) {
                                        setState(() {
                                          totalPayment = resultFee['total_payment'];
                                          feeLayanan = resultFee['fee_layanan'];
                                        });
                                      }
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
                                                      "$baseUrl/image/payment-method/${item['img']}",
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
                                                          if (widget.totalHarga < limit_min)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4.0),
                                                              child: Text(
                                                                "Limit minimal transaksi $voteCurrency ${formatter.format((roundedValue_min + 1000))}",
                                                                softWrap: true,
                                                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                              ),
                                                            ),
                                                          
                                                          if (widget.totalHarga > limit_max)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4.0),
                                                              child: Text( limit_max == 0
                                                                ? "Limit maksimail transaksi $voteCurrency ${formatter.format((roundedValue_max + 1000))}"
                                                                : "Limit maksimail transaksi $voteCurrency ${formatter.format((roundedValue_max))}",
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

                                final currentcy_min = limit_min * exchange_rate;
                                final currentcy_max = limit_max * exchange_rate;
                                int roundedValue_min = currentcy_min.ceil();
                                int roundedValue_max = currentcy_max.ceil();

                                final isSelected = selectedIndex == idx;

                                final isDisabled = widget.totalHarga < limit_min || widget.totalHarga > limit_max;

                                return GestureDetector(
                                  onTap: isDisabled
                                  ? null 
                                  : () async {
                                    setState(() {
                                      selectedIndex = idx;
                                      id_payment_method = debit[index]['id_metod'];
                                    });
                                    
                                    Future.delayed(const Duration(milliseconds: 200), () {
                                        _scrollController.animateTo(
                                          _scrollController.position.maxScrollExtent,
                                          duration: const Duration(milliseconds: 600),
                                          curve: Curves.easeOut,
                                        );
                                      });

                                      final resultFee = await getFee(voteCurrency!, widget.totalHarga, item['fee_percent'], item['ppn'], item['fee'], item['rate']);

                                      if (resultFee != null) {
                                        setState(() {
                                          totalPayment = resultFee['total_payment'];
                                          feeLayanan = resultFee['fee_layanan'];
                                        });
                                      }
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
                                                      "$baseUrl/image/payment-method/${item['img']}",
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
                                                          if (widget.totalHarga < limit_min)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4.0),
                                                              child: Text(
                                                                "Limit minimal transaksi $voteCurrency ${formatter.format((roundedValue_min + 1000))}",
                                                                softWrap: true,
                                                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                              ),
                                                            ),
                                                          
                                                          if (widget.totalHarga > limit_max)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4.0),
                                                              child: Text( limit_max == 0
                                                                ? "Limit maksimail transaksi $voteCurrency ${formatter.format((roundedValue_max + 1000))}"
                                                                : "Limit maksimail transaksi $voteCurrency ${formatter.format((roundedValue_max))}",
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
                                                          },
                                                          keyboardType: TextInputType.number,
                                                          decoration: InputDecoration(
                                                            hintText: "masukkan nomor handphone kamu",
                                                            hintStyle: const TextStyle(
                                                              color: Colors.grey,
                                                            ),
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
                          const Text(
                            "Detail Harga",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 16,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${widget.nama_finalis} (${widget.counts}x)",
                              ),
                              Text(
                                "$voteCurrency ${formatter.format(totalPayment-feeLayanan)}"
                              )
                            ],
                          ),

                          const SizedBox(height: 16,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Biaya Layanan"),
                              Text("$voteCurrency ${formatter.format(feeLayanan)}")
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
                              Text("Total Bayar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
                              Text("$voteCurrency ${formatter.format(totalPayment)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),)
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
                                      text: "Apakah kamu memiliki masalah dengan transaksi ini? ",
                                      style: TextStyle(color: Colors.black),
                                      children: const [
                                        TextSpan(
                                          text: "Dapatkan Bantuan",
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
                                    "Vote yang telah diberikan bersifat final dan tidak dapat dikembalikan.",
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
                                      TextSpan(text: "Saya menyetujui bahwa "),
                                      TextSpan(
                                          text: "KREEN ",),
                                      TextSpan(
                                          text:
                                              "dapat membagikan informasi saya kepada pihak penyelenggara acara, telah membaca "),
                                      TextSpan(
                                          text: "Ketentuan Layanan",
                                          style: TextStyle(color: Colors.red)),
                                      TextSpan(text: ", dan menyetujui "),
                                      TextSpan(
                                          text: "Kebijakan Privasi",
                                          style: TextStyle(color: Colors.red)),
                                      TextSpan(text: " yang berlaku."),
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
                                        text: "Saya menyetujui Syarat & Ketentuan Voting yang berlaku, termasuk kebijakan bahwa transaksi yang sudah dilakukan tidak dapat dibatalkan atau dikembalikan (non-refundable).",
                                      )
                                    ]
                                  )
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),
                          if (_showError)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                "Bagian ini harus dipilih",
                                style: TextStyle(
                                    color: Colors.red, fontWeight: FontWeight.bold),
                              ),
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
                                      TextSpan(text: "Saya menyatakan bahwa jumlah vote yang saya masukkan, yaitu 20 vote dengan total pembayaran sebesar "),
                                      TextSpan(
                                          text: "$voteCurrency ${formatter.format(totalPayment)}",
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                      TextSpan(
                                          text:
                                              ", sudah benar, telah saya periksa, dan saya secara sadar menyetujui untuk melanjutkan transaksi sesuai jumlah tersebut."),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                              child: const Text(
                                "Konfirmasi",
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
                              child: const Text("Batal"),
                            ),
                          ),
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
                                    TextSpan(text: "Saya menyetujui bahwa "),
                                    TextSpan(
                                        text: "KREEN ",),
                                    TextSpan(
                                        text:
                                            "dapat membagikan informasi saya kepada pihak penyelenggara acara, telah membaca "),
                                    TextSpan(
                                        text: "Ketentuan Layanan",
                                        style: TextStyle(color: Colors.red)),
                                    TextSpan(text: ", dan menyetujui "),
                                    TextSpan(
                                        text: "Kebijakan Privasi",
                                        style: TextStyle(color: Colors.red)),
                                    TextSpan(text: " yang berlaku."),
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
                                      text: "Saya menyetujui Syarat & Ketentuan Voting yang berlaku, termasuk kebijakan bahwa transaksi yang sudah dilakukan tidak dapat dibatalkan atau dikembalikan (non-refundable).",
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
                            child: const Text(
                              "Konfirmasi",
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
                            child: const Text("Batal"),
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

}