// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/modal/modal_filter.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class ExploreSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  final List<String> initialTime;
  final List<String> initialPrice;
  final Function(List<String>, List<String>) onFilterApply;
  final int selectedIndex;

  const ExploreSearchBar({
    super.key, 
    required this.controller, 
    required this.onChanged,
    required this.initialTime,
    required this.initialPrice,
    required this.onFilterApply,
    required this.selectedIndex,
  });

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
    
    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");

    setState(() {
      search = tempbahasa['search'];
      isLoading = false;
    });
  }

  late List<String> paramTime;
  late List<String> paramPrice;
  late int paramPage = 1;
  
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
    });

    paramTime = List.from(widget.initialTime);
    paramPrice = List.from(widget.initialPrice);
  }

  @override
  void didUpdateWidget(covariant ExploreSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialTime != widget.initialTime ||
        oldWidget.initialPrice != widget.initialPrice) {
      setState(() {
        paramTime = widget.initialTime;
        paramPrice = widget.initialPrice;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return isLoading 
      ? const CircularProgressIndicator(color: Colors.red,) 
      : Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextField(
                  onChanged: widget.onChanged,
                  controller: widget.controller,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: search,
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400,),
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(width: 4,),
            IconButton(
              onPressed: () async {
                final result = await ModalFilter.show(
                  context,
                  langCode!,
                  paramTime,
                  paramPrice,
                  paramPage,
                  selectedIndex: widget.selectedIndex,
                );

                if (result != null) {
                  setState(() {
                    paramTime = result['time']!;
                    paramPrice = result['price']!;
                    paramPage = 1;
                  });
                  widget.onFilterApply(paramTime, paramPrice);
                }
              },
              icon: const Icon(Icons.filter_alt_outlined, size: 34,),
            ),
          ],
        );
  }
}
