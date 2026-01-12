// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class ExploreSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const ExploreSearchBar({super.key, required this.controller, required this.onChanged});

  @override
  _ExploreSearchBarState createState() => _ExploreSearchBarState();
}

class _ExploreSearchBarState extends State<ExploreSearchBar> {  
  String? langCode, search;
  bool isLoading = true;

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();
    setState(() {
      langCode = code;
    });
    
    final tempsearch = await LangService.getText(langCode!, "search");

    setState(() {
      search = tempsearch;
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
    return isLoading 
      ? const CircularProgressIndicator(color: Colors.red,) 
      : Row(
          children: [
            Expanded(
              child: Container(
                color: Colors.white,
                height: 48,
                child: TextField(
                  onChanged: widget.onChanged,
                  controller: widget.controller,
                  decoration: InputDecoration(
                    hintText: search,
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade400,),
                    ),
                  ),
                ),
              ),
            ),
            
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.filter_alt_outlined, size: 30,),
            ),
          ],
        );
  }
}
