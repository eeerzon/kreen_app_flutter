// ignore_for_file: use_build_context_synchronously

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/global_function.dart';
import 'package:kreen_app_flutter/pages/order/order_event_paid.dart';
import 'package:kreen_app_flutter/pages/vote/add_support.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class CheckPaymentModal {
  // ─── VOTE ───────────────────────────────────────────────────────────────────
  static Future<bool?> show(BuildContext context, String idOrder) async {
    final langCode = await StorageService.getLanguage();
    final bahasa = await LangService.getJsonData(langCode!, "bahasa");

    return await showModalBottomSheet<bool?>(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _VotePaymentModalContent(
        idOrder: idOrder,
        langCode: langCode,
        bahasa: bahasa,
      ),
    );
  }

  // ─── EVENT ──────────────────────────────────────────────────────────────────
  static Future<bool?> showEvent(BuildContext context, String idOrder) async {
    final langCode = await StorageService.getLanguage();
    final bahasa = await LangService.getJsonData(langCode!, "bahasa");

    return await showModalBottomSheet<bool?>(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EventPaymentModalContent(
        idOrder: idOrder,
        langCode: langCode,
        bahasa: bahasa,
      ),
    );
  }
}

// ─── VOTE MODAL CONTENT ───────────────────────────────────────────────────────
class _VotePaymentModalContent extends StatefulWidget {
  final String idOrder;
  final String langCode;
  final Map<String, dynamic> bahasa;

  const _VotePaymentModalContent({
    required this.idOrder,
    required this.langCode,
    required this.bahasa,
  });

  @override
  State<_VotePaymentModalContent> createState() => _VotePaymentModalContentState();
}

class _VotePaymentModalContentState extends State<_VotePaymentModalContent> {
  final formatter = NumberFormat.decimalPattern("en_US");

  Map<String, dynamic> voteOrder = {};
  List<dynamic> voteOrderDetail = [];
  List<dynamic> voteFinalis = [];
  Map<String, dynamic> vote = {};
  String? statusOrder;
  String? currencyRegion;
  num totalAmountPg = 0;

  bool isLoading = true;
  bool isRedirecting = false;
  bool isCheckingPayment = false;
  bool isExpired = false;
  bool redirected = false;
  bool handlerCalled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadOrder();
      if (mounted) {
        setState(() => isLoading = false);
        _handleRedirectIfNeeded();
      }
    });
  }

  Future<void> _loadOrder() async {
    final resultOrder = await ApiService.get(
      "/order/vote/${widget.idOrder}",
      xLanguage: widget.langCode,
    );

    if (resultOrder != null && resultOrder['rc'] == 200) {
      final tempOrder = resultOrder['data'] ?? {};
      voteOrder = tempOrder['vote_order'] ?? {};
      voteOrderDetail = tempOrder['vote_order_detail'] ?? [];
      voteFinalis = tempOrder['vote_finalis'] ?? [];
      vote = tempOrder['vote'] ?? {};

      _setStatusOrder();
      _setCurrency();
      _calcTotal();

      if (voteOrder['order_status'] == '20' || voteOrder['order_status'] == '2') {
        isExpired = true;
      }
    } else {
      if (mounted) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.noHeader,
          animType: AnimType.topSlide,
          title: widget.bahasa['maaf'],
          desc: widget.bahasa['error'],
          btnOkOnPress: () {},
          btnOkColor: Colors.red,
          buttonsTextStyle: const TextStyle(color: Colors.white),
          headerAnimationLoop: false,
          dismissOnTouchOutside: true,
          showCloseIcon: true,
        ).show();
      }
    }
  }

  void _setStatusOrder() {
    statusOrder = {
      '0': widget.bahasa['status_order_0'],
      '1': widget.bahasa['status_order_1'],
      '2': widget.bahasa['status_order_2'],
      '3': widget.bahasa['status_order_3'],
      '4': widget.bahasa['status_order_4'],
      '20': widget.bahasa['status_order_20'],
      '404': widget.bahasa['status_order_404'],
    }[voteOrder['order_status']];
  }

  void _setCurrency() {
    currencyRegion = {
      'EU': 'EUR', 
      'ID': 'IDR', 
      'PH': 'PHP',
      'SG': 'SGD', 
      'US': 'USD', 
      'TH': 'THB',
      'MY': 'MYR', 
      'VN': 'VND',
    }
    [voteOrder['order_region']];
  }

  void _calcTotal() {
    num sumAmount = voteOrder['total_amount'] * voteOrder['currency_value_region'];
    totalAmountPg = num.parse(sumAmount.toStringAsFixed(5));
    if (currencyRegion == "IDR") {
      totalAmountPg = totalAmountPg.ceil();
    } else {
      totalAmountPg = (totalAmountPg * 100).ceil() / 100;
    }
  }

  Future<void> _handleRedirectIfNeeded() async {
    if (handlerCalled) return;
    handlerCalled = true;
    
    if (voteOrder['order_status'] == '1' && !isRedirecting) {
      setState(() => isRedirecting = true);

      int countdown = 3;
      late AwesomeDialog dialog;
      late void Function(void Function()) dialogSetState;

      dialog = AwesomeDialog(
        context: context,
        dialogType: DialogType.noHeader,
        animType: AnimType.scale,
        dismissOnTouchOutside: false,
        dismissOnBackKeyPress: false,
        body: StatefulBuilder(
          builder: (context, setDialogState) {
            dialogSetState = setDialogState;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  "${widget.bahasa['redirect']} $countdown ${widget.bahasa['second']}...",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        ),
      )..show();

      for (int i = countdown; i > 0; i--) {
        await Future.delayed(const Duration(seconds: 1));
        countdown--;
        if (mounted) dialogSetState(() {});
      }

      if (!mounted) return;
      dialog.dismiss();
      redirected = true;
      Navigator.of(context).pop(true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AddSupportPage(
            id_vote: vote['id_vote'],
            id_order: voteOrder['id_order'],
            nama: voteOrder['voter_name'],
          ),
        ),
      );
      return;
    }
    
    if ((voteOrder['order_status'] == '20' || voteOrder['order_status'] == '2') && !isRedirecting) {
      setState(() => isRedirecting = true);

      int countdown = 2;
      late AwesomeDialog dialog;
      late void Function(void Function()) dialogSetState;

      dialog = AwesomeDialog(
        context: context,
        dialogType: DialogType.noHeader,
        animType: AnimType.scale,
        dismissOnTouchOutside: false,
        dismissOnBackKeyPress: false,
        body: StatefulBuilder(
          builder: (context, setDialogState) {
            dialogSetState = setDialogState;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const CircularProgressIndicator(color: Colors.red),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      )..show();

      for (int i = countdown; i > 0; i--) {
        await Future.delayed(const Duration(seconds: 1));
        countdown--;
        if (mounted) dialogSetState(() {});
      }

      if (!mounted) return;
      dialog.dismiss();
      Navigator.of(context).pop(null);
    }
  }

  Color _statusColor(String? status) {
    return {
      '0': Colors.red,
      '1': Colors.green,
      '2': Colors.red,
      '3': Colors.orange,
      '4': Colors.red,
      '20': Colors.red,
    }[status] ?? Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: kGlobalPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.bahasa['info_pesanan'],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: Colors.red)),
              )
            else ...[
              Table(
                columnWidths: const {
                  0: IntrinsicColumnWidth(),
                  1: FixedColumnWidth(20),
                  2: FlexColumnWidth(),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(children: [
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.top,
                      child: const Text('Event'),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.top,
                      child: const Text(' :  '),
                    ),
                    Text(
                      vote['judul_vote'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ]),
                  const TableRow(children: [SizedBox(height: 8), SizedBox(height: 8), SizedBox(height: 8)]),
                  TableRow(children: [
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.top,
                      child: Text(widget.bahasa['finalis']),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.top,
                      child: const Text(' :  '),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: voteOrderDetail.map((detail) {
                        final finalis = voteFinalis.firstWhere(
                          (f) => f['id_finalis'] == detail['id_finalis'],
                          orElse: () => {'nama_finalis': widget.bahasa['no_data']},
                        );
                        return Text(
                          detail['qty'] > 1
                            ? "${finalis['nama_finalis']} (${detail['qty']} ${widget.bahasa['text_votes']})"
                            : "- ${finalis['nama_finalis']} (${detail['qty']} ${widget.bahasa['text_vote']})",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        );
                      }).toList(),
                    ),
                  ]),
                  const TableRow(children: [SizedBox(height: 8), SizedBox(height: 8), SizedBox(height: 8)]),
                  TableRow(children: [
                    Text(widget.bahasa['total_bayar']),
                    const Text(' :  '),
                    Text(
                      voteOrder.isNotEmpty
                        ? "$currencyRegion ${formatter.format(totalAmountPg)}"
                        : '-',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ]),
                  const TableRow(children: [SizedBox(height: 8), SizedBox(height: 8), SizedBox(height: 8)]),
                  TableRow(children: [
                    Text(widget.bahasa['status_pembayaran']),
                    const Text(' :  '),
                    Text(
                      statusOrder ?? '-',
                      style: TextStyle(
                        color: _statusColor(voteOrder['order_status']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: isCheckingPayment
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    isRedirecting
                      ? widget.bahasa['redirecting']
                      : isCheckingPayment
                        ? widget.bahasa['loading']
                        : widget.bahasa['check_status'],
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isRedirecting || isCheckingPayment
                    ? null
                    : () async {
                        setState(() {
                          isCheckingPayment = true;
                          handlerCalled = false;
                        });
                        try {
                          await _loadOrder();
                          if (mounted) setState(() {});
                          await _handleRedirectIfNeeded();
                        } finally {
                          if (mounted) setState(() => isCheckingPayment = false);
                        }
                      },
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── EVENT MODAL CONTENT ──────────────────────────────────────────────────────
class _EventPaymentModalContent extends StatefulWidget {
  final String idOrder;
  final String langCode;
  final Map<String, dynamic> bahasa;

  const _EventPaymentModalContent({
    required this.idOrder,
    required this.langCode,
    required this.bahasa,
  });

  @override
  State<_EventPaymentModalContent> createState() => _EventPaymentModalContentState();
}

class _EventPaymentModalContentState extends State<_EventPaymentModalContent> {
  final formatter = NumberFormat.decimalPattern("en_US");

  Map<String, dynamic> eventOrder = {};
  List<dynamic> eventOrderDetail = [];
  List<dynamic> eventTiket = [];
  Map<String, dynamic> event = {};
  String? statusOrder;
  String? currencyRegion;
  num totalAmountPg = 0;
  Map<String, Map<String, dynamic>> groupedTickets = {};

  bool isLoading = true;
  bool isRedirecting = false;
  bool isCheckingPayment = false;
  bool isExpired = false;
  bool redirected = false;
  bool handlerCalled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadOrder();
      if (mounted) {
        setState(() => isLoading = false);
        _handleRedirectIfNeeded();
      }
    });
  }

  Future<void> _loadOrder() async {
    final resultOrder = await ApiService.get(
      "/order/event/${widget.idOrder}",
      xLanguage: widget.langCode,
    );

    final tempOrder = resultOrder?['data'] ?? {};
    eventOrder = tempOrder['event_order'] ?? {};
    eventOrderDetail = tempOrder['event_order_detail'] ?? [];
    eventTiket = tempOrder['event_ticket'] ?? [];
    event = tempOrder['event'] ?? {};

    _setStatusOrder();
    _setCurrency();
    _calcTotal();
    _groupTickets();

    if (eventOrder['order_status'] == '20' || eventOrder['order_status'] == '2') {
      isExpired = true;
    }
  }

  void _setStatusOrder() {
    statusOrder = {
      '0': widget.bahasa['status_order_0'],
      '1': widget.bahasa['status_order_1'],
      '2': widget.bahasa['status_order_2'],
      '3': widget.bahasa['status_order_3'],
      '4': widget.bahasa['status_order_4'],
      '20': widget.bahasa['status_order_20'],
      '404': widget.bahasa['status_order_404'],
    }[eventOrder['order_status']];
  }

  void _setCurrency() {
    currencyRegion = {
      'EU': 'EUR', 
      'ID': 'IDR', 
      'PH': 'PHP',
      'SG': 'SGD', 
      'US': 'USD', 
      'TH': 'THB',
      'MY': 'MYR', 
      'VN': 'VND',
    }
    [eventOrder['order_region']];
  }

  void _calcTotal() {
    num sumAmount = (eventOrder['amount'] + eventOrder['fees']) * eventOrder['currency_value_region'];
    totalAmountPg = num.parse(sumAmount.toStringAsFixed(5));
    if (currencyRegion == "IDR") {
      totalAmountPg = totalAmountPg.ceil();
    } else {
      totalAmountPg = (totalAmountPg * 100).ceil() / 100;
    }
  }

  void _groupTickets() {
    groupedTickets = {};
    for (var detail in eventOrderDetail) {
      final id = detail['id_event_ticket'];
      final ticket = eventTiket.firstWhere(
        (f) => f['id_event_ticket'] == id,
        orElse: () => {'ticket_name': widget.bahasa['no_data']},
      );
      if (groupedTickets.containsKey(id)) {
        groupedTickets[id]!['qty'] += 1;
      } else {
        groupedTickets[id] = {
          'ticket_name': ticket['ticket_name'],
          'qty': 1,
        };
      }
    }
  }

  Future<void> _handleRedirectIfNeeded() async {
    if (handlerCalled) return;
    handlerCalled = true;

    if (eventOrder['order_status'] == '1' && !isRedirecting) {
      setState(() => isRedirecting = true);

      int countdown = 3;
      late AwesomeDialog dialog;
      late void Function(void Function()) dialogSetState;

      dialog = AwesomeDialog(
        context: context,
        dialogType: DialogType.noHeader,
        animType: AnimType.scale,
        dismissOnTouchOutside: false,
        dismissOnBackKeyPress: false,
        body: StatefulBuilder(
          builder: (context, setDialogState) {
            dialogSetState = setDialogState;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  "${widget.bahasa['redirect']} $countdown ${widget.bahasa['second']}...",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        ),
      )..show();

      for (int i = countdown; i > 0; i--) {
        await Future.delayed(const Duration(seconds: 1));
        countdown--;
        if (mounted) dialogSetState(() {});
      }

      if (!mounted) return;
      dialog.dismiss();
      redirected = true;
      Navigator.of(context).pop(true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderEventPaid(
            idOrder: eventOrder['id_order'],
            isSukses: true,
          ),
        ),
      );
      return;
    }

    if ((eventOrder['order_status'] == '20' || eventOrder['order_status'] == '2') && !isRedirecting) {
      setState(() => isRedirecting = true);

      int countdown = 2;
      late AwesomeDialog dialog;
      late void Function(void Function()) dialogSetState;

      dialog = AwesomeDialog(
        context: context,
        dialogType: DialogType.noHeader,
        animType: AnimType.scale,
        dismissOnTouchOutside: false,
        dismissOnBackKeyPress: false,
        body: StatefulBuilder(
          builder: (context, setDialogState) {
            dialogSetState = setDialogState;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const CircularProgressIndicator(color: Colors.red),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      )..show();

      for (int i = countdown; i > 0; i--) {
        await Future.delayed(const Duration(seconds: 1));
        countdown--;
        if (mounted) dialogSetState(() {});
      }

      if (!mounted) return;
      dialog.dismiss();
      Navigator.of(context).pop(null);
    }
  }

  Color _statusColor(String? status) {
    return {
      '0': Colors.red,
      '1': Colors.green,
      '2': Colors.red,
      '3': Colors.orange,
      '4': Colors.red,
      '20': Colors.red,
    }[status] ?? Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: kGlobalPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.bahasa['info_pesanan'],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: Colors.red)),
              )
            else ...[
              Table(
                columnWidths: const {
                  0: IntrinsicColumnWidth(),
                  1: FixedColumnWidth(20),
                  2: FlexColumnWidth(),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(children: [
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.top,
                      child: const Text('Event'),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.top,
                      child: const Text(' :  '),
                    ),
                    Text(
                      event['event_title'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ]),
                  const TableRow(children: [SizedBox(height: 8), SizedBox(height: 8), SizedBox(height: 8)]),
                  TableRow(children: [
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.top,
                      child: Text(widget.bahasa['tiket']),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.top,
                      child: const Text(' :  '),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: groupedTickets.values.map((tiket) {
                        return Text(
                          "- ${tiket['ticket_name']} ${tiket['qty']} x",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        );
                      }).toList(),
                    ),
                  ]),
                  const TableRow(children: [SizedBox(height: 8), SizedBox(height: 8), SizedBox(height: 8)]),
                  TableRow(children: [
                    Text(widget.bahasa['total_bayar']),
                    const Text(' :  '),
                    Text(
                      eventOrder.isNotEmpty
                        ? "$currencyRegion ${formatter.format(totalAmountPg)}"
                        : '-',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ]),
                  const TableRow(children: [SizedBox(height: 8), SizedBox(height: 8), SizedBox(height: 8)]),
                  TableRow(children: [
                    Text(widget.bahasa['status_pembayaran']),
                    const Text(' :  '),
                    Text(
                      statusOrder ?? '-',
                      style: TextStyle(
                        color: _statusColor(eventOrder['order_status']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: isCheckingPayment
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    isRedirecting
                      ? widget.bahasa['redirecting']
                      : isCheckingPayment
                        ? widget.bahasa['loading']
                        : widget.bahasa['check_status'],
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isRedirecting || isCheckingPayment
                    ? null
                    : () async {
                        setState(() {
                          isCheckingPayment = true;
                          handlerCalled = false;
                        });
                        try {
                          await _loadOrder();
                          if (mounted) setState(() {});
                          await _handleRedirectIfNeeded();
                        } finally {
                          if (mounted) setState(() => isCheckingPayment = false);
                        }
                      },
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}