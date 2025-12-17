import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  String? langCode;
  bool isLoading = true;

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
    return isLoading ? const Center(child: CircularProgressIndicator(color: Colors.red,)) : Scaffold(
      
    );
  }
}