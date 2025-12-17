// ignore_for_file: camel_case_types, deprecated_member_use, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/modal/faq_modal.dart';
import 'package:kreen_app_flutter/modal/s_k_modal.dart';
import 'package:kreen_app_flutter/modal/tutor_modal.dart';
import 'package:kreen_app_flutter/pages/vote/detail_finalis.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote_lang.dart';
import 'package:share_plus/share_plus.dart';

class DeskripsiSection_5 extends StatelessWidget {
  final Map<String, dynamic> data;
  final String langCode;
  const DeskripsiSection_5({super.key, required this.data, required this.langCode});

  @override
  Widget build(BuildContext context) {
    final lang = DetailVoteLang.of(context).values;

    Map<String, Color> colorMap = {
      'Blue': Colors.blue,
      'Red': Colors.red,
      'Green': Colors.green,
      'Yellow': Colors.yellow,
      'Purple': Colors.purple,
      'Orange': Colors.orange,
      'Pink': Colors.pink,
      'Grey': Colors.grey,
      'Turqoise': Colors.teal,
    };

    String themeName = 'Red';
    if (data['theme_name'] != null) {
      themeName = data['theme_name'];
    }
    Color color = colorMap[themeName] ?? Colors.red;

    Color bgColor;
    if (color is MaterialColor) {
      bgColor = color.shade50;
    } else {
      bgColor = color.withOpacity(0.1);
    }

    final dateStr = data['tanggal_grandfinal_mulai']?.toString() ?? '-';
    
    String formattedDate = '-';
    
    if (dateStr.isNotEmpty) {
      try {
        // parsing string ke DateTime
        final date = DateTime.parse(dateStr); // pastikan format ISO (yyyy-MM-dd)
        if (langCode == 'id') {
          // Bahasa Indonesia
          final formatter = DateFormat("EEEE, dd MMMM yyyy", "id_ID");
          formattedDate = formatter.format(date);
        } else {
          // Bahasa Inggris
          final formatter = DateFormat("EEEE, MMMM d yyyy", "en_US");
          formattedDate = formatter.format(date);

          // tambahkan suffix (1st, 2nd, 3rd, 4th...)
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

    final formatter = NumberFormat.decimalPattern("id_ID");
    final hargaFormatted = formatter.format(data['harga'] ?? 0);

    DateTime mulai = DateTime.parse("${data['tanggal_grandfinal_mulai']} ${data['waktu_mulai']}");
    DateTime selesai = DateTime.parse("${data['tanggal_grandfinal_mulai']} ${data['waktu_selesai']}");

    String jamMulai = "${mulai.hour.toString().padLeft(2, '0')}:${mulai.minute.toString().padLeft(2, '0')}";
    String jamSelesai = "${selesai.hour.toString().padLeft(2, '0')}:${selesai.minute.toString().padLeft(2, '0')}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInImage.assetNetwork(
          placeholder: 'assets/images/img_placeholder.jpg',
          image: data['banner'],
          width: double.infinity,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 300),
          imageErrorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/images/img_broken.jpg',
              width: double.infinity,
              fit: BoxFit.cover,
            );
          },
        ),

        const SizedBox(height: 8),

        Padding(
          padding: kGlobalPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['judul_vote'] ?? '-',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // title event
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          data['nama_kategori'] ?? '-',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]
                  ),

                  InkWell(
                    onTap: () {
                      Share.share(
                        "$baseUrl/voting/${data['vote_slug']}",
                        subject: data['judul_vote'],
                      );
                    },
                    child: SvgPicture.network(
                      '$baseUrl/image/icon-vote/$themeName/share-red.svg',
                      height: 40,
                      width: 40,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),

              // tombol list horizontal
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        await FaqModal.show(context, data['faq']);
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
                        await TutorModal.show(context, data['tutorial_vote']);
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color, // outline merah
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

                    const SizedBox(width: 5),
                    InkWell(
                      onTap: () async {
                        await SKModal.show(context, data['snk']);
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color, // outline merah
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
                ),
              ),
              const SizedBox(height: 18),

              Container(
                color: Colors.white,
                child: Padding(
                  padding: kGlobalPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Image.network(
                            data['icon_penyelenggara'],
                            width: 80,   // atur sesuai kebutuhan
                            height: 80,
                            fit: BoxFit.contain,
                          ),

                          const SizedBox(width: 12),
                          //text
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
                                  data['nama_penyelenggara'],
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  softWrap: true,          // biar teks bisa kebungkus
                                  overflow: TextOverflow.visible, 
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40,),
                      Text(
                        lang['deskripsi'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 12,),
                      Container(
                        color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                          child: Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (data['merchant_description'] != null) ... [
                                    Html(
                                      data: data['merchant_description'],
                                      style: {
                                        "p": Style(
                                          margin: Margins.zero,
                                          padding: HtmlPaddings.zero,
                                        ),
                                        "body": Style(
                                          margin: Margins.zero,
                                          padding: HtmlPaddings.zero,
                                        ),
                                      },
                                    ),
                                    SizedBox(height: 12,)
                                  ],
                                  Html(
                                    data: data['deskripsi'],
                                      style: {
                                        "p": Style(
                                          margin: Margins.zero,
                                          padding: HtmlPaddings.zero,
                                        ),
                                        "body": Style(
                                          margin: Margins.zero,
                                          padding: HtmlPaddings.zero,
                                        ),
                                      },
                                  )
                                ],
                              ),
                            ],
                          ),
                        ) 
                      ),

                      const SizedBox(height: 20,),
                      Text(
                        lang['grandfinal_detail'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 12,),
                      Container(
                        color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  SvgPicture.network(
                                    "$baseUrl/image/icon-vote/$themeName/Calendar.svg",
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),

                                  const SizedBox(width: 12),
                                  //text
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  SvgPicture.network(
                                    "$baseUrl/image/icon-vote/$themeName/Time.svg",
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),

                                  const SizedBox(width: 12),
                                  //text
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "$jamMulai - $jamSelesai",
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                            ),
                                          ),
                                          TextSpan(
                                            text: data['code_timezone'] == 'WIB'
                                              ? " (GMT+7)"
                                              : data['code_timezone'] == 'WITA'
                                                ? " (GMT+8)"
                                                : data['code_timezone'] == 'WIT'
                                                  ? " (GMT+9)"
                                                  : "",
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

                      const SizedBox(height: 20,),
                      Text(
                        lang['lokasi'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 12,),
                      Container(
                        color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  SvgPicture.network(
                                    "$baseUrl/image/icon-vote/$themeName/Locations.svg",
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),

                                  const SizedBox(width: 12),
                                  //text
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

                      const SizedBox(height: 20,),
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
                                  SvgPicture.network(
                                    "$baseUrl/image/icon-vote/$themeName/Locations.svg",
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),

                                  const SizedBox(width: 12),
                                  //text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          data['lokasi_nama_tempat'],
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

                      const SizedBox(height: 20,),
                      Text(
                        lang['harga'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12,),
                      Text(
                        data['harga'] == 0
                        ? lang['harga_detail']
                        : "${data['currency']} $hargaFormatted",
                        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 20),
                      ),
                    ],
                  ),
                ) 
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class LeaderboardSection_5 extends StatelessWidget {
  final List<dynamic> ranking;
  final Map<String, dynamic> data;
  final String langCode;
  const LeaderboardSection_5({super.key, required this.ranking, required this.data, required this.langCode});

  @override
  Widget build(BuildContext context) {
    final lang = DetailVoteLang.of(context).values;

    Map<String, Color> colorMap = {
      'Blue': Colors.blue,
      'Red': Colors.red,
      'Green': Colors.green,
      'Yellow': Colors.yellow,
      'Purple': Colors.purple,
      'Orange': Colors.orange,
      'Pink': Colors.pink,
      'Grey': Colors.grey,
      'Turqoise': Colors.teal,
    };

    String themeName = 'Red';
    if (data['theme_name'] != null) {
      themeName = data['theme_name'];
    }
    Color color = colorMap[themeName] ?? Colors.red;

    Color bgColor;
    if (color is MaterialColor) {
      bgColor = color.shade200;
    } else {
      bgColor = color.withOpacity(0.1);
    }

    final List<int> customOrder = [2, 1, 3];

    final List<dynamic> topThree = ranking
        .where((item) => customOrder.contains(item['rank']))
        .toList()
      ..sort((a, b) => customOrder.indexOf(a['rank']).compareTo(customOrder.indexOf(b['rank'])));

    final List<dynamic> others = ranking
        .where((item) => item['rank'] >= 4)
        .toList()
      ..sort((a, b) => (a['rank'] as int).compareTo(b['rank'] as int));

    DateTime deadline = DateTime.parse(data['tanggal_tutup_vote']);
    Duration remaining = Duration.zero;
    final now = DateTime.now();
    final difference = deadline.difference(now);

    remaining = difference.isNegative ? Duration.zero : difference;

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
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6), // jarak icon ke lingkaran
                decoration: const BoxDecoration(
                  color: Colors.white, // background lingkaran
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FontAwesomeIcons.crown, // icon mahkota
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
                data['judul_vote'],
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              )
            ],
          ),
        ),

        // konten data dari data api
        if (ranking.isNotEmpty) ... [
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

              return buildTopCard(
                context: context, 
                rank: item['rank'], 
                name: item['nama_finalis'], 
                votes: item['percent'], 
                color: colors, 
                isBig: big, 
                image: item['poster_finalis'] ?? "$baseUrl/noimage_finalis.png",
                tema: color, 
                idFinalis: item['id_finalis'].toString(),
                remaining: remaining,
                flag_hide_no_urut: data['flag_hide_nomor_urut']
              );

            }).toList(),
          ),

          if (data['leaderboard_limit_tampil'] > 3) ... [
            const SizedBox(height: 20),
            Column(
              children: others.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20), // jarak antar item
                    child: buildListCard(
                      rank: item['rank'],
                      name: item['nama_finalis'],
                      votes: item['total_voters'],
                      image: item['poster_finalis'] ?? "$baseUrl/noimage_finalis.png",
                      persentase: item['percent'],
                      tema: color
                    ),
                );
              }).toList(),
            )
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
        ],
      ],
    );
  }
}

class DukunganSection_5 extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<dynamic> support;
  final String langCode;
  const DukunganSection_5({super.key, required this.data, required this.support, required this.langCode});

  @override
  Widget build(BuildContext context) {
    final lang = DetailVoteLang.of(context).values;

    Map<String, Color> colorMap = {
      'Blue': Colors.blue,
      'Red': Colors.red,
      'Green': Colors.green,
      'Yellow': Colors.yellow,
      'Purple': Colors.purple,
      'Orange': Colors.orange,
      'Pink': Colors.pink,
      'Grey': Colors.grey,
      'Turqoise': Colors.teal,
    };

    String themeName = 'Red';
    if (data['theme_name'] != null) {
      themeName = data['theme_name'];
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
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bgColor, color],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: BorderRadius.circular(8),
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
          children: (data['dukungan'] != null && data['dukungan'].isNotEmpty)
          ? data['dukungan'].map<Widget>((item) {
            final dateStr = item['created_at'];
            var hideNama = item['hide_name'];
            var nama = item['nama'] ?? '-';
    
            String formattedDate = '-';
  
            if (dateStr.isNotEmpty) {
              try {
                final date = DateTime.parse(dateStr);

                if (langCode == 'id') {
                  // Bahasa Indonesia
                  final formatter = DateFormat("dd MMMM yyyy HH:mm", "id_ID");
                  formattedDate = "${formatter.format(date)} WIB";
                } else {
                  // Bahasa Inggris
                  final formatter = DateFormat("MMMM d yyyy HH:mm", "en_US");
                  formattedDate = formatter.format(date);

                  // Tambahkan suffix hari
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
              padding: const EdgeInsets.only(bottom: 20), // jarak antar item
              child: CommentCard(
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
  required double votes,
  required Color color,
  required String image,
  bool isBig = false,
  required Color tema,
  required String idFinalis,
  required Duration remaining,
  required String flag_hide_no_urut
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

  return Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.topCenter,
    children: [
      Container(
        width: isBig ? 120 : 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300,),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Image.network(
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
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "$votes%",
              style: TextStyle(color: tema, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailFinalisPage(
                      id_finalis: idFinalis,
                      count: 0,
                      indexWrap: null,
                      flag_hide_no_urut: flag_hide_no_urut
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                backgroundColor: tema,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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

      if (crownImage.isNotEmpty)
        Positioned(
          top: isBig ? -65 : -45,
          child: Image.network(
            crownImage,
            width: isBig ? 75 : 55,
            height: isBig ? 75 : 55,
            fit: BoxFit.contain,
          ),
        ),
    ],
  );
}

Widget buildListCard({
  required int rank,
  required String name,
  required int votes,
  required String image,
  required double persentase,
  required Color tema
}) {
  // hitung persentase
  final double progress = persentase / 100;

  return Container(
    padding: kGlobalPadding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300,),
    ),
    child: Row(
      children: [
      
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.circle, size: 32, color: Colors.white),
            Text(
              "$rank",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
            
        const SizedBox(width: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            image, 
            height: 50, 
            width: 50, 
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.network(
                '$baseUrl/noimage_finalis.png',
                height: 50,
                width: 50,
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(10),
                color: tema,
                backgroundColor: Colors.grey.shade200,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            Text(
              "$persentase%", // tampil persentase
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: tema,
              ),
            ),
          ],
        )
        
      ],
    ),
  );
}

Widget CommentCard({
  required String name,
  required String time,
  required String message,
}) {
  return Container(
    width: double.infinity,
    padding: kGlobalPadding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300,),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, // biar teks rata kiri
      children: [
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        Text(
          time,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),

        const SizedBox(height: 15),

        Text(
          message,
          softWrap: true, // biar otomatis turun ke bawah
        ),
      ],
    ),
  );

}