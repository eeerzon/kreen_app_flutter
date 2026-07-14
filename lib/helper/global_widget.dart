

// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, unused_local_variable, deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/date_helper.dart';
import 'package:kreen_app_flutter/helper/global_function.dart';
import 'package:kreen_app_flutter/helper/ticket_pdf_generator.dart';
import 'package:kreen_app_flutter/helper/widget_webview.dart';
import 'package:kreen_app_flutter/modal/email_verif_modal.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/pages/vote/detail_finalis.dart';
import 'package:kreen_app_flutter/pages/vote/detail_finalis_paket.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote_lang.dart';
import 'package:kreen_app_flutter/pages/vote/finalis_page.dart';
import 'package:kreen_app_flutter/pages/vote/finalis_paket_page.dart';
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
  required bool persen
}) async {

  final storedToken = await StorageService.getToken() ?? '';
  var storeUser = await StorageService.getUser();
  String? currencyCode = await StorageService.getCurrency();

  await refreshAfterVerification(storedToken, storeUser['email'] ?? '', langCode);

  storeUser = await StorageService.getUser();

  final bahasa = DetailVoteLang.of(context).values;

  if (flagLogin == '1' && storedToken.isEmpty) {
    await EmailVerifModal.showLogin(context, bahasa, tema, onLoginSuccess: onAfterLogin);
    return;
  }
  
  if (flagLogin == '0' && flagVerifyEmail == '1' && storedToken.isEmpty) {
    await EmailVerifModal.showLogin(context, bahasa, tema, onLoginSuccess: onAfterLogin);
    return;
  }
  
  if (flagVerifyEmail == '1' && storeUser['verifEmail'] == '0') {
    await EmailVerifModal.show(context, storedToken, langCode, bahasa, storeUser['email'] ?? '', tema);
    return;
  }
  
  if (context.mounted) {
    _navigateToFinalis(context, flagPaket, idFinalis, flagHideNoUrut, persen);
  }
}

void _navigateToFinalis(
  BuildContext context,
  String flagPaket,
  String idFinalis,
  String flagHideNoUrut,
  bool persen
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
            persen: persen,
          )
        : DetailFinalisPaketPage(
            id_finalis: idFinalis,
            vote: 0,
            index: 0,
            total_detail: 0,
            id_paket_bw: null,
            flag_hide_no_urut: flagHideNoUrut,
            persen: persen,
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
  required dynamic namaFinalis,
  required String name,
  required String time,
  required String message,
}) {

  final List<String> namaList = namaFinalis is List
    ? namaFinalis.map((e) => e.toString()).toList()
    : [namaFinalis.toString()];

  final String parsedMessage = parseNewline(message);
    
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
        if (namaList.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: namaList.map<Widget>((item) {
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
          parsedMessage,
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
  String? currencyCode;

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

    currencyCode = await StorageService.getCurrency();
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
                            currencyCode: currencyCode!,
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

Future<bool> isImageAccessible(String? url) async {
  if (url == null || url.isEmpty) return false;
  try {
    final response = await http.head(Uri.parse(url));
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

void showBoostPopup(
  BuildContext context, 
  String langCode, 
  Map<String, dynamic> bahasa, 
  Map<String, dynamic> vote, 
  String flag_paket, 
  Color color, 
  int multiplier, 
  String multiplier_end_date, 
  Duration? remainingTime, 
  int view_api,
  bool leaderboardClicked
) {
  Timer? dialogTimer;
  Duration currentRemaining = remainingTime ?? Duration.zero;
  String formattedDate = '-';

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        
        dialogTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
          if (currentRemaining.inSeconds > 0) {
            setDialogState(() {
              currentRemaining = currentRemaining - const Duration(seconds: 1);
            });
          }
        });

        if (multiplier_end_date.isNotEmpty) {
          try {
            final localDate = DateHelper.parseWibToLocal(multiplier_end_date);
            if (langCode == 'id') {
              final formatter = DateFormat(formatDateId, "id_ID");
              formattedDate = formatter.format(localDate);
            } else {
              final formatter = DateFormat(formatDateEn, "en_US");
              formattedDate = formatter.format(localDate);
              
              final day = localDate.day;
              String suffix = 'th';
              if (day % 10 == 1 && day != 11) { suffix = 'st'; }
              else if (day % 10 == 2 && day != 12) { suffix = 'nd'; }
              else if (day % 10 == 3 && day != 13) { suffix = 'rd'; }
              formattedDate = formatter.format(localDate).replaceFirst('$day', '$day$suffix');
            }
          } catch (e) {
            formattedDate = '-';
          }
        }

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.75,
                    child: Image.asset(
                      'assets/images/boost_kreen.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      Text(
                        'BOOST',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color, width: 3),
                        ),
                        child: Text(
                          'VOTE ${multiplier}X 🔥',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: 10),
                      Text(
                        '${bahasa['boost_desc_1'] ?? 'Every vote purchased during this promo period will be counted'} ${multiplier}x',
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white60,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '🚀 ${bahasa['boost_desc_2'] ?? 'Boost Vote ends in'}',
                            ),

                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _timeBox(currentRemaining.inDays.toString().padLeft(2, "0"), bahasa['day'], Colors.black),
                                const SizedBox(width: 10),
                                _separator(Colors.white),
                                const SizedBox(width: 10),
                                _timeBox(currentRemaining.inHours.remainder(24).toString().padLeft(2, "0"), bahasa['hour'], Colors.black),
                                const SizedBox(width: 10),
                                _separator(Colors.white),
                                const SizedBox(width: 10),
                                _timeBox(currentRemaining.inMinutes.remainder(60).toString().padLeft(2, "0"), bahasa['minute'], Colors.black),
                                const SizedBox(width: 10),
                                _separator(Colors.white),
                                const SizedBox(width: 10),
                                _timeBox(currentRemaining.inSeconds.remainder(60).toString().padLeft(2, "0"), bahasa['second'], Colors.black),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 10),
                      Text(
                        '*${bahasa['boost_desc_3'] ?? 'Boost vote period is valid until'}\n$formattedDate',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      SizedBox(height: 10),
                      SizedBox(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            padding: EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            if (leaderboardClicked) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pop(context);

                              if (flag_paket == '0') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FinalisPage(id_vote: vote['id_vote'], view_api: view_api,),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FinalisPaketPage(id_vote: vote['id_vote'], view_api: view_api,),
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(
                            bahasa['vote_sekarang'] ?? 'VOTE NOW!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    )
  ).whenComplete(() => dialogTimer?.cancel());
}



Widget _timeBox(String value, String label, Color color) {
  return Column(
    children: [
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        label,
        style: const TextStyle(color: Colors.black),
      ),
    ],
  );
}

Widget _separator(Color color) {
  return Column(
    children: [
      Text(
        "|",
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 20),
    ],
  );
}

void showFreeVotePopup(
  BuildContext context,
  Map<String, dynamic> bahasa,
  int freeVote,
) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  bahasa['free_vote_title'] ?? 'Free Vote Available!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.justify,
                  text: TextSpan(
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: bahasa['free_vote_desc']?.split('{qty}').first ?? 'You have ',
                      ),
                      TextSpan(
                        text: freeVote.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: " ${bahasa['free_vote_qty']}",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: bahasa['free_vote_desc']?.split('{qty}').last ?? ' free votes available.',
                      ),
                    ],
                  ),
                ),
              ]
            ),
          ),
        );
      }
    ),
  );
}

class AutoPlayCarousel extends StatefulWidget {
  final List<String> images;
  final List<dynamic> data;
  final List<double?> aspectRatios;
  final Map<String, dynamic> bahasa;

  const AutoPlayCarousel({
    super.key,
    required this.images,
    required this.data,
    required this.aspectRatios,
    required this.bahasa,
  });

  @override
  State<AutoPlayCarousel> createState() => _AutoPlayCarouselState();
}

class _AutoPlayCarouselState extends State<AutoPlayCarousel> {
  late PageController controller;
  int currentIndex = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    
    controller = PageController(viewportFraction: 1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoPlay();
    });
  }

  void _startAutoPlay() {
    if (widget.images.length <= 1) return;

    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (!controller.hasClients) return;

      final next = (currentIndex + 1) % widget.images.length;

      controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );

      currentIndex = next;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final aspect = currentIndex < widget.aspectRatios.length
      ? widget.aspectRatios[currentIndex]
      : null;
    final height = aspect == null ? 150.0 : (screenWidth / aspect);

    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.red, Colors.white],
              stops: [0.5, 0.5],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              height: height,
              child: PageView.builder(
                controller: controller,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => currentIndex = i),
                itemCount: widget.images.length,
                itemBuilder: (context, i) {
                  final img = widget.images[i];

                  if (widget.aspectRatios[i] == null) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    );
                  }

                  return InkWell(
                    onTap: () {
                      if (widget.data[i]['url_detail'] == null || widget.data[i]['url_detail'] == '') {
                        
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                WidgetWebView(header: widget.bahasa['artikel'], url: widget.data[i]['url_detail']),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Material(
                        borderRadius: BorderRadius.circular(8),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          img,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Container(
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        SizedBox(height: 10, child: Container(color: Colors.white,),),
        Container(
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (i) {
              final isActive = i == currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 14 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? Colors.red : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
        )
      ],
    );
  }
}

class CountdownBox extends StatefulWidget {
  final DateTime deadlineUtc;
  final Map<String, dynamic> bahasa;
  final VoidCallback? onExpired;

  const CountdownBox({
    super.key,
    required this.deadlineUtc,
    required this.bahasa,
    this.onExpired,
  });

  @override
  State<CountdownBox> createState() => _CountdownBoxState();
}

class _CountdownBoxState extends State<CountdownBox> {
  Duration remaining = Duration.zero;
  Timer? _timer;
  bool _expiredCalled = false;

  @override
  void initState() {
    super.initState();
    _update();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _update(),
    );
  }

  void _update() {
    final diff = widget.deadlineUtc.difference(
      DateTime.now().toUtc(),
    );

    if (!mounted) return;

    if (diff.isNegative || diff.inSeconds == 0) {
      
      _timer?.cancel();

      setState(() {
        remaining = Duration.zero;
      });

      if (!_expiredCalled) {
        _expiredCalled = true;
        widget.onExpired?.call();
      }
      return;
    }

    setState(() {
      remaining = diff;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _timeBox(String value, String label,) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.red,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.black),
        ),
      ],
    );
  }

  Widget _separator() {
    return Column(
      children: [
        Text(
          ":",
          style: TextStyle(
            color: Colors.red,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.red,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: kGlobalPadding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _timeBox(
              hours.toString().padLeft(2, '0'),
              widget.bahasa['hour'],
            ),
            const SizedBox(width: 10),
            _separator(),
            const SizedBox(width: 10),
            _timeBox(
              minutes.toString().padLeft(2, '0'),
              widget.bahasa['minute'],
            ),
            const SizedBox(width: 10),
            _separator(),
            const SizedBox(width: 10),
            _timeBox(
              seconds.toString().padLeft(2, '0'),
              widget.bahasa['second'],
            ),
          ],
        ),
      ),
    );
  }
}