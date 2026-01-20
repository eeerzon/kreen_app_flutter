import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/constants.dart';
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

  String _keyword = '';

  final TextEditingController _searchController = TextEditingController();

  List<String> timeFilter = ['this_week','this_month','next_month'];
  List<String> priceFilter = ['free','paid'];


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
      _keyword = value;
    });
  }

  void onFilterChanged(int index) {
    setState(() {
      _selectedIndex = index;
      _keyword = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ExploreAll(
        keyword: _keyword,
        timeFilter: timeFilter,
        priceFilter: priceFilter,
      ),
      ExploreVote(
        keyword: _keyword,
        timeFilter: timeFilter,
        priceFilter: priceFilter,
      ),
      ExploreEvent(
        keyword: _keyword,
        timeFilter: timeFilter,
        priceFilter: priceFilter,
      ),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Container(
        padding: kGlobalPadding,
        child: Column(
          children: [
            // PreferredSize(
            //   preferredSize: const Size.fromHeight(50),
            //   child: Padding(
            //     padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            //     child: LayoutBuilder(
            //       builder: (context, constraints) {
            //         final buttonWidth = (constraints.maxWidth - 4) / 2;

            //         return ToggleButtons(
            //           borderRadius: BorderRadius.circular(8),
            //           borderColor: Colors.red.shade200,
            //           selectedBorderColor: Colors.red,
            //           selectedColor: Colors.white,
            //           fillColor: Colors.red,
            //           color: Colors.grey,
            //           renderBorder: true,
            //           isSelected: [_selectedIndex == 0, _selectedIndex == 1],
            //           onPressed: (index) {
            //             setState(() {
            //               _selectedIndex = index;
            //             });
            //           },
            //           constraints: BoxConstraints(
            //             minHeight: 40,
            //             minWidth: buttonWidth,
            //           ),
            //           children: const [
            //             Row(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Icon(Icons.how_to_vote_rounded),
            //                 SizedBox(width: 6),
            //                 Text("Vote"),
            //               ],
            //             ),
            //             Row(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Icon(Icons.confirmation_number_rounded),
            //                 SizedBox(width: 6),
            //                 Text("Event"),
            //               ],
            //             ),
            //           ],
            //         );
            //       },
            //     ),
            //   ),
            // ),
            
            ExploreSearchBar(
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
            ),
            const SizedBox(height: 16),
            ExploreFilter(
              selectedIndex: _selectedIndex,
              onChanged: onFilterChanged,
            ),
            const SizedBox(height: 16),
            Expanded(child: pages[_selectedIndex]),
          ],
        ),
      ),
    );
  }
}
