
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:kreen_app_flutter/helper/global_function.dart';
import 'package:url_launcher/url_launcher.dart';

class FaqModal {
  static Future<void> show(BuildContext context, String faq, Map<String, dynamic> bahasa) async {
    var jsonFaq = jsonDecode(faq);
    final List rawData = jsonFaq['data'] ?? [];

    final List<Map<String, String>> faqData = rawData.isNotEmpty
      ? List<Map<String, String>>.from(
          rawData.map((e) => {
                'pertanyaan': e['pertanyaan'].toString(),
                'jawaban': e['jawaban'].toString(),
              }),
        )
      : List.generate(6, (i) {
          final idx = i + 1;
          return {
            'pertanyaan': bahasa['faq_default_q$idx'].toString(),
            'jawaban': bahasa['faq_default_a$idx'].toString(),
          };
        });

    await showModalBottomSheet<void>(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: kGlobalPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Frequently Asked Questions Vote',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, color: Colors.black),
                        ),
                      ],
                    ),
                    const Divider(),

                    const SizedBox(height: 8),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: faqData.length,
                      itemBuilder: (context, index) {
                        final item = faqData[index];
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${index + 1}.',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Html(
                                        data: item['pertanyaan'],
                                        style: {
                                          "p": Style(
                                            fontWeight: FontWeight.bold,
                                            margin: Margins.zero,
                                          ),
                                          "body": Style(
                                            fontWeight: FontWeight.bold,
                                            margin: Margins.zero,
                                          ),
                                        },
                                      ),
                                      Html(
                                        data: item['jawaban'],
                                        onLinkTap: (url, _, __) async {
                                          if (url == null) return;
                                          await launchUrl(
                                            Uri.parse(url),
                                            mode: LaunchMode.externalApplication,
                                          );
                                        },
                                        style: {
                                          "p": Style(textAlign: TextAlign.justify),
                                          "body": Style(textAlign: TextAlign.justify),
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }
}