// ignore_for_file: deprecated_member_use, non_constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/date_helper.dart';
import 'package:kreen_app_flutter/helper/global_function.dart';
import 'package:kreen_app_flutter/helper/global_widget.dart';
import 'package:kreen_app_flutter/helper/vote_free_notifcation.dart';
import 'package:kreen_app_flutter/helper/vote_notification.dart';
import 'package:kreen_app_flutter/modal/faq_modal.dart';
import 'package:kreen_app_flutter/modal/s_k_modal.dart';
import 'package:kreen_app_flutter/modal/tutor_modal.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/infinite_sponsor.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/running_text.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote_lang.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:share_plus/share_plus.dart';

class DeskripsiSection extends StatefulWidget {
  final Map<String, dynamic> data;
  final List<dynamic> dataNotif;
  final String langCode;
  final String? currencyCode;
  final GlobalKey? runningTextKey;
  final String? token;

  const DeskripsiSection({
    super.key, 
    required this.data, 
    required this.dataNotif, 
    required this.langCode, 
    this.currencyCode,
    this.runningTextKey,
    this.token
  });

  @override
  State<DeskripsiSection> createState() => _DeskripsiSectionState();
}

class _DeskripsiSectionState extends State<DeskripsiSection> {

  final ScrollController sponsorController = ScrollController();
  Timer? _timer;
  final GlobalKey _shareKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    if (widget.data['logo'] != null) {
      const speed = 0.5;

      _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (!sponsorController.hasClients) return;

        final position = sponsorController.position;
        final offset = sponsorController.offset;
        
        final singleSetWidth = position.maxScrollExtent / 2;
        
        if (offset >= singleSetWidth) {
          sponsorController.jumpTo(offset - singleSetWidth);
        } else {
          sponsorController.jumpTo(offset + speed);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    sponsorController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final lang = DetailVoteLang.of(context).values;

    String themeName = 'default';
    if (widget.data['theme_name'] != null) {
      themeName = widget.data['theme_name'];
    }
    if (themeName == "Default Kreen") {
      themeName = "default";
    }

    Color color = colorMap[themeName] ?? Colors.red;

    Color bgColor;
    if (color is MaterialColor) {
      bgColor = color.shade50;
    } else {
      bgColor = color.withOpacity(0.1);
    }

    String strSponsor = widget.data['logo'] ?? '';
    List<dynamic> sponsors = [];
    if (strSponsor.isNotEmpty) {
      sponsors = json.decode(strSponsor);
    }

    Color textColor = color; 
    final rawColor = (widget.data['running_text_color'] ?? '').toString().trim();
    if (rawColor.isNotEmpty) {
      try {
        final hex = rawColor.replaceAll('#', '');
        textColor = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        if (widget.data['flag_live'] == '1'
            && widget.data['real_tanggal_tutup_vote'] != null &&
            DateTime.tryParse(widget.data['real_tanggal_tutup_vote'].toString())?.isAfter(DateTime.now()) == true) ... [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color,
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.network(
                    "$baseUrl/image/signal.svg",
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                  ),

                  SizedBox(width: 6,),
                  Text(
                    lang['voting_ongoing'],
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],

        Stack(
          children: [
            AspectRatio(
              aspectRatio: 4 / 5,
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/images/img_placeholder.jpg',
                image: widget.data['banner'],
                width: double.infinity,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 200),
                imageErrorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/img_broken.jpg',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),

            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  
                  if (widget.dataNotif.isNotEmpty)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: VoteNotifStack(
                          notifList: widget.dataNotif,
                          color: color,
                          bgColor: bgColor,
                          themeName: themeName,
                        ),
                      ),
                    ),
                    
                  if (widget.data['free_quota'] > 0)
                    Padding(
                      padding: widget.dataNotif.isNotEmpty ?  const EdgeInsets.only(top: 48) : const EdgeInsets.only(top: 12),
                      child: FreeVoteFloatingNotif(
                        bahasa: lang,
                        freeVote: widget.data['free_quota'],
                        freeVoteRemain: widget.data['free_vote_remaining_quota'],
                        token: widget.token,
                      ),
                    ),
                ],
              ),
            ),
          ]
        ),

        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsetsGeometry.fromLTRB(20, 0, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.data['judul_vote'] ?? '-',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.data['nama_kategori'] ?? '-',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  InkWell(
                    key: _shareKey,
                    onTap: () {
                      final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
                      final rect = box != null
                          ? box.localToGlobal(Offset.zero) & box.size
                          : Rect.fromLTWH(0, 0, 100, 100);

                      String? editedUrl;
                      if (baseUrl.contains('bc')) {
                        editedUrl = "https://kreenconnect.com";
                      } else {
                        editedUrl = baseUrl;
                      }

                      Share.share(
                        // "$baseUrl/voting/${widget.data['vote_slug']}",
                        "$editedUrl/voting/${widget.data['vote_slug']}",
                        subject: widget.data['judul_vote'],
                        sharePositionOrigin: rect,
                      );
                    },
                    child: SvgPicture.network(
                      '$baseUrl/image/icon-vote/$themeName/share-red.svg',
                      height: 30,
                      width: 30,
                    ),
                  )
                ],
              ),

              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        await FaqModal.show(context, widget.data['faq'], lang);
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              "FAQ Vote",
                              style: TextStyle(color: color),
                            ),
                            const SizedBox(width: 5),
                            Icon(Icons.open_in_new, color: color, size: 14),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 5),
                    InkWell(
                      onTap: () async {
                        await TutorModal.show(context, widget.data['tutorial_vote'], lang['tutorial_vote_text']);
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              lang['tutorial_vote'],
                              style: TextStyle(color: color),
                            ),
                            const SizedBox(width: 5),
                            Icon(Icons.open_in_new, color: color, size: 14),
                          ],
                        ),
                      ),
                    ),

                    if (!isHtmlEmpty(widget.data['snk'])) ... [
                      const SizedBox(width: 5),
                      InkWell(
                        onTap: () async {
                          await SKModal.show(context, widget.data['snk'], lang['s_n_k_vote']);
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                lang['syarat_ket_vote'],
                                style: TextStyle(color: color),
                              ),
                              const SizedBox(width: 5),
                              Icon(Icons.open_in_new, color: color, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 12),
        Container(
          key: widget.runningTextKey,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: textColor,
          ),
          child: Builder(
            builder: (context) {
              final rawText = (widget.data['running_text'] ?? '').toString().trim();
              final displayText = rawText.isNotEmpty
                  ? rawText
                  : 'Kreen Vote - Your Trusted Voting Partner - ${lang['running_text_def']} ${widget.data['judul_vote'] ?? ''}';

              return RunningText(text: displayText, textColor: Colors.white);
            },
          ),
        ),
        
        Padding(
          padding: EdgeInsetsGeometry.fromLTRB(20, 0, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Colors.white,
                child: Padding(
                  padding: kGlobalPadding,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Image.network(
                            widget.data['icon_penyelenggara'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/img_broken.jpg',
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              );
                            },
                          ),

                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang['penyelenggara'],
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  widget.data['nama_penyelenggara'] ?? '-',
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  softWrap: true,
                                  overflow: TextOverflow.visible, 
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ) 
              ),


              if (sponsors.isNotEmpty) ... [
                const SizedBox(height: 20,),
                Text(
                  'Sponsor',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12,),
                InfiniteSponsorMarquee(
                  sponsors: sponsors,
                  height: 48,
                  speed: 35,
                  showFade: false,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class LeaderboardSection extends StatefulWidget {
  final List<dynamic> ranking;
  final Map<String, dynamic> data;
  final String langCode;
  final bool isLoading;

  const LeaderboardSection({
    super.key, 
    required this.ranking, 
    required this.data, 
    required this.langCode,
    this.isLoading = false,
  });

  @override
  State<LeaderboardSection> createState() => _LeaderboardSectionState();
}

class _LeaderboardSectionState extends State<LeaderboardSection> {
  // ignore: unused_field
  String _storedToken = '';

  bool isTutup = false;
  bool isPaymentClosed = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await StorageService.getToken() ?? '';
    if (mounted) setState(() => _storedToken = token);
  }
  
  Future<void> _onAfterLogin() async {
    await _loadToken();
  }

  @override
  Widget build(BuildContext context) {
    final lang = DetailVoteLang.of(context).values;

    String themeName = 'default';
    if (widget.data['theme_name'] != null) {
      themeName = widget.data['theme_name'];
    }
    if (themeName == "Default Kreen") {
      themeName = "default";
    }

    Color color = colorMap[themeName] ?? Colors.red;
    
    Color bgColor;
    if (color is MaterialColor) {
      bgColor = color.shade200;
    } else {
      bgColor = color.withOpacity(0.1);
    }

    final List<int> customOrder = [2, 1, 3];

    final int limitTampil = (widget.data['leaderboard_limit_tampil'] ?? 0) as int;
    final int effectiveLimit = limitTampil > 3 ? limitTampil : 10;

    final List<dynamic> topThree = widget.ranking
        .where((item) => customOrder.contains(item['rank']))
        .toList()
      ..sort((a, b) => customOrder.indexOf(a['rank']).compareTo(customOrder.indexOf(b['rank'])));

    final List<dynamic> others = widget.ranking
        .where((item) => item['rank'] >= 4 && item['rank'] <= effectiveLimit)
        .toList()
      ..sort((a, b) => (a['rank'] as int).compareTo(b['rank'] as int));
        
    DateTime deadlineUtc = DateHelper.parseWibToUtc(widget.data['real_tanggal_tutup_vote']);
    Duration remaining = Duration.zero;
    final nowUtc = DateTime.now().toUtc();
    final difference = deadlineUtc.difference(nowUtc);

    remaining = difference.isNegative ? Duration.zero : difference;
    
    final bukaVoteUtc = DateHelper.parseWibToUtc(widget.data['real_tanggal_buka_vote']);
    bool isBeforeOpen = nowUtc.isBefore(bukaVoteUtc);

    if (remaining.inSeconds == 0 || isBeforeOpen) {
      isTutup = true;
    }

    if (widget.data['close_payment'] != '1') {
      isPaymentClosed = false;
    }

    if (widget.data['tanggal_buka_payment'] != null) {
      final reopenUtc = DateHelper.parseWibToUtc(widget.data['tanggal_buka_payment']!);
      final nowUtc = DateTime.now().toUtc();

      final closed = nowUtc.isBefore(reopenUtc);

      if (closed != isPaymentClosed) {
        isPaymentClosed = closed;
      }
    } else {
      isPaymentClosed = false;
    }
    
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bgColor, color],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300,),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FontAwesomeIcons.crown,
                  color: color, 
                  size: 20,
                ),
              ),

              const SizedBox(height: 12,),
              Text(
                "Leaderboard",
                style: TextStyle(color: Colors.white),
              ),

              const SizedBox(height: 12,),
              Text(
                widget.data['judul_vote'],
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              )
            ],
          ),
        ),

        if (widget.isLoading) ...[
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              buildTopCardSkeleton(isCenter: false),
              buildTopCardSkeleton(isCenter: true),
              buildTopCardSkeleton(isCenter: false),
            ],
          ),
        ]
        else if (widget.ranking.isNotEmpty) ... [
          const SizedBox(height: 60,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: topThree.map((item) {
              
              bool big = false;
              Color colors = Colors.grey;
              if (item['rank'] == 1) {
                big = true;
                colors = Colors.amber;
              } else if (item['rank'] == 2) {
                colors = Colors.grey;
              } else if (item['rank'] == 3) {
                colors = Colors.brown;
              }

              if ((item['total_voters'] ?? 0) > 0) {
                return buildTopCard(
                  context: context, 
                  rank: item['rank'], 
                  name: item['nama_finalis'], 
                  votes: item['total_voters'] ?? 0, 
                  color: colors, 
                  isBig: big, 
                  image: item['poster_finalis'] ?? "$baseUrl/noimage_finalis.png",
                  tema: color, 
                  idFinalis: item['id_finalis'].toString(),
                  remaining: remaining,
                  lang: lang,
                  flag_hide_no_urut: widget.data['flag_hide_nomor_urut'],
                  flag_paket : widget.data['flag_paket'],
                  flag_login: widget.data['flag_login'],
                  flag_verify_email: widget.data['flag_verify_email'],
                  langCode: widget.langCode,
                  onAfterLogin: _onAfterLogin,
                  isTutup: isBeforeOpen,
                  isPaymentClosed: isPaymentClosed
                );
              } else {
                return SizedBox.shrink();
              }

            }).toList(),
          ),

          if (others.isNotEmpty) ...[
            const SizedBox(height: 20),
            Column(
              children: others.map((item) {
                if ((item['total_voters'] ?? 0) > 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: buildListCard(
                      context: context,
                      rank: item['rank'],
                      name: item['nama_finalis'],
                      nameTambahan: item['nama_tambahan'],
                      votes: item['total_voters'] ?? 0,
                      progress: 0,
                      image: item['poster_finalis'] ?? "$baseUrl/noimage_finalis.png",
                      tema: color,
                      idFinalis: item['id_finalis'].toString(),
                      remaining: remaining,
                      lang: lang,
                      flag_hide_no_urut: widget.data['flag_hide_nomor_urut'],
                      flag_paket : widget.data['flag_paket'],
                      flag_login: widget.data['flag_login'],
                      flag_verify_email: widget.data['flag_verify_email'],
                      langCode: widget.langCode,
                      onAfterLogin: _onAfterLogin,
                      isTutup: isBeforeOpen,
                      isPaymentClosed: isPaymentClosed
                    ),
                  );
                } else {
                  return SizedBox.shrink();
                }
              }).toList(),
            ),
          ]
        ]

        else ... [
          Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                lang['no_leaderboard'],
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ]
      ],
    );
  }
}

class InfoSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final String langCode;
  const InfoSection({super.key, required this.data, required this.langCode});

  @override
  Widget build(BuildContext context) {
    final lang = DetailVoteLang.of(context).values;

    String themeName = 'Red';
    if (data['theme_name'] != null) {
      themeName = data['theme_name'];
    }
    if (themeName == "Default Kreen") {
      themeName = "Red";
    }

    Color color = colorMap[themeName] ?? Colors.red;

    final dateStr = data['tanggal_grandfinal_mulai']?.toString() ?? '-';
    
    String formattedDate = '-';
    
    if (dateStr.isNotEmpty) {
      try {
        final date = DateTime.parse(dateStr);
        if (langCode == 'id') {
          final formatter = DateFormat("$formatDay, $formatDateId", "id_ID");
          formattedDate = formatter.format(date);
        } else {
          final formatter = DateFormat("$formatDay, $formatDateEn", "en_US");
          formattedDate = formatter.format(date);
          
          final day = date.day;
          String suffix = 'th';
          if (day % 10 == 1 && day != 11) { suffix = 'st'; }
          else if (day % 10 == 2 && day != 12) { suffix = 'nd'; }
          else if (day % 10 == 3 && day != 13) { suffix = 'rd'; }
          formattedDate = formatter.format(date).replaceFirst('$day', '$day$suffix');
        }
      } catch (e) {
        formattedDate = '-';
      }
    }

    final formatter = NumberFormat.decimalPattern("en_US");
    final hargaFormatted = formatter.format(data['harga'] ?? 0);

    DateTime mulai = DateTime.parse("${data['tanggal_grandfinal_mulai'] ?? DateTime.now().toIso8601String().substring(0, 10)} ${data['waktu_mulai'] ?? DateTime.now().toIso8601String().substring(11, 19)}");
    DateTime selesai = DateTime.parse("${data['tanggal_grandfinal_mulai'] ?? DateTime.now().toIso8601String().substring(0, 10)} ${data['waktu_selesai'] ?? DateTime.now().toIso8601String().substring(11, 19)}");

    String jamMulai = data['waktu_mulai'] != null ? "${mulai.hour.toString().padLeft(2, '0')}:${mulai.minute.toString().padLeft(2, '0')}" : '-';
    String jamSelesai = data['waktu_selesai'] != null ? "${selesai.hour.toString().padLeft(2, '0')}:${selesai.minute.toString().padLeft(2, '0')}" : '-';

    final unescape = HtmlUnescape();
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang['grandfinal_detail'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12,),
        Container(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 0, horizontal: 20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    themeName == "Gold"
                      ? SvgPicture.asset(
                          'assets/images/Calendar.svg',
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                        )
                      : SvgPicture.network(
                          "$baseUrl/image/icon-vote/$themeName/Calendar.svg",
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                        ),

                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12,),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    themeName == "Gold"
                      ? SvgPicture.asset(
                          'assets/images/Time.svg',
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                        )
                      : SvgPicture.network(
                          "$baseUrl/image/icon-vote/$themeName/Time.svg",
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                        ),

                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: jamMulai != '-' && jamSelesai != '-' ? "$jamMulai - $jamSelesai" : '-',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                              // text: jamMulai != '-' && jamSelesai != '-' 
                              //   ? data['code_timezone'] == 'WIB'
                              //     ? " (GMT+7)"
                              //     : data['code_timezone'] == 'WITA'
                              //       ? " (GMT+8)"
                              //       : data['code_timezone'] == 'WIT'
                              //         ? " (GMT+9)"
                              //         : data['code_timezone'] != null
                              //           ? " (${data['code_timezone']})"
                              //           : ''
                              //   : '',
                              text: jamMulai != '-' && jamSelesai != '-' 
                                ? data['code_timezone'] != null 
                                  ? " (${data['code_timezone']})" 
                                  : '' 
                                : '',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ) 
        ),

        if (data['lokasi_alamat'] != null && data['lokasi_alamat'] != '' && data['lokasi_alamat'] != '-')...[
          const SizedBox(height: 15,),
          Text(
            lang['lokasi'],
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12,),
          Container(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsetsGeometry.symmetric(vertical: 0, horizontal: 20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      themeName == "Gold"
                        ? SvgPicture.asset(
                            'assets/images/Locations.svg',
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                          )
                        : SvgPicture.network(
                            "$baseUrl/image/icon-vote/$themeName/Locations.svg",
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                          ),

                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              data['lokasi_alamat'] ?? '-',
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ) 
          ),
        ],

        if (data['lokasi_nama_tempat'] != null && data['lokasi_nama_tempat'] != '' && data['lokasi_nama_tempat'] != '-') ...[
          const SizedBox(height: 15,),
          Text(
            "Venue",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12,),
          Container(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsetsGeometry.symmetric(vertical: 0, horizontal: 20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      themeName == "Gold"
                        ? SvgPicture.asset(
                            'assets/images/Locations.svg',
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                          )
                        : SvgPicture.network(
                            "$baseUrl/image/icon-vote/$themeName/Locations.svg",
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                          ),

                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              data['lokasi_nama_tempat'] != null && data['lokasi_nama_tempat'] != ''
                                ? unescape.convert(data['lokasi_nama_tempat'].toString())
                                : '-',
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ) 
          ),
        ],

        const SizedBox(height: 15,),
        Text(
          lang['harga'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12,),
        Text(
          data['harga'] == 0
          ? lang['harga_detail']
          : "Rp. $hargaFormatted",
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
        ),
      ],
    );
  }
}

class DukunganSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<dynamic> support;
  final String langCode;
  final bool isLoading;

  const DukunganSection({
    super.key, 
    required this.data, 
    required this.support, 
    required this.langCode,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final lang = DetailVoteLang.of(context).values;

    String themeName = 'Red';
    if (data['theme_name'] != null) {
      themeName = data['theme_name'];
    }
    if (themeName == "Default Kreen") {
      themeName = "Red";
    }

    Color color = colorMap[themeName] ?? Colors.red;

    Color bgColor;
    if (color is MaterialColor) {
      bgColor = color.shade200;
    } else {
      bgColor = color.withOpacity(0.1);
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: kGlobalPadding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bgColor, color],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300,),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mail_outline,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12,),
              Text(
                lang['kata_mereka'],
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: isLoading
            ? List.generate(
                1,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: buildSkeletonDukungan(),
                ),
              ) 
            : (support.isNotEmpty)
                ? support.map<Widget>((item) {
                    final dateStr = item['created_at'];
                    var hideNama = item['hide_name'];
                    var nama = item['nama'] ?? '-';
            
                    String formattedDate = '-';
          
                    if (dateStr.isNotEmpty) {
                      try {
                        final date = DateTime.parse(dateStr).toLocal();

                        if (langCode == 'id') {
                          final formatter = DateFormat("$formatDateId HH:mm", "id_ID");
                          formattedDate = "${formatter.format(date)} WIB";
                        } else {
                          final formatter = DateFormat("$formatDateEn h:mm a", "en_US");
                          formattedDate = formatter.format(date);
                          
                          final day = date.day;
                          String suffix = 'th';
                          if (day % 10 == 1 && day != 11) { suffix = 'st'; }
                          else if (day % 10 == 2 && day != 12) { suffix = 'nd'; }
                          else if (day % 10 == 3 && day != 13) { suffix = 'rd'; }
                          formattedDate = formatter.format(date).replaceFirst('$day', '$day$suffix');
                        }
                      } catch (e) {
                        formattedDate = '-';
                      }
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20), 
                      child: CommentCard(
                        namaFinalis: (item['nama_finalis'] != null &&
                            item['nama_finalis'].toString().trim().isNotEmpty)
                          ? item['nama_finalis']
                          : [],
                        name: hideNama == '0' ? nama : 'Anonymous',
                        time: formattedDate,
                        message: item['dukungan']
                      ),
                    );
                  }).toList()
                : [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        lang['no_support'],
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
        ),
      ],
    );
  }
}


Widget buildTopCard({
  required BuildContext context,
  required int rank,
  required String name,
  required num votes,
  required Color color,
  required String image,
  bool isBig = false,
  required Color tema,
  required String idFinalis,
  required Duration remaining,
  required Map<String, dynamic> lang,
  required String flag_hide_no_urut,
  required String flag_paket,
  required String flag_login,
  required String flag_verify_email,
  required String langCode,
  required VoidCallback onAfterLogin,
  bool isTutup = false,
  bool isPaymentClosed = false
}) {
  String crownImage = '';
  switch (rank) {
    case 1:
      crownImage = '$baseUrl/image/gold_crown.gif';
      break;
    case 2:
      crownImage = '$baseUrl/image/silver_crown.png';
      break;
    case 3:
      crownImage = '$baseUrl/image/bronze_crown.png';
      break;
    default:
      crownImage = '';
  }

  bool isButtonClicked = false;

  return Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.topCenter,
    children: [
      InkWell(
        onTap: (remaining.inSeconds == 0)
          ? null
          : () async {
            if (isButtonClicked) return;

            isButtonClicked = true;

            try{
              await handleVoteAction(
                context: context,
                flagLogin: flag_login,
                flagVerifyEmail: flag_verify_email,
                idFinalis: idFinalis,
                flagHideNoUrut: flag_hide_no_urut,
                flagPaket: flag_paket,
                langCode: langCode,
                tema: tema,
                onAfterLogin: onAfterLogin,
                persen: false,
              );
            } finally {
              isButtonClicked = false;
            }
        },
        child: Container(
          width: isBig ? 120 : 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300,),
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 4 / 5,
                child: Image.network(
                  image, 
                  height: isBig ? 120 : 90, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.network(
                      '$baseUrl/noimage_finalis.png',
                      height: isBig ? 120 : 90,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "$votes",
                style: TextStyle(color: tema, fontWeight: FontWeight.bold),
              ),
              Text(
                votes > 1 
                  ? lang['text_votes'] 
                  : lang['text_vote'],
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: (remaining.inSeconds == 0)
                  ? null
                  : () async {
                    if (isButtonClicked) return;

                    isButtonClicked = true;

                    try{
                      await handleVoteAction(
                        context: context,
                        flagLogin: flag_login,
                        flagVerifyEmail: flag_verify_email,
                        idFinalis: idFinalis,
                        flagHideNoUrut: flag_hide_no_urut,
                        flagPaket: flag_paket,
                        langCode: langCode,
                        tema: tema,
                        onAfterLogin: onAfterLogin,
                        persen: false,
                      );
                    } finally {
                      isButtonClicked = false;
                    }
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (states) =>
                        states.contains(MaterialState.disabled) ? Colors.grey : tema,
                  ),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 13),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                child: const Text(
                  "Vote",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),

      if (crownImage.isNotEmpty)
        Positioned(
          top: isBig ? -65 : -45,
          child: Image.network(
            crownImage,
            width: isBig ? 75 : 55,
            height: isBig ? 75 : 55,
            fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/img_broken.jpg',
                  width: isBig ? 75 : 55,
                  height: isBig ? 75 : 55,
                  fit: BoxFit.contain,
                );
              },
          ),
        ),
    ],
  );
}


Widget buildListCard({
  required BuildContext context,
  required int rank,
  required String name,
  String? nameTambahan,
  required num votes,
  required num progress,
  required String image,
  required Color tema,
  required String idFinalis,
  required Duration remaining,
  required Map<String, dynamic> lang,
  required String flag_hide_no_urut,
  required String flag_paket,
  required String flag_login,
  required String flag_verify_email,
  required String langCode,
  required VoidCallback onAfterLogin,
  bool isTutup = false,
  bool isPaymentClosed = false
}) {
  bool isButtonClicked = false;

  return InkWell(
    onTap: (isTutup || isPaymentClosed || remaining.inSeconds == 0)
      ? null
      : () async {
        if (isButtonClicked) return;

        isButtonClicked = true;

        try {
          await handleVoteAction(
            context: context,
            flagLogin: flag_login,
            flagVerifyEmail: flag_verify_email,
            idFinalis: idFinalis,
            flagHideNoUrut: flag_hide_no_urut,
            flagPaket: flag_paket,
            langCode: langCode,
            tema: tema,
            onAfterLogin: onAfterLogin,
            persen: false,
          );
        } finally {
          isButtonClicked = false;
        }
    },
    child: Container(
      padding: kGlobalPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300,),
      ),
      child: Row(
        children: [
          Text("$rank",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 50,
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.network(
                      '$baseUrl/noimage_finalis.png',
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                ),

                if (nameTambahan != null && nameTambahan.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(nameTambahan),
                ]
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                votes.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]}."),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: tema,
                ),
              ),
              Text(
                votes > 1
                  ? lang['text_votes']
                  : lang['text_vote'],
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          )
          
        ],
      ),
    ),
  );
}