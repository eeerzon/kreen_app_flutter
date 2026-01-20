// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';

// contoh model
class CharityItem {
  final String title;
  final String subtitle;
  // final String imageUrl;
  final String imagePath;
  final String price;

  CharityItem({
    required this.title,
    required this.subtitle,
    // required this.imageUrl,
    required this.imagePath,
    required this.price,
  });
}

class CharityPage extends StatefulWidget {
  const CharityPage({super.key});

  @override
  State<CharityPage> createState() => _CharityPageState();
}

class _CharityPageState extends State<CharityPage> {
  final prefs = FlutterSecureStorage();
  String? langCode;
  String? cari_charity;
  bool isGrid = true;

  @override
  void initState() {
    super.initState();
    _getBahasa();
  }

  Future<void> _getBahasa() async {
    final code = await prefs.read(key: 'bahasa');

    final bahasa = await LangService.getJsonData(code!, 'bahasa');

    setState(() {
      langCode = code;
      cari_charity = bahasa['cari_charity'];
    });
  }

  // simulasi data (nanti diganti dari API/database)
  final List<CharityItem> items = [
    CharityItem(
      title: "Mister Miss Tourism Charm Indonesia 2024",
      subtitle: "2 Jul - 4 Agu",
      // imageUrl: "assets/images/image_140.png", // ganti ke url image dari DB
      imagePath: "assets/images/image_140.png",
      price: "Rp 5.000",
    ),
    CharityItem(
      title: "Putra Pariwisata Nusantara favorite 2024",
      subtitle: "29 Jul - 4 Agu",
      // imageUrl: "assets/images/image_140.png",
      imagePath: "assets/images/image_140.png",
      price: "Rp 20.000",
    ),
    CharityItem(
      title: "Putra Pariwisata Nusantara favorite 2024",
      subtitle: "29 Jul - 4 Agu",
      // imageUrl: "assets/images/image_140.png",
      imagePath: "assets/images/image_140.png",
      price: "Rp 20.000",
    ),
    CharityItem(
      title: "Putra Pariwisata Nusantara favorite 2024",
      subtitle: "29 Jul - 4 Agu",
      // imageUrl: "assets/images/image_140.png",
      imagePath: "assets/images/image_140.png",
      price: "Rp 20.000",
    ),
    CharityItem(
      title: "Putra Pariwisata Nusantara favorite 2024",
      subtitle: "29 Jul - 4 Agu",
      // imageUrl: "assets/images/image_140.png",
      imagePath: "assets/images/image_140.png",
      price: "Rp 20.000",
    ),
    CharityItem(
      title: "Putra Pariwisata Nusantara favorite 2024",
      subtitle: "29 Jul - 4 Agu",
      // imageUrl: "assets/images/image_140.png",
      imagePath: "assets/images/image_140.png",
      price: "Rp 20.000",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // kalau data bahasa belum siap, tampilkan loading
    // if (cari_charity == null) {
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
        title: Text("Charity"),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      // --- Bottom Navigation Bar ---
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home
              Expanded(
                child: InkWell(
                  onTap: () {},
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.filter_alt, color: Colors.red),
                      Text("filter", style: TextStyle(fontSize: 12, color: Colors.red)),
                    ],
                  ),
                ),
              ),

              // Eksplore
              Expanded(
                child: InkWell(
                  onTap: () {},
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.card_travel_sharp, color: Colors.grey),
                      Text("harga", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 40), // space untuk tombol scan

              // Pesanan
              Expanded(
                child: InkWell(
                  onTap: () {},
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.more_time, color: Colors.grey),
                      Text("waktu", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),

              // Info
              Expanded(
                child: InkWell(
                  onTap: () {},
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.confirmation_num, color: Colors.grey),
                      Text("jenis", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: Container(
        padding: kGlobalPadding,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // search bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: cari_charity,
                        hintStyle: TextStyle(color: Colors.grey.shade400),
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
                child: isGrid ? buildGridView() : buildListView(),
              ),
              const SizedBox(height: 20,),
            ],
          ),
        )
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
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12), // biar ripple ikut radius
          child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.asset(
                    item.imagePath,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item.subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item.price,
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

  Widget buildListView() {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: SizedBox(
              width: 40,
              height: 40,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(item.imagePath, fit: BoxFit.cover),
              ),
            ),
            title: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(item.subtitle),
            trailing: Text(
              item.price,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        );
      },
    );
  }
}