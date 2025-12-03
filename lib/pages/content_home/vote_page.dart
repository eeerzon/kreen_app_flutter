// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';


class VotePage extends StatefulWidget {
  const VotePage({super.key});

  @override
  State<VotePage> createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  final prefs = FlutterSecureStorage();
  String? langCode;
  String? cari_vote;
  bool isGrid = true;

  @override
  void initState() {
    super.initState();
    _getBahasa();

    _loadVotes();
  }

  Future<void> _getBahasa() async {
    final code = await prefs.read(key: 'bahasa');

    final text = await LangService.getText(code!, 'cari_vote');

    setState(() {
      langCode = code;
      cari_vote = text;
    });
  }

  List<dynamic> votes = [];
  Future<void> _loadVotes() async {
    final result = await ApiService.get(
      "/vote/latest",
    );

    if (result != null && mounted) {
      setState(() {
        votes = result['data'] ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // kalau data bahasa belum siap, tampilkan loading
    // if (cari_vote == null) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     showLoadingDialog(context);
    //   });

    //   return const Scaffold(); // kosongin dulu
    // } else {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     hideLoadingDialog(context);
    //   });
    // }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text("Vote"),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: Container(
        padding: kGlobalPadding,
        child: Column(
          children: [
            // search bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: cari_vote,
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      
                    },
                  ),
                ),

                IconButton(
                  iconSize: 45,
                  icon: Icon(isGrid ? Icons.grid_view_rounded : Icons.list_rounded),
                  color: Colors.red,
                  onPressed: () {
                    setState(() {
                      isGrid = !isGrid;
                      _getBahasa();
                    });
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 12,),
            // isi data
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: buildGridView(),
            ),
          ],
        ),
      ),
    );
  }



  Widget buildGridView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.65,
      ),
      itemCount: votes.length,
      itemBuilder: (context, index) {
        final item = votes[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailVotePage(id_event: item['id_event']), // lempar data item kalau perlu
              ),
            );
          },
          borderRadius: BorderRadius.circular(12), // biar ripple ikut radius
          child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    item['img'],
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item['date_event'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    item['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Rp. ${item['price']}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
