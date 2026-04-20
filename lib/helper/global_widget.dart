

// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/helper/ticket_pdf_generator.dart';
import 'package:kreen_app_flutter/modal/email_verif_modal.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/pages/vote/detail_finalis.dart';
import 'package:kreen_app_flutter/pages/vote/detail_finalis_paket.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote_lang.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:printing/printing.dart';


Future<void> handleVoteAction({
  required BuildContext context,
  required String flagLogin,
  required String flagVerifyEmail,
  required String flagPaket,
  required String idFinalis,
  required String flagHideNoUrut,
  required String langCode,
  required Color tema,
  required VoidCallback onAfterLogin,
}) async {

  final storedToken = await StorageService.getToken() ?? '';
  var storeUser = await StorageService.getUser();

  await refreshAfterVerification(storedToken, storeUser['email'] ?? '', langCode);

  storeUser = await StorageService.getUser();

  final bahasa = DetailVoteLang.of(context).values;

  if (flagLogin == '1' && storedToken.isEmpty) {
    await EmailVerifModal.showLogin(context, bahasa, tema, onLoginSuccess: onAfterLogin);
    return;
  }

  // Tidak perlu login tapi perlu verif -> anggap perlu login dulu
  if (flagLogin == '0' && flagVerifyEmail == '1' && storedToken.isEmpty) {
    await EmailVerifModal.showLogin(context, bahasa, tema, onLoginSuccess: onAfterLogin);
    return;
  }

  // Sudah login, tapi email belum diverifikasi
  if (flagVerifyEmail == '1' && storeUser['verifEmail'] == '0') {
    await EmailVerifModal.show(context, storedToken, langCode, bahasa, storeUser['email'] ?? '', tema);
    return;
  }

  // Semua lolos -> navigate
  if (context.mounted) {
    _navigateToFinalis(context, flagPaket, idFinalis, flagHideNoUrut);
  }
}

void _navigateToFinalis(
  BuildContext context,
  String flagPaket,
  String idFinalis,
  String flagHideNoUrut,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => flagPaket == '0'
        ? DetailFinalisPage(
            id_finalis: idFinalis,
            count: 0,
            indexWrap: null,
            flag_hide_no_urut: flagHideNoUrut,
          )
        : DetailFinalisPaketPage(
            id_finalis: idFinalis,
            vote: 0,
            index: 0,
            total_detail: 0,
            id_paket_bw: null,
            flag_hide_no_urut: flagHideNoUrut,
          ),
    ),
  );
}

Future<void> refreshAfterVerification(String token, String email, String lang) async {

  final result = await ApiService.getLoginUser("/me", token: token, xLanguage: lang);

  if (result != null && result['success'] == true && result['rc'] == 200) {
    final user = result['data'];
    
    await StorageService.setUser(
      id: user['id'], 
      first_name: user['first_name'], 
      last_name: user['last_name'], 
      phone: user['phone'], 
      email: user['email'], 
      gender: user['gender'], 
      photo: user['photo'],
      DOB: user['date_of_birth'],
      verifEmail: user['verified_email'],
      company: user['company'],
      jobTitle: user['job_title'],
      link_linkedin: user['link_linkedin'],
      link_ig: user['link_ig'],
      link_twitter: user['link_twitter'],
    );
  }
}

Widget CommentCard({
  required List<dynamic> namaFinalis,
  required String name,
  required String time,
  required String message,
}) {
  return Container(
    width: double.infinity,
    padding: kGlobalPadding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade300,),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: namaFinalis.map<Widget>((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.toString(),
                style: const TextStyle(color: Colors.black),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        Text(
          message,
          softWrap: true,
        ),

        const SizedBox(height: 12),

        Divider(),

        const SizedBox(height: 12),
        
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        Text(
          time,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    ),
  );
}

class VoteLimit extends StatefulWidget {
  final String errorMessage;
  final String id_event;
  const VoteLimit({super.key, required this.errorMessage, required this.id_event});

  @override
  State<VoteLimit> createState() => _VoteLimitState();
}

class _VoteLimitState extends State<VoteLimit> {
  Map<String, dynamic> bahasa = {};

  @override
  void initState() {
    super.initState();
    _getBahasa();
  }

  Future<void> _getBahasa() async {
    final langCode = await StorageService.getLanguage() ?? 'id';
    final tempBahasa = await LangService.getJsonData(langCode, "bahasa");

    if (!mounted) return;
    setState(() {
      bahasa = tempBahasa;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: kGlobalPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Spacer(),
              
              Image.asset(
                'assets/images/img_vote_limit.png',
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.language, size: 100, color: Colors.grey),
              ),

              const SizedBox(height: 32),
              Text(
                "Vote Limit",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.errorMessage,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),

              const Spacer(),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                      (route) => false,
                    );

                    await Future.delayed(Duration.zero);

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailVotePage(
                            id_event: widget.id_event,
                            currencyCode: currencyCode,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    bahasa['kembali'] ?? 'Back',
                    style: TextStyle( fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



  Future<void> downloadTicket(
    BuildContext context, 
    StateSetter setState,
    Map<String, dynamic> event,
    Map<String, dynamic> eventOder,
    Map<String, dynamic> detailEvent,
    Map<String, dynamic> dataEvents,
    List<dynamic> eventOrderDetail,
    List<dynamic> eventTiket,
    String langCode,
    Map<String, dynamic> bahasa,
  ) async {
    try {
      final pdfBytes = await TicketPdfGenerator.generate(
        event: event,
        eventOder: eventOder,
        detailEvent: detailEvent,
        dataEvents: dataEvents,
        eventOrderDetail: eventOrderDetail,
        eventTiket: eventTiket,
        langCode: langCode,
        bahasa: bahasa,
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'tiket-${eventOder['id_order']}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${bahasa['error']}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }