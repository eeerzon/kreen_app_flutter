import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class ChangePassword extends StatefulWidget {

  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePasswordCurrent = true;
  bool _obscurePasswordNew = true;
  bool _obscurePasswordConfirm = true;

  bool get _isFormFilled =>
      _currentPasswordController.text.isNotEmpty &&
      _newPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty;

  Map<String, dynamic> errorMessage = {};
  String errorMessage500 = '';
  int errorCode = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text("Ganti Kata Sandi"),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: Colors.white,
          padding: kGlobalPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pengaturan Kata Sandi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),

              SizedBox(height: 20),
              Text(
                'Kata sandi baru tidak boleh sama dengan kata sandi sebelumnya.'
              ),

              SizedBox(height: 20),
              Text(
                'Password Lama',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 8),
              TextField(
                controller: _currentPasswordController,
                onChanged: (_) => setState(() {}),
                obscureText: _obscurePasswordCurrent,
                decoration: InputDecoration(
                  hintText: 'Masukkan kata sandi lama',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePasswordCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() => _obscurePasswordCurrent = !_obscurePasswordCurrent);
                    },
                  ),
                ),
              ),
              if (errorCode == 500) ... [
                SizedBox(height: 4,),
                Text(
                  errorMessage500,
                  style: TextStyle(color: Colors.red),
                ),
              ]
              else if (errorCode == 422) ... [
                SizedBox(height: 4,),
                Text(
                  errorMessage['current_password'][0],
                  style: TextStyle(color: Colors.red),
                ),
              ],

              SizedBox(height: 20),
              Text(
                'Password Baru',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 8),
              TextField(
                controller: _newPasswordController,
                onChanged: (_) => setState(() {}),
                obscureText: _obscurePasswordNew,
                decoration: InputDecoration(
                  hintText: 'Masukkan kata sandi baru',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePasswordNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() => _obscurePasswordNew = !_obscurePasswordNew);
                    },
                  ),
                ),
              ),

              SizedBox(height: 20),
              Text(
                'Konfirmasi Kata Sandi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                onChanged: (_) => setState(() {}),
                obscureText: _obscurePasswordConfirm,
                decoration: InputDecoration(
                  hintText: 'Konfirmasi kata sandi lama',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePasswordConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() => _obscurePasswordConfirm = !_obscurePasswordConfirm);
                    },
                  ),
                ),
              ),
              if (errorCode == 422) ... [
                SizedBox(height: 4,),
                Text(
                  errorMessage['password'][0],
                  style: TextStyle(color: Colors.red),
                ),
              ],

              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
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
                  onPressed: _isFormFilled ? _doChangePassword : null,
                  child: Text(
                    'Simpan',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _doChangePassword() async {
    String? token = await StorageService.getToken();
    
    final body = {
        "current_password": _currentPasswordController.text.trim(),
        "password": _newPasswordController.text.trim(),
        "password_confirmation": _confirmPasswordController.text.trim(),
    };
    
    final response = await ApiService.postSetProfil('$baseapiUrl/setting/update-password',token: token, body: body);

    if (!mounted) return;

    if (response != null && response['success'] == true && response['rc'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kata sandi berhasil diubah')),
      );
      Navigator.pop(context);
    } else if (response != null && response['rc'] == 500) {
      setState(() {
        errorCode = 500;
        errorMessage500 = response['message'] ?? 'Terjadi kesalahan server. Silakan coba lagi nanti.';
      });
    } else if (response != null && response['rc'] == 422) {
      setState(() {
        errorCode = 422;
        errorMessage = response['data'] ?? {};
      });
    }
  }
}