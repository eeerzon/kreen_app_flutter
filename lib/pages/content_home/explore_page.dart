import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/pages/content_explore/explore_event.dart';
import 'package:kreen_app_flutter/pages/content_explore/explore_vote.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  bool isGrid = true;

  int _selectedIndex = 0;

  final List<Widget> _pages = [
    ExploreVote(),
    ExploreEvent(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Container(
        padding: kGlobalPadding,
        child: Column(
          children: [
            PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final buttonWidth = (constraints.maxWidth - 4) / 2;

                    return ToggleButtons(
                      borderRadius: BorderRadius.circular(8),
                      borderColor: Colors.red.shade200,
                      selectedBorderColor: Colors.red,
                      selectedColor: Colors.white,
                      fillColor: Colors.red,
                      color: Colors.grey,
                      renderBorder: true,
                      isSelected: [_selectedIndex == 0, _selectedIndex == 1],
                      onPressed: (index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      constraints: BoxConstraints(
                        minHeight: 40,
                        minWidth: buttonWidth,
                      ),
                      children: const [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.how_to_vote_rounded),
                            SizedBox(width: 6),
                            Text("Vote"),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.confirmation_number_rounded),
                            SizedBox(width: 6),
                            Text("Event"),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 12,),
            Expanded(
              child: _pages[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}
