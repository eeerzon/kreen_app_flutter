// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';


class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final prefs = FlutterSecureStorage();
  String? langCode;
  String? cari_event;
  bool isGrid = true;

  @override
  void initState() {
    super.initState();
    _getBahasa();

    _loadEvents();
  }

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();

    final bahasa = await LangService.getJsonData(code!, 'bahasa');

    setState(() {
      langCode = code;
      cari_event = bahasa['cari_event'];
    });
  }

  List<dynamic> events = [];
  Future<void> _loadEvents() async {
    final result = await ApiService.post(
      "/event/list",
      body: {"id_merchant": "ITWXLBFDRCKNTTWTK448"},
      xLanguage: langCode
    );

    if (result != null && mounted) {
      setState(() {
        events = result['data'] ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // kalau data bahasa belum siap, tampilkan loading
    // if (cari_event == null) {
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
        title: Text("Event"),
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
                      hintText: cari_event,
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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
              child: isGrid ? buildGridView() : buildListView(),
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
      itemCount: events.length,
      itemBuilder: (context, index) {
        final item = events[index];
        return InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8), // biar ripple ikut radius
          child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    item['img_organizer'] ?? "",
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/img_broken.jpg',
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item['created_at'] ?? '',
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
                // Padding(
                //   padding: const EdgeInsets.all(8.0),
                //   child: Text(
                //     item.price,
                //     style: const TextStyle(
                //       color: Colors.red,
                //       fontWeight: FontWeight.bold,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildListView() {
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final item = events[index];
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: SizedBox(
              width: 40,
              height: 40,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['img_organizer'] ?? "",
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/img_broken.jpg',
                    );
                  },
                )

              ),
            ),
            title: Text(
              item['title'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(item['created_at'] ?? ''),
            // trailing: Text(
            //   item.price,
            //   style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
            // ),
          ),
        );
      },
    );
  }
}