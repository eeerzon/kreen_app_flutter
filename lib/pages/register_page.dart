// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:kreen_app_flutter/widgets/google_login.dart';
import 'package:kreen_app_flutter/widgets/loading_page.dart';

class RegisPage extends StatefulWidget {
  final bool fromProfil;
  const RegisPage({super.key, required this.fromProfil});

  @override
  State<RegisPage> createState() => _RegisPageState();
}

class _RegisPageState extends State<RegisPage> {
  final prefs = FlutterSecureStorage();

  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmpasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmpasswordFocus = FocusNode();

  bool get _isFormFilled =>
      _namaController.text.isNotEmpty &&
      _emailController.text.isNotEmpty &&
      _phoneController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _confirmpasswordController.text.isNotEmpty;

  bool isValidPhone(String phone) {
    final regex = RegExp(r'^08[0-9]{8,11}$');
    return regex.hasMatch(phone);
  }
  
  OutlineInputBorder _border(bool isFilled) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isFilled ? Colors.orange : Colors.grey.shade400,
        width: 1.5,
      ),
    );
  }

  int errorCode = 0;
  Map<String, dynamic> errorMessage = {};
  void _doRegis() async {
    showLoadingDialog(context);

    final body = {
      "email": _emailController.text,
      "name": _namaController.text,
      "phone": _phoneController.text,
      "password": _passwordController.text,
      "password_confirmation": _confirmpasswordController.text
    };

    bool isSukses = false;
    
    final result = await ApiService.post("/register", body: body);
    if (result!= null && result['success'] == true && result['rc'] == 200) {
      isSukses = true;
    } else if (result!['rc'] == 422) {
      isSukses = false;
      setState(() {
        errorMessage = result['data'];
        errorCode = 422;
      });
    } 

    if (!mounted) return;
    Navigator.pop(context);

    if (isSukses) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        title: langCode == 'id' ? 'Berhasil' : 'Succes',
        desc: result['message'],
        transitionAnimationDuration: const Duration(milliseconds: 400),
        autoHide: const Duration(seconds: 1),
      ).show().then((_) {
        Navigator.pop(context);
      });
    } else {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: langCode == 'id' ? 'Gagal' : 'Failed',
        desc: result['message'],
        btnOkOnPress: () {},
        btnOkColor: Colors.red,
      ).show();
    }
  }


  void _loginGoogle() async {
    final user = await GoogleAuthService.signInWithGoogle();
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (user != null) {

      final result = await ApiService.post('/google/callback', body: {
        "name": user.displayName,
        "email": user.email,
        "photo": user.photoURL,
        "google_id_token": idToken,
      });

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
        Fluttertoast.showToast(
          msg: cancelLogin!,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: cancelLogin!,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  String? langCode;
  String? fullNameLabel, fullName;
  String? emailLabel, email;
  String? phoneLabel, phone, phoneError;
  String? passwordLabel, password;
  String? confirmPasswordLabel, confirmPassword;
  String? daftarText, sudahPunyaAkunText;
  String? googleLogin;
  String? loginAs, login;
  String? cancelLogin;
  bool isLoading = true;

  Future<void> _getBahasa() async {
    final templangCode = await StorageService.getLanguage();

    // pastikan di-set dulu
    setState(() {
      langCode = templangCode;
    });

    final tempgoogleLogin = await LangService.getText(langCode!, "google_login");

    final tempfullNameLabel = await LangService.getText(langCode!, "nama_lengkap_label");
    final tempfullName = await LangService.getText(langCode!, "nama_lengkap");
    final tempemailLabel = await LangService.getText(langCode!, "email_label");
    final tempemail = await LangService.getText(langCode!, "input_email");
    final tempphoneLabel = await LangService.getText(langCode!, "nomor_hp_label");
    final tempphone = await LangService.getText(langCode!, "nomor_hp");
    final tempphoneError = await LangService.getText(langCode!, "nomor_hp_error");
    final temppasswordLabel = await LangService.getText(langCode!, "password_label");
    final temppassword = await LangService.getText(langCode!, "input_password");
    final tempconfirmPasswordLabel = await LangService.getText(langCode!, "konfirmasi_password_label");
    final tempconfirmPassword = await LangService.getText(langCode!, "konfirmasi_password");
    final tempdaftarText = await LangService.getText(langCode!, "daftar");
    final tempsudahPunyaAkunText = await LangService.getText(langCode!, "sudah_punya_akun");

    final templogin = await LangService.getText(langCode!, "login");
    final temploginAs = await LangService.getText(langCode!, "login_as");
    final tempcancelLogin = await LangService.getText(langCode!, "cancel_login");

    setState(() {
      googleLogin = tempgoogleLogin;

      fullNameLabel = tempfullNameLabel;
      fullName = tempfullName;
      emailLabel = tempemailLabel;
      email = tempemail;
      phoneLabel = tempphoneLabel;
      phone = tempphone;
      phoneError = tempphoneError;
      passwordLabel = temppasswordLabel;
      password = temppassword;
      confirmPasswordLabel = tempconfirmPasswordLabel;
      confirmPassword = tempconfirmPassword;
      daftarText = tempdaftarText;
      sudahPunyaAkunText = tempsudahPunyaAkunText;

      login = templogin;
      loginAs = temploginAs;
      cancelLogin = tempcancelLogin;

      isLoading = false;
    });
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
        ? Center(child: CircularProgressIndicator(color: Colors.red,))
        : buildKonten()
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
        title: Text(daftarText ?? "..."),
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
                  //nama lengkap

                  Align(
                    alignment: AlignmentGeometry.centerLeft,
                    child: Text(fullNameLabel ?? "..."),
                  ),
                  TextField(
                    controller: _namaController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: fullName!,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: _border(_namaController.text.isNotEmpty),
                      focusedBorder: _border(true),
                    ),
                  ),


                  //email 
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentGeometry.centerLeft,
                    child: Text(
                      emailLabel!
                    ),
                  ),
                  TextField(
                    controller: _emailController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: email!,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: _border(_emailController.text.isNotEmpty),
                      focusedBorder: _border(true),
                    ),
                  ),
                  if (errorCode == 422) ... [
                    SizedBox(height: 4),
                    Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: Text(
                        errorMessage['email'][0],
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    )
                  ],

                  //phone
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentGeometry.centerLeft,
                    child: Text(
                      phoneLabel!
                    ),
                  ),
                  TextField(
                    controller: _phoneController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: phone!,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: _border(_phoneController.text.isNotEmpty),
                      focusedBorder: _border(true),
                    ),
                  ),
                  if (_phoneController.text.isNotEmpty &&
                      !isValidPhone(_phoneController.text))
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        phoneError ?? '',
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),

                  //password
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentGeometry.centerLeft,
                    child: Text(
                      passwordLabel!
                    ),
                  ),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    onChanged: (_) => setState(() {}),
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: password!,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: _border(_passwordController.text.isNotEmpty),
                      focusedBorder: _border(true),
                      suffixIcon: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                          _passwordFocus.canRequestFocus = false;
                        },
                        child: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                  ),

                  //confirm password
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentGeometry.centerLeft,
                    child: Text(
                      confirmPasswordLabel!
                    ),
                  ),
                  TextField(
                    controller: _confirmpasswordController,
                    focusNode: _confirmpasswordFocus,
                    onChanged: (_) => setState(() {}),
                    obscureText: _obscurePasswordConfirm,
                    decoration: InputDecoration(
                      hintText: confirmPassword!,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: _border(_confirmpasswordController.text.isNotEmpty),
                      focusedBorder: _border(true),
                      suffixIcon: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() => _obscurePasswordConfirm = !_obscurePasswordConfirm);
                          _confirmpasswordFocus.canRequestFocus = false;
                        },
                        child: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  if (errorCode == 422) ... [
                    SizedBox(height: 4),
                    Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var err in errorMessage['password'])
                            Text(
                              err,
                              style: const TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                    )
                  ],

                  // tombol Login
                  const SizedBox(height: 30),
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
                      onPressed: _isFormFilled ? _doRegis : null,
                      child: Text(
                        daftarText!,
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),

                  // masuk dengan
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(loginAs!),
                      ),
                      Expanded(child: Divider(thickness: 1)),
                    ],
                  ),

                  // tombol google dan fb
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
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
                      onPressed: () {
                        _loginGoogle();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset("assets/images/img_google.png", height: 50, width: 50,),
                          Text(googleLogin!, style: TextStyle(color: Colors.black),),
                        ])
                    ),
                  ),

                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                      // IconButton(
                      //   onPressed: () {},
                      //   icon: Image.asset("assets/images/img_facebook.png"),
                      //   iconSize: 50,
                      // ),
                      // const SizedBox(width: 24),
                  //     IconButton(
                  //       onPressed: () {},
                  //       icon: Image.asset("assets/images/img_google.png"),
                  //       iconSize: 50,
                  //     ),
                  //   ],
                  // ),

                  // regis
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(sudahPunyaAkunText!),
                      GestureDetector(
                        onTap: () {
                          if (widget.fromProfil) {
                            Navigator.pushReplacement(
                              context, 
                              MaterialPageRoute(builder: (context) => LoginPage()),
                            );
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          login!,
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),
                ],
              ),
              ),
          )
        ],
      ),
    );
  }
}