// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';

class PaymentItem extends StatefulWidget {
  final String paymentTipe;
  final Map item;
  final int idx;

  final bool isSelected;
  final bool isDisabled;

  final String? currencyCode;
  final String? voteCurrency;
  final Map bahasa;
  final NumberFormat formatter;

  final num convertedHarga;
  final num roundedValueMin;
  final num roundedValueMax;
  final int limit_max;

  final VoidCallback onTap;

  final Function(String)? onCardChanged;
  final Function(String)? onCvvChanged;
  final TextEditingController? expDateController;

  final Function(String)? onPhoneChanged;
  final Function(String)? onIDCardChanged;

  final bool showError;

  final FocusNode? cardFocus;
  final FocusNode? expiryFocus;
  final FocusNode? cvvFocus;

  final FocusNode? phoneFocus;
  final FocusNode? idCardFocus;
  final TextEditingController? phoneDebitController;
  final TextEditingController? idCardDebitController;

  final bool? cardTouched;
  final TextEditingController? cardNumberController;
  final TextEditingController? cvvController;

  final bool? debitPhoneTouched;

  final FocusNode? phoneEWalletFocus;
  final TextEditingController? phoneEwalletController;

  const PaymentItem({
    super.key,
    required this.paymentTipe,
    required this.item,
    required this.idx,
    required this.isSelected,
    required this.isDisabled,
    required this.currencyCode,
    required this.voteCurrency,
    required this.bahasa,
    required this.formatter,
    required this.convertedHarga,
    required this.roundedValueMin,
    required this.roundedValueMax,
    required this.limit_max,
    required this.onTap,
    this.onCardChanged,
    this.onCvvChanged,
    this.expDateController,
    this.onPhoneChanged,
    this.onIDCardChanged,
    required this.showError,
    this.cardFocus,
    this.expiryFocus,
    this.cvvFocus,
    this.phoneFocus,
    this.idCardFocus,
    this.phoneDebitController,
    this.idCardDebitController,
    this.cardTouched,
    this.cardNumberController,
    this.cvvController,
    this.debitPhoneTouched,
    this.phoneEWalletFocus,
    this.phoneEwalletController,
  });

  @override
  State<PaymentItem> createState() => _PaymentItemState();
}

class _PaymentItemState extends State<PaymentItem> {
  late bool cardTouched;
  late bool expiryTouched;
  late bool cvvTouched;

  late bool debitPhoneTouched;

  @override
  void initState() {
    super.initState();
    cardTouched = widget.cardTouched ?? false;
    expiryTouched = false;
    cvvTouched = false;

    debitPhoneTouched = false;
  }

  @override
  Widget build(BuildContext context) {

    final payment_name = widget.item['payment_name'];
    final id_pg_type = widget.item['id_pg_type'];
    final isSvg = widget.item['img_web'].toLowerCase().endsWith('.svg');
    final isAMEX = widget.item['note'] != null ? widget.item['note'].toLowerCase().contains('amex') : false;

    final rawAttribute = widget.item['attribute'];

    final List<dynamic> attributes =
        (rawAttribute != null && rawAttribute is String && rawAttribute.isNotEmpty)
            ? jsonDecode(rawAttribute) as List
            : [];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.isDisabled 
        ? null 
        : () {
            FocusManager.instance.primaryFocus?.unfocus();
            widget.onTap();
          },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Opacity(
            opacity: widget.isDisabled ? 0.6 : 1.0,
            child: ColorFiltered(
              colorFilter: widget.isDisabled
                ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: widget.isSelected ? Colors.green.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: isSvg
                            ? SvgPicture.network(
                                "$baseUrl/image/payment-method/${widget.item['img_web']}",
                                fit: BoxFit.contain,
                                placeholderBuilder: (_) => const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              )
                            : Image.network(
                                "$baseUrl/image/payment-method/${widget.item['img_web']}",
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/img_broken.jpg',
                                    height: 70,
                                    width: 70,
                                  );
                                },
                              ),
                        ),

                        const SizedBox(width: 8,),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        "$payment_name $id_pg_type",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      widget.item['region'] ?? '',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),
                              if (widget.convertedHarga < widget.roundedValueMin)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    widget.currencyCode == null
                                      ? "${widget.bahasa['limit_min']} ${widget.voteCurrency} ${widget.formatter.format((widget.roundedValueMin + 1000))}"
                                      : "${widget.bahasa['limit_min']} ${widget.currencyCode} ${widget.formatter.format((widget.roundedValueMin))}",
                                    softWrap: true,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ),
                              
                              if (widget.convertedHarga > widget.roundedValueMax)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text( widget.limit_max == 0
                                    ? widget.currencyCode == null
                                      ? "${widget.bahasa['limit_max']} ${widget.voteCurrency} ${widget.formatter.format((widget.roundedValueMax + 1000))}"
                                      : "${widget.bahasa['limit_max']} ${widget.currencyCode} ${widget.formatter.format((widget.roundedValueMax))}"
                                    : widget.currencyCode == null
                                      ? "${widget.bahasa['limit_max']} ${widget.voteCurrency} ${widget.formatter.format((widget.roundedValueMax))}"
                                      : "${widget.bahasa['limit_max']} ${widget.currencyCode} ${widget.formatter.format((widget.roundedValueMax))}",
                                    softWrap: true,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        )
                      ],
                    ),

                    if (widget.paymentTipe == 'credit_card') ... [
                      if (widget.isSelected) ...[
                        if (widget.item['flag_client'] == "0") ... [
                          const SizedBox(height: 20),

                          Text(widget.bahasa['kartu_credit']),

                          const SizedBox(height: 6),

                          TextField(
                            focusNode: widget.cardFocus,
                            onChanged: (value) {
                              final rawValue = value.replaceAll(' ', '');
                              widget.onCardChanged!(rawValue);
                              if (!cardTouched) {
                                setState(() => cardTouched = true);
                              } else {
                                setState(() {});
                              }
                            },
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "xxxx xxxx xxxx xxxx",
                              filled: true,
                              fillColor: Colors.white,
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                                borderSide: BorderSide(color: Colors.grey.shade300,),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade300,),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(16),
                              CardNumberFormatter(),
                            ],
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  focusNode: widget.expiryFocus,
                                  controller: widget.expDateController,
                                  onChanged: (value) {
                                    if (!expiryTouched) {
                                      setState(() => expiryTouched = true);
                                    } else {
                                      setState(() {});
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: "MM/YY",
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                      ),
                                      borderSide: BorderSide(color: Colors.grey.shade300,),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey.shade300,),
                                    ),
                                  ),
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(5),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  focusNode: widget.cvvFocus,
                                  onChanged: (value)  {
                                    if (!cvvTouched) {
                                      setState(() => cvvTouched = true);
                                    } else {
                                      setState(() {});
                                    }
                                    widget.onCvvChanged?.call(value);
                                  },
                                  decoration: InputDecoration(
                                    hintText: "CVV",
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.only(
                                        bottomRight: Radius.circular(8),
                                      ),
                                      borderSide: BorderSide(color: Colors.grey.shade300,),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey.shade300,),
                                    ),
                                  ),
                                  inputFormatters: [ 
                                    isAMEX 
                                      ? LengthLimitingTextInputFormatter(4) 
                                      : LengthLimitingTextInputFormatter(3),
                                  ],
                                  obscureText: true,
                                ),
                              ),
                            ],
                          ),

                          if (widget.showError && (
                            (widget.cardNumberController?.text.trim().isEmpty ?? true) ||
                            (widget.expDateController?.text.trim().isEmpty ?? true) ||
                            (widget.cvvController?.text.trim().isEmpty ?? true)
                          ))
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                              child: Text(
                                widget.bahasa['required'],
                                style: TextStyle(color: Colors.red[900], fontSize: 12),
                              ),
                            ),
                        ],
                      ]
                    ],

                    if (widget.paymentTipe == "debit") ...[
                      if (widget.isSelected) ... [
                        if (widget.item['flag_client'] == "0") ...[
                          const SizedBox(height: 20,),
                          if (attributes.isNotEmpty) ...[
                            ...List.generate(attributes.length, (idx) {
                              final itemAtribute = attributes[idx];
                              final isLast = idx == attributes.length - 1;

                              final bool isphone = itemAtribute['code'] == 'mobile_number';
                              final String? value = isphone
                                ? widget.phoneDebitController?.text.trim()
                                : widget.idCardDebitController?.text.trim();

                              final bool hasError = widget.showError && (
                                value == null ||
                                (isphone && !isValidPhone(value)) ||
                                (!isphone && value.isEmpty)
                              );

                              return Padding(
                                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      color: Colors.white,
                                      width: double.infinity,
                                      child: TextField(
                                        focusNode: isphone ? widget.phoneFocus : widget.idCardFocus,
                                        controller: isphone ? widget.phoneDebitController : widget.idCardDebitController,
                                        autofocus: false,
                                        onChanged: (value) {
                                          if (isphone) {
                                            if (!debitPhoneTouched) {
                                              setState(() => debitPhoneTouched = true);
                                            } else {
                                              setState(() {});
                                            }
                                            widget.onPhoneChanged?.call(value);
                                          } else {
                                            widget.onIDCardChanged?.call(value);
                                          }
                                        },
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: isphone ? widget.bahasa['nomor_hp'] : widget.bahasa['id_card'],
                                          filled: true,
                                          fillColor: Colors.white,
                                          hintStyle: TextStyle(color: Colors.grey.shade400),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(8),
                                              topRight: Radius.circular(8),
                                            ),
                                            borderSide: BorderSide(color: Colors.grey.shade300,),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.grey.shade300,),
                                          ),
                                        ),
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(16),
                                        ],
                                      ),
                                    ),

                                    if (hasError)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                                        child: Text(
                                          isphone
                                            ? (value != null && value.isNotEmpty && !isValidPhone(value)
                                                ? widget.bahasa['nomor_hp_error']
                                                : widget.bahasa['nomor_hp'])
                                            : widget.bahasa['id_card'],
                                          style: TextStyle(color: Colors.red[900], fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ] else ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.item['flag_client'] == "0") ...[
                                  Container(
                                    color: Colors.white,
                                    width: double.infinity,
                                    child: TextField(
                                      focusNode: widget.phoneFocus,
                                      autofocus: false,
                                      onChanged: widget.onPhoneChanged,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: widget.bahasa['nomor_hp'],
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintStyle: TextStyle(color: Colors.grey.shade400),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            topRight: Radius.circular(8),
                                          ),
                                          borderSide: BorderSide(color: Colors.grey.shade300,),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.grey.shade300,),
                                        ),
                                      ),
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(16),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            )
                          ],
                        ],
                      ]
                    ],
                    
                    if (widget.paymentTipe == "e_wallet") ...[
                      if (widget.isSelected) ... [

                        if (attributes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ...List.generate(attributes.length, (i) {
                            final attr = attributes[i];
                            final isPhone = attr['code'] == 'mobile_number';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  
                                  Container(
                                    color: Colors.white,
                                    width: double.infinity,
                                    child: TextField(
                                      focusNode: widget.phoneEWalletFocus,
                                      controller: widget.phoneEwalletController,
                                      autofocus: false,
                                      onChanged: widget.onPhoneChanged,
                                      keyboardType: isPhone
                                          ? TextInputType.number
                                          : TextInputType.text,
                                      decoration: InputDecoration(
                                        hintText: attr['name'] ?? '',
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintStyle: TextStyle(color: Colors.grey.shade400),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                      ),
                                      inputFormatters: [
                                        if (isPhone) FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(16),
                                      ],
                                    ),
                                  ),
                                  if (widget.showError &&
                                      (widget.phoneEwalletController?.text.trim().isEmpty ?? true))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        widget.bahasa['nomor_hp'] ?? 'Wajib diisi',
                                        style: TextStyle(color: Colors.red[900], fontSize: 12),
                                      ),
                                    )
                                  else if (isPhone &&
                                      widget.phoneEwalletController?.text.trim().isNotEmpty == true &&
                                      !isValidPhone(widget.phoneEwalletController!.text.trim()))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        widget.bahasa['nomor_hp_error'] ?? 'Nomor tidak valid',
                                        style: TextStyle(color: Colors.red[900], fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ]
                      ]
                    ],
                  ],
                )
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // hapus semua spasi
    final text = newValue.text.replaceAll(' ', '');

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}