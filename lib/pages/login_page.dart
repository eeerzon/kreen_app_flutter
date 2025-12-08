// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:kreen_app_flutter/widgets/google_login.dart';
import 'package:kreen_app_flutter/widgets/loading_page.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '/services/lang_service.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final bool notLog;
  const LoginPage({super.key, this.notLog = false,});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final prefs = FlutterSecureStorage();

  String dialog_title = "";
  String input_email = "";
  String input_password = "";
  String lupa_password = "";
  String login = "";
  String login_as = "";
  String belum = "";
  String daftar = "";
  

  bool get _isFormFilled =>
      _emailController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty;

  OutlineInputBorder _border(bool isFilled) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isFilled ? Colors.orange : Colors.grey.shade400,
        width: 1.5,
      ),
    );
  }

  Future<void> _loadPrefBahasa() async {
  final savedLang = await prefs.read(key: 'bahasa'); // String? kalau ada, null kalau belum

  if (savedLang != null) {
    setState(() {
      _selectedLang = savedLang; // langsung aja, ga perlu `as String`
    });
    _loadLanguage(savedLang); // langsung dipakai
  }
}


  void _doLogin() async {
    showLoadingDialog(context); // tampilkan loading
    
    final body = {
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
    };

    final result = await ApiService.post("/login", body: body);

    if (!mounted) return;

    hideLoadingDialog(context);

    if (result != null && result['success'] == true && result['rc'] == 200) {
      final user = result['data']['user'];
      final token = result['data']['token'];

      // simpan ke secure storage
      await StorageService.setToken(token);
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

      if (widget.notLog) {
        // jika login dari halaman lain
        Navigator.pop(context, true);
      } else {
        // jika login dari splashscreen
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } else {
      // gagal login
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: 'Gagal',
        desc: result?['message'] ?? 'Username atau password salah!',
        btnOkOnPress: () {},
      ).show();
    }
  }

  //setting bahasa
  Future<void> _loadLanguage(String langCode) async {

    final data_dialog = await LangService.getText(langCode, "dialog_title");
    setState(() {
      dialog_title = data_dialog;
    });

    final data_email = await LangService.getText(langCode, "input_email");
    setState(() {
      input_email = data_email;
    });

    final data_pass = await LangService.getText(langCode, "input_password");
    setState(() {
      input_password = data_pass;
    });

    final data_pass_lupa = await LangService.getText(langCode, "lupa_password");
    setState(() {
      lupa_password = data_pass_lupa;
    });

    final data_login = await LangService.getText(langCode, "login");
    setState(() {
      login = data_login;
    });

    final data_login_as = await LangService.getText(langCode, "login_as");
    setState(() {
      login_as = data_login_as;
    });

    final data_belum = await LangService.getText(langCode, "belum");
    setState(() {
      belum = data_belum;
    });

    final data_daftar = await LangService.getText(langCode, "daftar");
    setState(() {
      daftar = data_daftar;
    });
  }

  String _selectedLang = "id";
  final Map<String, String> languages = {
    "id": "Indonesia",
    "en": "English"
  };

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempLang = _selectedLang; // buat sementara
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dialog_title),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: languages.entries.map((entry) {
                    return RadioListTile<String>(
                      value: entry.key,
                      groupValue: tempLang,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedLang = val; // update global
                          });
                          setStateDialog(() {
                            tempLang = val; // update local
                          });
                          _loadLanguage(val);
                          Navigator.pop(context); // langsung tutup popup
                        }
                      },
                      title: Row(
                        children: [
                          Image.asset(
                            "assets/flags/${entry.key}.png", // simpan bendera di folder assets/flags
                            width: 28,
                            height: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(entry.value),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPrefBahasa();
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
        title: Text(login),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: Stack(
        children: [
          //konten page
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  //logo
                  Column(
                    children: [
                      Image.asset(
                        "assets/images/img_homekreen.png",
                        width: 200,   // atur sesuai kebutuhan
                        height: 200,
                        fit: BoxFit.contain, // biar proporsional tanpa crop
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                  //email
                  const SizedBox(height: 35),
                  TextField(
                    controller: _emailController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: input_email,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: _border(_emailController.text.isNotEmpty),
                      focusedBorder: _border(true),
                    ),
                  ),

                  //password
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    onChanged: (_) => setState(() {}),
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: input_password,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: _border(_emailController.text.isNotEmpty),
                      focusedBorder: _border(true),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                  ),

                  // lupa Password
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        lupa_password,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),

                  // tombol Login
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.disabled)) {
                            return Colors.grey;
                          }
                          return Colors.red;
                        }),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      onPressed: _isFormFilled ? _doLogin : null,
                      child: Text(
                        login,
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),

                  // masuk dengan
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(login_as),
                      ),
                      Expanded(child: Divider(thickness: 1)),
                    ],
                  ),

                  // tombol google dan fb
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                          return Colors.white60;
                        }),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      onPressed: () async {
                        final user = await GoogleAuthService.signInWithGoogle();
                        if (user != null) {
                          print("Login berhasil");
                          print("Nama: ${user.displayName}");
                          print("Email: ${user.email}");
                          print("Foto: ${user.photoURL}");
                        } else {
                          print("Login dibatalkan user");
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset("assets/images/img_google.png", height: 50, width: 50,),
                          Text('Lanjut dengan Google', style: TextStyle(color: Colors.black),),
                        ])
                    ),
                  ),

                  // Row(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    // children: [
                      // IconButton(
                      //   onPressed: () {},
                      //   icon: Image.asset("assets/images/img_facebook.png"),
                      //   iconSize: 50,
                      // ),
                      // const SizedBox(width: 24),
                      // IconButton(
                      //   onPressed: () {},
                      //   icon: Image.asset("assets/images/img_google.png"),
                      //   iconSize: 50,
                      // ),
                    // ],
                  // ),

                  // regis
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(belum),
                      GestureDetector(
                        onTap: () {
                          // navigasi ke register
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => RegisPage(fromProfil: false,)),
                          );
                        },
                        child: Text(
                          daftar,
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20,),
                ],
              ),
            ),
          ),

          //bahasa
          Positioned(
            top: 16,
            right: 20,
            child: GestureDetector(
              onTap: _showLanguageDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                Image.asset("assets/flags/$_selectedLang.png",
                    width: 24, height: 24),
                const SizedBox(width: 4),
                Text(
                  _selectedLang.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
              ),
            ),
          ),
        ],
      )
    );
  }
}