import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TentangPage extends StatefulWidget {
  const TentangPage({super.key});

  @override
  State<TentangPage> createState() => _TentangPageState();
}

class _TentangPageState extends State<TentangPage> {
  late YoutubePlayerController _controller;

  String extractVideoId(String url) {
    try {
      return YoutubePlayer.convertUrlToId(url) ?? "";
    } catch (_) {
      return "";
    }
  }

  @override
  void initState() {
    super.initState();

    String link = 'https://www.youtube.com/embed/vrPwy3HZe-w?si=lAEecnRgNEN2ZZGE';

    final videoId = extractVideoId(link);

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text("Tentang Kami"),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: kGlobalPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                aspectRatio: 16 / 9,
              ),

              SizedBox(height: 15,),
              Text(
                'PT. Tiket Keren Indonesia',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              Text(
                'PT. Tiket Keren Nusantara / KREEN is an event company that connects B2B, B2C, and B2G. With networking that reaches various industrial sectors, KREEN has been trusted to help companies and communities on a global and local scale in succeding the events that are held. With the support of the KREEN team, we always prioritize creative and innovative ways of carrying out an event. It’s our mission to fulfil the needs of our clients by creating unforgettable events with innovative ideas, all to exceed the expectations. We have a vision to become a global leader market in creative industry that integrates conferencing, exhibition, advertising and entertainment.',
                softWrap: true,
                textAlign: TextAlign.justify,
              ),

              SizedBox(height: 15,),
              Text(
                'Kantor di Indonesia',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              Text(
                'PT TIKET KEREN NUSANTARA \n Rukan CBD Blok E No.5, Jl. Green Lake City, Desa/Kelurahan Gondrong,\nKec. Cipondoh, Kota Tangerang, Provinsi Banten,\nKode Pos: 15146',
                softWrap: true,
                textAlign: TextAlign.justify,
              ),

              SizedBox(height: 15,),
              Text(
                'Kantor di Singapura',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              Text(
                'AYRTONWARE PTE. LTD.\n68 Circular Road,\n#02-01, Singapore\n049422',
                softWrap: true,
                textAlign: TextAlign.justify,
              ),

              SizedBox(height: 15,),
              Text(
                'Hubungi Kami',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8,),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.red,
                      Colors.orange.shade700
                    ]
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: InkWell(
                  onTap: () async {
                    Uri? uri = Uri.tryParse('https://wa.me/6285232304965');
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      await launchUrl(Uri.parse("https://google.com"), mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SvgPicture.network(
                        "$baseUrl/image/cs.svg",
                        height: 40,
                        width: 30,
                      ),
                      SizedBox(width: 15,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Support',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Kenta - 62 852-3230-4965',
                            style: TextStyle(color: Colors.white,),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              SizedBox(height: 15,),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.red,
                      Colors.orange.shade700
                    ]
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: InkWell(
                  onTap: () async {
                    Uri? uri = Uri.tryParse('https://wa.me/6282124594440');
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      await launchUrl(Uri.parse("https://google.com"), mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SvgPicture.network(
                        "$baseUrl/image/wa-white.svg",
                        height: 40,
                        width: 30,
                      ),
                      SizedBox(width: 15,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event dan Vote',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Julia - 62 821-2459-4440',
                            style: TextStyle(color: Colors.white,),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              SizedBox(height: 15,),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.red,
                      Colors.orange.shade700
                    ]
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: InkWell(
                  onTap: () async {
                    final Uri email = Uri(
                      scheme: 'mailto',
                      path: 'info@kreen.id',
                    );

                    if (await canLaunchUrl(email)) {
                      await launchUrl(email);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SvgPicture.network(
                        "$baseUrl/image/mail-white.svg",
                        height: 30,
                        width: 30,
                      ),
                      SizedBox(width: 15,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Us',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'info@kreen.id',
                            style: TextStyle(color: Colors.white,),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              SizedBox(height: 15,),
              Text(
                'Terhubung dengan Kami',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSocialButton(
                    iconUrl: "$baseUrl/image/ig-orange.svg",
                    link: 'https://www.instagram.com/kreenindonesia/',
                    platform: "instagram",
                  ),
                  _buildSocialButton(
                    iconUrl: "$baseUrl/image/linkedin-orange.svg",
                    link: 'https://www.linkedin.com/company/kerenindonesia/',
                    platform: "linkedin",
                  ),
                  _buildSocialButton(
                    iconUrl: "$baseUrl/image/wa-orange.svg",
                    link: 'https://wa.me/6282124594440',
                    platform: "whatsapp",
                  ),
                  _buildSocialButton(
                    iconUrl: "$baseUrl/image/fb-orange.svg",
                    link: 'https://web.facebook.com/kreenindonesia/?_rdc=1&_rdr',
                    platform: "facebook",
                  ),
                ],
              ),

              SizedBox(height: 15,),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String iconUrl,
    required String? link,
    required String platform,
  }) {
    final bool isEmpty = link == null || link.trim().isEmpty;

    return GestureDetector(
      onTap: isEmpty
          ? null
          : () async {
              Uri? uri = Uri.tryParse(link);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                await launchUrl(Uri.parse("https://google.com"), mode: LaunchMode.externalApplication);
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: SvgPicture.network(
          iconUrl,
          height: 30,
          width: 30,
          colorFilter: isEmpty
              ? const ColorFilter.mode(Colors.grey, BlendMode.srcIn)
              : null,
        ),
      ),
    );
  }
}