// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
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

  void _doRegis() async {
    showLoadingDialog(context);

    final body = {
      "email": _emailController.text,
      "name": _namaController.text,
      "phone": _phoneController.text,
      "password": _passwordController.text,
      "password_confirmation": _confirmpasswordController.text
    };

    final result = await ApiService.post("/register", body: body);
    bool isSukses = result!['success'];

    if (!mounted) return;
    Navigator.pop(context);

    if (isSukses) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        title: 'Sukses',
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
        title: 'Gagal',
        desc: result['message'] ?? 'Registrasi gagal',
        btnOkOnPress: () {},
      ).show();
    }
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
        title: Text("Daftar Kreen"),
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
                    child: Text(
                      'Nama Lengkap'
                    ),
                  ),
                  TextField(
                    controller: _namaController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Nama Lengkap',
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
                      'Email'
                    ),
                  ),
                  TextField(
                    controller: _emailController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: _border(_emailController.text.isNotEmpty),
                      focusedBorder: _border(true),
                    ),
                  ),


                  //phone
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentGeometry.centerLeft,
                    child: Text(
                      'Nomor Handphone'
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
                      hintText: 'Masukkan Nomor Handphone',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: _border(_phoneController.text.isNotEmpty),
                      focusedBorder: _border(true),
                      errorText: _phoneController.text.isEmpty
                        ? null
                        : (!isValidPhone(_phoneController.text)
                            ? "Nomor HP harus 10-13 digit dan dimulai dengan 08"
                            : null),
                    ),
                  ),

                  //password
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentGeometry.centerLeft,
                    child: Text(
                      'Password'
                    ),
                  ),
                  TextField(
                    controller: _passwordController,
                    onChanged: (_) => setState(() {}),
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: _border(_passwordController.text.isNotEmpty),
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

                  //confirm password
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentGeometry.centerLeft,
                    child: Text(
                      'Confirm Password'
                    ),
                  ),
                  TextField(
                    controller: _confirmpasswordController,
                    onChanged: (_) => setState(() {}),
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Confirm Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: _border(_confirmpasswordController.text.isNotEmpty),
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
                        'Daftar',
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
                        child: Text('Atau'),
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
                      onPressed: () {},
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset("assets/images/img_google.png", height: 50, width: 50,),
                          Text('Masuk dengan Google', style: TextStyle(color: Colors.black),),
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
                      Text('sudah punya akun? '),
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
                          'Masuk',
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