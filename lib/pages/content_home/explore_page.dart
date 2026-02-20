import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/pages/content_explore/explore_all.dart';
import 'package:kreen_app_flutter/pages/content_explore/explore_event.dart';
import 'package:kreen_app_flutter/pages/content_explore/explore_filter.dart';
import 'package:kreen_app_flutter/pages/content_explore/explore_search_bar.dart';
import 'package:kreen_app_flutter/pages/content_explore/explore_vote.dart';

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


  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
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

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 16),
            ExploreFilter(
              selectedIndex: _selectedIndex,
              onChanged: onFilterChanged,
            ),
            const SizedBox(height: 16),
            Expanded(child: buildPage()),
          ],
        ),
      ),
    );
  }
}
