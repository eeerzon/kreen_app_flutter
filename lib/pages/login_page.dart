// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kreen_app_flutter/pages/lupa_password.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/helper/session_manager.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:kreen_app_flutter/helper/google_login.dart';
import 'package:kreen_app_flutter/helper/loading_page.dart';
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

  String dialog_language = "";
  String input_email = "";
  String input_password = "";
  String lupa_password = "";
  String login = "";
  String login_as = "";
  String belum = "";
  String daftar = "";
  String? langCode, googleLogin, gagalLogin, cancelLogin;
  bool isLoading = true;
  bool _isGoogleLoading = false;

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

  void _doLogin() async {
    showLoadingDialog(context, bahasa!['loading']); // tampilkan loading
    
    final body = {
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
    };

    final result = await ApiService.post("/login", body: body, xLanguage: langCode);

    if (!mounted) return;

    hideLoadingDialog(context);

    if (result != null && result['success'] == true && result['rc'] == 200) {
      final user = result['data']['user'];
      final token = result['data']['token'];

      // simpan ke secure storage
      await StorageService.setToken(token);
      await StorageService.setLoginMethod('password');
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

      SessionManager.isGuest = true;
      SessionManager.checkingUserModalShown = true;

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
        dialogType: DialogType.noHeader,
        animType: AnimType.topSlide,
        title: bahasa!['maaf'],
        desc: bahasa!['error'], //"Terjadi kesalahan. Silakan coba lagi.",
        btnOkOnPress: () {},
        btnOkColor: Colors.red,
        buttonsTextStyle: TextStyle(color: Colors.white),
        headerAnimationLoop: false,
        dismissOnTouchOutside: true,
        showCloseIcon: true,
      ).show();
    }
  }

  void _loginGoogle() async {
    if (_isGoogleLoading) return;

    setState(() => _isGoogleLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final user = await GoogleAuthService.signInWithGoogle();
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();

      if (user != null) {
        final result = await ApiService.post(
          '/google/callback',
          body: {
            "name": user.displayName,
            "email": user.email,
            "photo": user.photoURL,
            "google_id_token": idToken,
          },
          xLanguage: langCode,
        );

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

          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else {
          Fluttertoast.showToast(msg: cancelLogin!);
        }
      } else {
        Fluttertoast.showToast(msg: cancelLogin!);
      }
    } catch (e) {
      debugPrint('Google login error: $e');
      Fluttertoast.showToast(msg: cancelLogin!);
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  //setting bahasa
  Map<String, dynamic>? bahasa;
  Future<void> _getBahasa() async {
    final templangCode = await StorageService.getLanguage();

    // pastikan di-set dulu
    setState(() {
      langCode = templangCode;
    });
    
    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");

    setState(() {
      bahasa = tempbahasa;

      dialog_language = tempbahasa['pick_language'];
      input_email = tempbahasa['input_email'];
      input_password = tempbahasa['input_password'];
      lupa_password = tempbahasa['lupa_password'];
      login = tempbahasa['login'];
      login_as = tempbahasa['login_as'];
      belum = tempbahasa['belum'];
      daftar = tempbahasa['daftar'];
      googleLogin = tempbahasa['google_login'];
      gagalLogin = tempbahasa['gagal_login'];
      cancelLogin = tempbahasa['cancel_login'];

      isLoading = false;
    });
  }

  final Map<String, String> languages = {
    "id": "Indonesia",
    "en": "English"
  };

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempLang = langCode!;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dialog_language),
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
                      onChanged: (val) async {
                        if (val != null) {
                          setState(() {
                            langCode = val; // update global
                          });
                          await StorageService.setLanguage(val);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const HomePage()),
                          );
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: Colors.red,),) 
        : buildKonten(),
    );
  }

  Widget buildKonten() {
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: _showLanguageDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset("assets/flags/${langCode ?? 'id'}.png",
                      width: 24, height: 24),
                  const SizedBox(width: 4),
                  Text(
                    (langCode ?? 'id').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        ],
      ),

      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Stack(
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
                        hintStyle: TextStyle(color: Colors.grey.shade400),
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
                        hintStyle: TextStyle(color: Colors.grey.shade400),
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LupaPasswordPage(),
                            ),
                          );
                        },
                        child: Text(
                          "$lupa_password ?",
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
                    InkWell(
                      onTap: _isGoogleLoading ? null : _loginGoogle,
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: _isGoogleLoading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.red,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/images/img_google.png",
                                  height: 24,
                                  width: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  googleLogin ?? '',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
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
          ],
        ),
      ),
    );
  }
}