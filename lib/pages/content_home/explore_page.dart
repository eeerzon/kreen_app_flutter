import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/pages/content_explore/explore_all.dart';
import 'package:kreen_app_flutter/pages/content_explore/explore_event.dart';
import 'package:kreen_app_flutter/pages/content_explore/explore_filter.dart';
import 'package:kreen_app_flutter/pages/content_explore/explore_search_bar.dart';
import 'package:kreen_app_flutter/pages/content_explore/explore_vote.dart';
import 'package:kreen_app_flutter/pages/content_explore_new/explore_filter_new.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class ExplorePage extends StatefulWidget {
  final int initialTab; // 0 = all, 1 = vote, 2 = event
  const ExplorePage({super.key, this.initialTab = 0,});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  bool isGrid = true;

  int _selectedIndex = 0;

  String? _keyword = '';

  final TextEditingController _searchController = TextEditingController();

  List<String> timeFilter = [];
  List<String> priceFilter = [];
  int pageFilter = 1;

  String? langCode;
  Map<String, dynamic>? bahasa;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void onSearch(String value) {
    setState(() {
      _keyword = (value.isEmpty ? "" : value);
    });
  }

  void _resetSearch() {
    _searchController.clear();

    setState(() {
      _keyword = "";
      timeFilter = [];
      priceFilter = [];
    });
  }


  void onFilterChanged(int index) {
    setState(() {
      _selectedIndex = index;
      _keyword = null;
      _searchController.clear();
      timeFilter = [];
      priceFilter = [];
    });
  }

  Future<void> _getBahasa() async {
    final templangCode = await StorageService.getLanguage();

    // pastikan di-set dulu
    setState(() {
      langCode = templangCode;
    });

    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");

    setState(() {
      bahasa = tempbahasa;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (bahasa == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.red,),
        ),
      );
    }
    Widget buildPage() {
      switch (_selectedIndex) {
        case 0:
          return ExploreAll(
            keyword: _keyword,
            timeFilter: timeFilter,
            priceFilter: priceFilter,
            pageFilter: pageFilter,
            onResetSearch: _resetSearch,
          );
        case 1:
          return ExploreVote(
            keyword: _keyword,
            timeFilter: timeFilter,
            priceFilter: priceFilter,
            pageFilter: pageFilter,
            onResetSearch: _resetSearch,
          );
        case 2:
          return ExploreEvent(
            keyword: _keyword,
            timeFilter: timeFilter,
            priceFilter: priceFilter,
            pageFilter: pageFilter,
            onResetSearch: _resetSearch,
          );
        default:
          return const SizedBox();
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Container(
        padding: kGlobalPadding,
        child: Column(
          children: [
            
            ExploreSearchBar(
              key: ValueKey(_selectedIndex),
              controller: _searchController, 
              onChanged: onSearch,
              initialTime: timeFilter,
              initialPrice: priceFilter,
              onFilterApply: (time, price) {
                setState(() {
                  timeFilter = time;
                  priceFilter = price;
                });
              },
              selectedIndex: _selectedIndex,
            ),

            // ExploreSearchBarNew(
            //   key: ValueKey(_selectedIndex),
            //   controller: _searchController, 
            //   onChanged: onSearch,
            //   initialTime: timeFilter,
            //   initialPrice: priceFilter,
            //   onFilterApply: (time, price, type) {
            //     setState(() {
            //       timeFilter = time;
            //       priceFilter = price;
            //       _selectedIndex = type;
            //     });
            //   },
            //   selectedIndex: _selectedIndex,
            //   onTypeChange: (type) {
            //     setState(() {
            //       _selectedIndex = type;
            //     });
            //   },
            // ),

            const SizedBox(height: 16),
            ExploreFilter(
              selectedIndex: _selectedIndex,
              onChanged: onFilterChanged,
            ),

            const SizedBox(height: 16),
            ExploreFilterNew(
              bahasa: bahasa!,
              selectedIndex: _selectedIndex,
              timeFilter: timeFilter,
              priceFilter: priceFilter,
              onReset: _resetSearch,
            ),

            const SizedBox(height: 16),
            Expanded(child: buildPage()),
          ],
        ),
      ),
    );
  }
}
