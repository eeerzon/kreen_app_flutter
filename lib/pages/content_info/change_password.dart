import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
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

  final FocusNode _currentPasswordFocus = FocusNode();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  bool get _isFormFilled =>
      _currentPasswordController.text.isNotEmpty &&
      _newPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty;

  Map<String, dynamic> errorMessage = {};
  String errorMessage500 = '';
  int errorCode = 0;

  bool isLoading = true;

  String? langCode;
  Map<String, dynamic> infoLang = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
    });
  }

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();
    setState(() => langCode = code);

    final tempinfolang = await LangService.getJsonData(langCode!, 'info');
    setState(() {
      infoLang = tempinfolang;

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading ? Center(child: CircularProgressIndicator(color: Colors.red,)) : Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(infoLang['change_password'] ?? ""),
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
                infoLang['pengaturan_password'], //'Pengaturan Kata Sandi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),

              SizedBox(height: 20),
              Text(
                infoLang['pengaturan_password_desc'], //'Kata sandi baru tidak boleh sama dengan kata sandi sebelumnya.'
              ),

              SizedBox(height: 20),
              Text(
                infoLang['old_password_label'], //'Password Lama',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 8),
              TextField(
                controller: _currentPasswordController,
                focusNode: _currentPasswordFocus,
                onChanged: (_) => setState(() {}),
                obscureText: _obscurePasswordCurrent,
                decoration: InputDecoration(
                  hintText: infoLang['old_password_hint'], //'Masukkan kata sandi lama',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey, width: 2),
                  ),
                  suffixIcon: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() => _obscurePasswordCurrent = !_obscurePasswordCurrent);
                      _currentPasswordFocus.canRequestFocus = false;
                    },
                    child: Icon(
                      _obscurePasswordCurrent ? Icons.visibility_off : Icons.visibility,
                    ),
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
                const SizedBox(height: 4),
                if (errorMessage['current_password'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var err in errorMessage['current_password'])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            err,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  )
              ],

              SizedBox(height: 20),
              Text(
                infoLang['new_password_label'], //'Password Baru',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 8),
              TextField(
                controller: _newPasswordController,
                focusNode: _newPasswordFocus,
                onChanged: (_) => setState(() {}),
                obscureText: _obscurePasswordNew,
                decoration: InputDecoration(
                  hintText: infoLang['new_password_hint'], //'Masukkan kata sandi baru',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey, width: 2),
                  ),
                  suffixIcon: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() => _obscurePasswordNew = !_obscurePasswordNew);
                      _newPasswordFocus.canRequestFocus = false;
                    },
                    child: Icon(
                      _obscurePasswordNew ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),
              Text(
                infoLang['konfirmasi_password_label'], //']'Konfirmasi Kata Sandi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocus,
                onChanged: (_) => setState(() {}),
                obscureText: _obscurePasswordConfirm,
                decoration: InputDecoration(
                  hintText: infoLang['konfirmasi_password_hint'], //']'Konfirmasi kata sandi lama',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey, width: 2),
                  ),
                  suffixIcon: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() => _obscurePasswordConfirm = !_obscurePasswordConfirm);
                      _confirmPasswordFocus.canRequestFocus = false;
                    },
                    child: Icon(
                      _obscurePasswordConfirm ? Icons.visibility_off : Icons.visibility,
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
                    infoLang['simpan'], //']'Simpan',
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
        SnackBar(content: Text(infoLang['sukses_info'])), //'Kata sandi berhasil diubah'
      );
      Navigator.pop(context);
    } else if (response != null && response['rc'] == 500) {
      setState(() {
        errorCode = 500;
        errorMessage500 = response['message'] ?? infoLang['gagal_info']; //'Terjadi kesalahan server. Silakan coba lagi nanti.';
      });
    } else if (response != null && response['rc'] == 422) {
      setState(() {
        errorCode = 422;
        errorMessage = response['data'] ?? {};
      });
    }
  }
}