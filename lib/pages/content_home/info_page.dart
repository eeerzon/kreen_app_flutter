// ignore_for_file: non_constant_identifier_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/pages/content_info/change_password.dart';
import 'package:kreen_app_flutter/pages/content_info/edit_profil.dart';
import 'package:kreen_app_flutter/pages/content_info/profile.dart';
import 'package:kreen_app_flutter/pages/content_info/tentang_page.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/pages/register_page.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:shimmer/shimmer.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final prefs = FlutterSecureStorage();
  String? langCode;
  String? login;
  String? token;

  String? first_name, last_name;
  String? email, phone;
  String? dob, photo;
  String? verifEmail;

  bool isLoading = true;

  bool isProfileMode = false;

  @override
  void initState() {
    super.initState();
    _getBahasa();
    _checkToken();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContent();
    });
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
        phone = storeUser['phone'];
        dob = storeUser['dob'];
        photo = storeUser['photo'];
        verifEmail = storeUser['verifEmail'];
      });
    }
  }

  Future<void> _getBahasa() async {
    langCode = await prefs.read(key: 'bahasa');
    
    login = await LangService.getText(langCode!, 'login');

    setState(() {
      
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
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: kGlobalPadding,
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            children: List.generate(6, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 16,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                    ),

                    const SizedBox(width: 16),
                    Container(
                      width: 16,
                      height: 16,
                      color: Colors.grey.shade300,
                    ),
                  ],
                )
              );
            })
          )
        )
      )
    );
  }

  Widget buildKonten() {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          child: isProfileMode ? buildProfileView() : buildDefaultView(),
        ),
      )
    );
  }

  Widget buildDefaultView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20,),

        token != null
          ? InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Profile(),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(14),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300,),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/img_profile.png',
                          height: 50,
                          width: 50,
                        ),
                    
                        SizedBox(width: 12,),
                        Text(
                          "Profile"
                        )
                      ],
                    ),
                    Icon(Icons.arrow_forward_ios)
                  ],
                ),
              )
            )
          : Container(
              padding: EdgeInsets.all(0),
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginPage()
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Masuk",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisPage(fromProfil: true,)
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Daftar",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

        SizedBox(height: 20,),
        Container(
          padding: EdgeInsets.all(14),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300,),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/img_bahasa.png',
                    height: 50,
                    width: 50,
                  ),
              
                  SizedBox(width: 12,),
                  Text(
                    "Bahasa"
                  )
                ],
              ),
              Icon(Icons.arrow_forward_ios)
            ],
          ),
        ),

        SizedBox(height: 20,),
        Container(
          padding: EdgeInsets.all(14),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300,),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/img_bantuan.png',
                    height: 50,
                    width: 50,
                  ),
              
                  SizedBox(width: 12,),
                  Text(
                    "Pusat Bantuan"
                  )
                ],
              ),
              Icon(Icons.arrow_forward_ios)
            ],
          ),
        ),

        SizedBox(height: 20,),
        InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TentangPage(),
                ),
              );
          },
          child: Container(
            padding: EdgeInsets.all(14),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300,),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/img_tentang.png',
                      height: 50,
                      width: 50,
                    ),
                
                    SizedBox(width: 12,),
                    Text(
                      "Tentang Kreen"
                    )
                  ],
                ),
                Icon(Icons.arrow_forward_ios)
              ],
            ),
          ),
        ),

        SizedBox(height: 20,),
        Container(
          padding: EdgeInsets.all(14),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300,),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/img_kebijakan.png',
                    height: 50,
                    width: 50,
                  ),
              
                  SizedBox(width: 12,),
                  Text(
                    "Kebijakan Privasi"
                  )
                ],
              ),
              Icon(Icons.arrow_forward_ios)
            ],
          ),
        ),

        // SizedBox(height: 20,),
        // Container(
        //   padding: EdgeInsets.all(14),
        //   width: double.infinity,
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     borderRadius: BorderRadius.circular(8),
        //     border: Border.all(color: Colors.grey.shade300,),
        //   ),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       Container(
        //         child: Row(
        //           children: [
        //             Image.asset(
        //               'assets/images/img_rating.png',
        //               height: 50,
        //               width: 50,
        //             ),

        //             SizedBox(width: 12,),
        //             Text(
        //               "Bari Rating"
        //             )
        //           ],
        //         ),
        //       ),
        //       Icon(Icons.arrow_forward_ios)
        //     ],
        //   ),
        // ),
      ],
    );
  }

  bool get isSvg => photo!.toLowerCase().endsWith(".svg");

  Widget buildProfileView() {

    String formattedDate = '-';

    if (dob!.isNotEmpty) {
      try {
        // parsing string ke DateTime
        final date = DateTime.parse(dob!); // pastikan format ISO (yyyy-MM-dd)
        if (langCode == 'id') {
          // Bahasa Indonesia
          final formatter = DateFormat("dd MMMM yyyy", "id_ID");
          formattedDate = formatter.format(date);
        } else {
          // Bahasa Inggris
          final formatter = DateFormat("MMMM d yyyy", "en_US");
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text('Profil'),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            setState(() {
              isProfileMode = false;
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
                    },
                  ),
                ),
              );

              if (result == true) {
                _fetchUserProfile(); 
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                "Edit",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )
          
        ],
      ),

      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                child: ClipOval(
                  child: isSvg
                      ? SvgPicture.network(
                          '$baseUrl/user/$photo',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          '$baseUrl/user/$photo',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                ),
              ),

              SizedBox(height: 20,),
              Text(
                "$first_name $last_name",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 20,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasu Utama'
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

                        SizedBox(height: 10,),
                        Row(
                          children: [
                            Icon(Icons.email_outlined, color: Colors.red,),

                            SizedBox(width: 12,),
                            Text(
                              email!
                            )
                          ],
                        ),

                        SizedBox(height: 10,),
                        Divider(),

                        SizedBox(height: 10,),
                        Row(
                          children: [
                            Icon(Icons.calendar_month, color: Colors.red,),

                            SizedBox(width: 12,),
                            Text(
                              formattedDate
                            )
                          ],
                        ),

                        SizedBox(height: 10,),
                        Divider(),

                        SizedBox(height: 10,),
                        Row(
                          children: [
                            Icon(Icons.phone, color: Colors.red,),

                            SizedBox(width: 12,),
                            Text(
                              phone!
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
                    'Keamanan & Regulasi'
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

                        SizedBox(height: 10,),
                        SizedBox(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChangePassword(),
                                ),
                              );
                            },
                            child: Text(
                              'Password',
                            ),
                          ),
                        ),

                        // if (verifEmail == null) ... [
                        //   SizedBox(height: 10,),
                        //   Divider(),

                        //   SizedBox(height: 10,),
                        //   SizedBox(
                        //     child: InkWell(
                        //       onTap: () {
                                
                        //       },
                        //       child: Text(
                        //         'Verifikasi Email',
                        //       ),
                        //     ),
                        //   ),
                        // ],
                        

                        SizedBox(height: 10,),
                        Divider(),

                        SizedBox(height: 10,),
                        SizedBox(
                          child: InkWell(
                            onTap: () {
                              
                            },
                            child: Text(
                              'Pusat Bantuan',
                            ),
                          ),
                        ),

                        SizedBox(height: 10,),
                        Divider(),

                        SizedBox(height: 10,),
                        SizedBox(
                          child: InkWell(
                            onTap: () {
                              
                            },
                            child: Text(
                              'Kebijakan Privasi',
                            ),
                          ),
                        ),

                        SizedBox(height: 10,),
                        Divider(),

                        SizedBox(height: 10,),
                        SizedBox(
                          child: InkWell(
                            onTap: () {
                              
                            },
                            child: Text(
                              'Tentang Kreen',
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
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Keluar",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              SizedBox(height: 40,),
            ],
          ),
        ),
      ) 
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
    });
  }

}