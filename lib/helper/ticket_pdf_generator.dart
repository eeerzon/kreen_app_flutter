// ignore_for_file: non_constant_identifier_names, unnecessary_import, curly_braces_in_flow_control_structures

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

class TicketPdfGenerator {
  static pw.Font? _cachedFont;
  static pw.Font? _cachedFontBold;

  static Future<Uint8List> generate({
    required Map<String, dynamic> event,
    required Map<String, dynamic> eventOder,
    required Map<String, dynamic> detailEvent,
    required Map<String, dynamic> dataEvents,
    required List<dynamic> eventOrderDetail,
    required List<dynamic> eventTiket,
    required String? langCode,
    required Map<String, dynamic> bahasa,
  }) async {
    final pdf = pw.Document();

    _cachedFont ??= await PdfGoogleFonts.robotoRegular();
    _cachedFontBold ??= await PdfGoogleFonts.robotoBold();

    final ttf = _cachedFont!;
    final ttfBold = _cachedFontBold!;

    // Load event banner
    Uint8List? bannerBytes;
    try {
      final response = await http.get(
        Uri.parse(event['event_banner']),
        headers: {'Accept': 'image/jpeg'},
      );
      if (response.statusCode == 200) {
        final codec = await ui.instantiateImageCodec(
          response.bodyBytes,
          targetWidth: 200,
          targetHeight: 200,
        );
        final frame = await codec.getNextFrame();
        final byteData = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        bannerBytes = byteData?.buffer.asUint8List();
      }
    } catch (_) {}
    
    final formatter = NumberFormat.decimalPattern("en_US");

    String formatDate(String dateStr) {
      if (dateStr.isEmpty) return '-';
      try {
        final date = DateTime.parse(dateStr);
        if (langCode == 'id') {
          return DateFormat("EEEE, dd MMMM yyyy", "id_ID").format(date);
        } else {
          final f = DateFormat("EEEE, MMMM d yyyy", "en_US");
          final day = date.day;
          String suffix = 'th';
          if (day % 10 == 1 && day != 11) suffix = 'st';
          else if (day % 10 == 2 && day != 12) suffix = 'nd';
          else if (day % 10 == 3 && day != 13) suffix = 'rd';
          return f.format(date).replaceFirst('$day', '$day$suffix');
        }
      } catch (_) {
        return '-';
      }
    }

    String formatTime(String time) {
      try {
        final t = DateFormat("HH:mm:ss").parse(time);
        return DateFormat("HH:mm").format(t);
      } catch (_) {
        return time;
      }
    }
    
    Future<Uint8List?> fetchQr(String data) async {
      try {
        final uri = Uri.parse(
            'https://api.qrserver.com/v1/create-qr-code/?size=100x100&data=$data');
        final res = await http.get(uri);
        if (res.statusCode == 200) return res.bodyBytes;
      } catch (_) {}
      return null;
    }
    
    final qrImages = await Future.wait(
      eventOrderDetail.map((order) => fetchQr(order['id_order_detail'])),
    );
    
    final endRaw = dataEvents['event_datetime'][0]['datetime_end_plus_diff'];
    final endDate = DateTime.parse(endRaw);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        build: (context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.red50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (bannerBytes != null)
                    pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(
                        pw.MemoryImage(bannerBytes),
                        width: 80,
                        height: 80,
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          event['event_title'] ?? '-',
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 14,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          "${bahasa['penyelenggara'] ?? 'Penyelenggara'}: ${detailEvent['organizer'] ?? '-'}",
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        // Jadwal
                        ...List.generate(dataEvents['event_datetime'].length, (i) {
                          final item = dataEvents['event_datetime'][i];
                          return pw.Text(
                            "${formatDate(item['date_event'])}  ${formatTime(item['time_start'])} - ${formatTime(item['time_end'])} (${detailEvent['code_timezone']})",
                            style: pw.TextStyle(font: ttf, fontSize: 10),
                          );
                        }),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          "${bahasa['lokasi'] ?? 'Lokasi'}: ${detailEvent['type_event'] == 'offline' ? detailEvent['location_map'] ?? '-' : '${detailEvent['type_event']} via ${detailEvent['venue_platform']}'}",
                          style: pw.TextStyle(font: ttf, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  bahasa['total_pembayaran'] ?? 'Total Pembayaran',
                  style: pw.TextStyle(font: ttfBold, fontSize: 12),
                ),
                pw.Text(
                  eventOder['amount'] == 0
                    ? bahasa['harga_detail'] ?? 'Gratis'
                    : "${eventOder['currency_event']} ${formatter.format(eventOder['amount'] + eventOder['fees'])}",
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 12,
                    color: PdfColors.red,
                  ),
                ),
              ],
            ),

            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),

            // Tiket-tiket
            ...List.generate(eventOrderDetail.length, (index) {
              final order = eventOrderDetail[index];
              final ticket = eventTiket.firstWhere(
                (e) => e['id_event_ticket'] == order['id_event_ticket'],
                orElse: () => null,
              );
              final ticketName = ticket != null ? ticket['name_ticket'] : '-';
              final qrBytes = qrImages[index];

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Info tiket (kiri)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "${bahasa['tiket'] ?? 'Tiket'} ${index + 1} $ticketName",
                            style: pw.TextStyle(font: ttfBold, fontSize: 11),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(order['ticket_buyer_name'] ?? '-',
                              style: pw.TextStyle(font: ttf, fontSize: 10)),
                          pw.Text(order['ticket_buyer_email'] ?? '-',
                              style: pw.TextStyle(font: ttf, fontSize: 10)),
                          pw.Text(order['ticket_buyer_phone'] ?? '-',
                              style: pw.TextStyle(font: ttf, fontSize: 10)),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            "${bahasa['expired_at'] ?? 'Berlaku hingga'} ${formatDate(endDate.toIso8601String())}",
                            style: pw.TextStyle(font: ttf, fontSize: 10),
                          ),
                          pw.Text(
                            "${DateFormat('HH:mm').format(endDate)} (${detailEvent['code_timezone']})",
                            style: pw.TextStyle(font: ttf, fontSize: 10),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            order['id_order_detail'] ?? '-',
                            style: pw.TextStyle(
                              font: ttfBold,
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (qrBytes != null)
                      pw.Column(
                        children: [
                          pw.Image(
                            pw.MemoryImage(qrBytes),
                            width: 80,
                            height: 80,
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    return pdf.save();
  }
}