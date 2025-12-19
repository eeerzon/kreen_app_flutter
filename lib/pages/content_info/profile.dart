// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/pages/content_info/change_password.dart';
import 'package:kreen_app_flutter/pages/content_info/edit_profil.dart';
import 'package:kreen_app_flutter/pages/content_info/help_center.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:shimmer/shimmer.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? langCode;
  String? login, keluar;
  String? token;

  String? first_name, last_name;
  String? email, phone;
  String? gender;
  String? dob, photo;
  String? verifEmail;
  String? company;
  String? jobTitle;
  String? link_linkedin;
  String? link_ig;
  String? link_twitter;

  bool isLoading = true;

  Map<String, dynamic> infoLang = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async{
      await _getBahasa();
      await _checkToken();
      await _loadContent();
    });
  }

  bool get isSvg {
    final p = photo;
    if (p == null) return false;
    return p.toLowerCase().endsWith(".svg");
  }

  bool get isHttp {
    final p = photo;
    if (p == null) return false;
    return p.toLowerCase().contains("http");
  }

  Future<void> _checkToken() async {
    final storedToken = await StorageService.getToken();
    final storeUser = await StorageService.getUser();
    if (mounted) {
      setState(() {
        token = storedToken;

        first_name = storeUser['first_name'];
        last_name = storeUser['last_name'];
        email = storeUser['email'];
        gender = storeUser['gender'];
        phone = storeUser['phone'];
        dob = storeUser['dob'];
        photo = storeUser['photo'];
        verifEmail = storeUser['verifEmail'];
        company = storeUser['company'];
        jobTitle = storeUser['jobTitle'];
        link_linkedin = storeUser['link_linkedin'];
        link_ig = storeUser['link_ig'];
        link_twitter = storeUser['link_twitter'];
      });
    }
  }

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();
    setState(() {
      langCode = code;
    });
    
    final templogin = await LangService.getText(langCode!, 'login');
    final tempkeluar = await LangService.getText(langCode!, 'keluar');
    final tempinfolang = await LangService.getJsonData(langCode!, 'info');

    setState(() {
      login = templogin;
      keluar = tempkeluar;
      infoLang = tempinfolang;
    });
  }

  Future<void> _loadContent() async {
    var get_user = await StorageService.getUser();
    first_name = get_user['first_name'];

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? buildSkeleton()
          : buildKonten()
    ); 
  }

  Widget buildSkeleton() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 40,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        centerTitle: false,
        leading: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(height: 40, width: 40, color: Colors.white)
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: kGlobalPadding,
          child: Column(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                ),
              ),

              const SizedBox(height: 20),

              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 150,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }


  Widget buildKonten() {
    String formattedDate = '-';

    if (dob != null) {
      try {
        // parsing string ke DateTime
        final date = DateTime.parse(dob!); // pastikan format ISO (yyyy-MM-dd)
        if (langCode == 'id') {
          // Bahasa Indonesia
          final formatter = DateFormat("dd MMMM yyyy", "id_ID");
          formattedDate = formatter.format(date);
        } else {
          // Bahasa Inggris
          final formatter = DateFormat("MMMM d, yyyy", "en_US");
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(infoLang['profil'] ?? ""),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            setState(() {
              Navigator.pop(context);
            });
          },
        ),
        actions: [
          InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(
                    user: {
                      'photo': photo,
                      'first_name': first_name,
                      'last_name': last_name,
                      'email': email,
                      'phone': phone,
                      'dob': dob,
                      'gender': gender,
                      'company': company,
                      'jobTitle': jobTitle,
                      'link_linkedin': link_linkedin,
                      'link_ig': link_ig,
                      'link_twitter': link_twitter,
                      'verified_email': verifEmail
                    },
                  ),
                ),
              );

              if (result == true) {
                _fetchUserProfile(); 
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric( vertical: 18 ,horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                "Edit",
                style: TextStyle(fontSize: 18),
              ),
            ),
          )
          
        ],
      ),

      body: Padding(
        padding: kGlobalPadding,
        child: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  child: ClipOval(
                    child: photo != null 
                      ?
                        isSvg
                          ? SvgPicture.network(
                              '$baseUrl/user/$photo',
                              width: 120,
                              height: 120,
                              fit: BoxFit.fill,
                            )
                          : isHttp
                            ? Image.network(
                                photo!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.fill,
                              )
                            : Image.network(
                                '$baseUrl/user/$photo',
                                width: 120,
                                height: 120,
                                fit: BoxFit.fill,
                              )
                      : Image.network(
                          "$baseUrl/noimage_finalis.png",
                          width: 120,
                          height: 120,
                          fit: BoxFit.fill,
                        )
                  ),
                ),

                SizedBox(height: 20,),
                Text(
                  "$first_name $last_name",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),

                SizedBox(height: 20,),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      infoLang['informasi_utama'] ?? "", //'Informasi Utama',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    SizedBox(height: 10,),
                    Container(
                      padding: EdgeInsets.all(14),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300,),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          //tanggal lahir
                          SizedBox(height: 10,),
                          Row(
                            children: [
                              Icon(Icons.cake_outlined, color: Colors.red,),

                              SizedBox(width: 12,),
                              Text(
                                formattedDate
                              )
                            ],
                          ),

                          //gender
                          if (gender != null) ... [

                            SizedBox(height: 10,),
                            Divider(),
                            
                            SizedBox(height: 10,),
                            Row(
                              children: [
                                Icon(FontAwesomeIcons.transgender, color: Colors.red,),

                                SizedBox(width: 12,),
                                Text(
                                  gender ?? '-'
                                )
                              ],
                            ),
                          ],

                          //company
                          if (company != null) ... [

                            SizedBox(height: 10,),
                            Divider(),

                            SizedBox(height: 10,),
                            Row(
                              children: [
                                Icon(FontAwesomeIcons.building, color: Colors.red,),

                                SizedBox(width: 12,),
                                Text(
                                  company ?? '-'
                                )
                              ],
                            ),
                          ],

                          //jobTitle
                          if (jobTitle != null) ... [

                            SizedBox(height: 10,),
                            Divider(),

                            SizedBox(height: 10,),
                            Row(
                              children: [
                                Icon(FontAwesomeIcons.briefcase, color: Colors.red,),

                                SizedBox(width: 12,),
                                Text(
                                  jobTitle ?? '-'
                                )
                              ],
                            ),
                          ],
                        ],
                      )
                    ),
                  ],
                ),

                SizedBox(height: 20,),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      infoLang['informasi_akun'] ?? "", //'Informasi Akun',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    SizedBox(height: 10,),
                    Container(
                      padding: EdgeInsets.all(14),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300,),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          //email
                          SizedBox(height: 10,),
                          Row(
                            children: [
                              Icon(FontAwesomeIcons.googlePlay, color: Colors.red,),

                              SizedBox(width: 12,),
                              Text(
                                email ?? '-'
                              )
                            ],
                          ),

                          SizedBox(height: 10,),
                          Divider(),

                          //nomor telepon
                          SizedBox(height: 10,),
                          Row(
                            children: [
                              Icon(Icons.phone, color: Colors.red,),

                              SizedBox(width: 12,),
                              Text(
                                phone != '' && phone!.isNotEmpty
                                  ? phone!
                                  : '-',
                              )
                            ],
                          ),
                        ],
                      )
                    ),
                  ],
                ),



                SizedBox(height: 20,),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      infoLang['media_sosial'] ?? "", //'Media Sosial',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    SizedBox(height: 10,),
                    Container(
                      padding: EdgeInsets.all(14),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300,),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          //linked in
                          SizedBox(height: 10,),
                          Row(
                            children: [
                              Icon(FontAwesomeIcons.linkedinIn, color: Colors.red,),

                              SizedBox(width: 12,),
                              Text(
                                link_linkedin != null && link_linkedin!.isNotEmpty
                                    ? extractUsername(link_linkedin)
                                    : '-',
                              )
                            ],
                          ),

                          SizedBox(height: 10,),
                          Divider(),

                          //instagram
                          SizedBox(height: 10,),
                          Row(
                            children: [
                              Icon(FontAwesomeIcons.instagram, color: Colors.red,),

                              SizedBox(width: 12,),  
                              Text(
                                link_ig != null && link_ig!.isNotEmpty
                                    ? extractUsername(link_ig)
                                    : '-',
                              )
                            ],
                          ),

                          SizedBox(height: 10,),
                          Divider(),

                          //twitter
                          SizedBox(height: 10,),
                          Row(
                            children: [
                              Icon(FontAwesomeIcons.twitter, color: Colors.red,),

                              SizedBox(width: 12,),
                              Text(
                                link_twitter != null && link_twitter!.isNotEmpty
                                    ? extractUsername(link_twitter)
                                    : '-',
                              )
                            ],
                          ),
                        ],
                      )
                    ),
                  ],
                ),

                SizedBox(height: 20,),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      infoLang['keamanan'] ?? "", //'Keamanan & Regulasi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    SizedBox(height: 10,),
                    Container(
                      padding: EdgeInsets.all(14),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300,),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          //password
                          SizedBox(height: 10,),
                          SizedBox(
                            width: double.infinity,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ChangePassword(),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.lock, color: Colors.red,),

                                  SizedBox(width: 12,),
                                  Text(
                                    infoLang['pengaturan_password'] ?? "", //'Pengaturan Sandi',
                                  )
                                ],
                              ),
                            ),
                          ),

                          if (verifEmail == '0') ... [
                            SizedBox(height: 10,),
                            Divider(),

                            SizedBox(height: 10,),
                            SizedBox(
                              child: InkWell(
                                onTap: () async {
                                  final resultVerifEmail = await ApiService.postSetProfil('$baseapiUrl/send-email-verification',token: token, body: null);

                                  if (resultVerifEmail?['rc'] == 200) {
                                    AwesomeDialog(
                                      context: context,
                                      dialogType: DialogType.success,
                                      title: langCode == 'id' ? 'Berhasil' : 'Success',
                                      desc: resultVerifEmail?['message'],
                                      transitionAnimationDuration: const Duration(milliseconds: 1000),
                                      autoHide: const Duration(seconds: 1),
                                    ).show();
                                  } else {
                                    AwesomeDialog(
                                      context: context,
                                      dialogType: DialogType.error,
                                      animType: AnimType.topSlide,
                                      title: 'Oops!',
                                      desc: resultVerifEmail?['message'],
                                      btnOkOnPress: () {},
                                      btnOkColor: Colors.red,
                                      buttonsTextStyle: TextStyle(color: Colors.white),
                                      headerAnimationLoop: false,
                                      dismissOnTouchOutside: true,
                                      showCloseIcon: true,
                                    ).show();
                                  }
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.email, color: Colors.red,),

                                    SizedBox(width: 12,),
                                    Text(
                                      infoLang['verif_email'] ?? "", //']'Verifikasi Email',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          SizedBox(height: 10,),
                          Divider(),

                          //pusat bantuan
                          SizedBox(height: 10,),
                          SizedBox(
                            width: double.infinity,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HelpCenterPage(),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.help_center, color: Colors.red,),

                                  SizedBox(width: 12,),
                                  Text(
                                    infoLang['pusat_bantuan'] ?? "", //'Pusat Bantuan',
                                  )
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 10,),
                          Divider(),

                          //kebijakan privasi
                          SizedBox(height: 10,),
                          SizedBox(
                            width: double.infinity,
                            child: InkWell(
                              onTap: () {},
                              child: Row(
                                children: [
                                  Icon(Icons.privacy_tip, color: Colors.red,),

                                  SizedBox(width: 12,),
                                  Text(
                                    infoLang['kebijakan_privasi'] ?? "", //'Kebijakan Privasi',
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    ),
                  ],
                ),
                
                SizedBox(height: 20,),
                InkWell(
                  onTap: () async {
                    await StorageService.clearUser();
                    await StorageService.clearToken();
                    setState(() {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(
                            fromLogout: true,
                          )
                        ),
                        (Route<dynamic> route) => false,
                      );
                    });
                  },
                  child: Container(
                    height: 48,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      keluar!, //"Keluar",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                SizedBox(height: 40,),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _fetchUserProfile() async {
    final user = await StorageService.getUser();
    setState(() {
      first_name = user['first_name'];
      last_name = user['last_name'];
      email = user['email'];
      phone = user['phone'];
      dob = user['dob'];
      photo = user['photo'];
      gender = user['gender'];
      company = user['company'];
      jobTitle = user['jobTitle'];
      link_linkedin = user['link_linkedin'];
      link_ig = user['link_ig'];
      link_twitter = user['link_twitter'];
    });
  }

  String extractUsername(String? url) {
    if (url == null || url.isEmpty) return '-';
    
    url = url.trim().replaceAll(RegExp(r'/+$'), '');
    
    if (!url.contains('/')) return url;
    
    String lastSegment = url.split('/').last;

    // Handle LinkedIn yang kadang pakai "in/" atau "company/"
    // Contoh: https://www.linkedin.com/in/admingg
    if (url.contains('linkedin.com')) {
      return lastSegment;
    }

    // Twitter / X
    if (url.contains('twitter.com') || url.contains('x.com')) {
      return lastSegment;
    }

    // Instagram
    if (url.contains('instagram.com')) {
      return lastSegment;
    }
    
    return lastSegment;
  }

}