// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';

class PaymentItem extends StatelessWidget {
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
    this.idCardDebitController
  });

  @override
  Widget build(BuildContext context) {

    final payment_name = item['payment_name'];
    final id_pg_type = item['id_pg_type'];
    final isSvg = item['img_web'].toLowerCase().endsWith('.svg');
    final isAMEX = item['note'] != null ? item['note'].toLowerCase().contains('amex') : false;

    final rawAttribute = item['attribute'];

    final List<dynamic> attributes =
        (rawAttribute != null && rawAttribute is String && rawAttribute.isNotEmpty)
            ? jsonDecode(rawAttribute) as List
            : [];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isDisabled 
        ? null 
        : () {
            FocusManager.instance.primaryFocus?.unfocus();
            onTap();
          },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Opacity(
            opacity: isDisabled ? 0.6 : 1.0,
            child: ColorFiltered(
              colorFilter: isDisabled
                ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green.shade50 : Colors.white,
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
                                "$baseUrl/image/payment-method/${item['img_web']}",
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
                                "$baseUrl/image/payment-method/${item['img_web']}",
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
                                  // Teks akan menyesuaikan ruang sisa
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
                                  // Badge region
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item['region'] ?? '',
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
                              if (convertedHarga < roundedValueMin)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    currencyCode == null
                                      ? "${bahasa['limit_min']} $voteCurrency ${formatter.format((roundedValueMin + 1000))}"
                                      : "${bahasa['limit_min']} $currencyCode ${formatter.format((roundedValueMin))}",
                                    softWrap: true,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ),
                              
                              if (convertedHarga > roundedValueMax)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text( limit_max == 0
                                    ? currencyCode == null
                                      ? "${bahasa['limit_max']} $voteCurrency ${formatter.format((roundedValueMax + 1000))}"
                                      : "${bahasa['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}"
                                    : currencyCode == null
                                      ? "${bahasa['limit_max']} $voteCurrency ${formatter.format((roundedValueMax))}"
                                      : "${bahasa['limit_max']} $currencyCode ${formatter.format((roundedValueMax))}",
                                    softWrap: true,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        )
                      ],
                    ),

                    if (paymentTipe == 'credit_card') ... [
                      if (isSelected) ...[
                        if (item['flag_client'] == "0") ... [
                          const SizedBox(height: 20),

                          Text(bahasa['kartu_credit']),

                          const SizedBox(height: 6),

                          TextField(
                            focusNode: cardFocus,
                            onChanged: (value) {
                              final rawValue = value.replaceAll(' ', '');
                              onCardChanged!(rawValue);
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
                                  focusNode: expiryFocus,
                                  controller: expDateController,
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
                                  focusNode: cvvFocus,
                                  onChanged: onCvvChanged,
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

                          if (showError) ... [
                            const SizedBox(height: 6),
                            Text(
                              bahasa['required'],
                              style: const TextStyle(color: Colors.red),
                            )
                          ]
                        ],
                      ]
                    ],

                    if (paymentTipe == "debit") ...[
                      if (isSelected) ... [
                        if (item['flag_client'] == "0") ...[
                          const SizedBox(height: 20,),
                          if (attributes.isNotEmpty) ...[
                            ...List.generate(attributes.length, (idx) {
                              final itemAtribute = attributes[idx];
                              final isLast = idx == attributes.length - 1;

                              final bool isphone = itemAtribute['code'] == 'mobile_number';
                              final String? value = isphone
                                ? phoneDebitController?.text.trim()
                                : idCardDebitController?.text.trim();

                              final bool hasError = showError && (
                                value == null ||
                                (isphone && !isValidPhone(value))
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
                                        focusNode: isphone ? phoneFocus : idCardFocus,
                                        controller: isphone ? phoneDebitController : idCardDebitController,
                                        autofocus: false,
                                        onChanged: isphone ? onPhoneChanged : onIDCardChanged,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: isphone ? bahasa['nomor_hp'] : bahasa['id_card'],
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
                                          errorText: hasError
                                            ? (isphone
                                                ? value != null && !isValidPhone(value)
                                                    ? bahasa['nomor_hp_error']
                                                    : bahasa['nomor_hp']
                                                : bahasa['id_card'])
                                            : null,
                                        ),
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(16),
                                        ],
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
                                if (item['flag_client'] == "0") ...[
                                  Container(
                                    color: Colors.white,
                                    width: double.infinity,
                                    child: TextField(
                                      focusNode: phoneFocus,
                                      autofocus: false,
                                      onChanged: onPhoneChanged,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: bahasa['nomor_hp'],
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
                    
                    if (paymentTipe == "e_wallet") ...[
                      if (isSelected) ... [
                        if (item['id'] == "6387457643547345") ...[
                          // const SizedBox(height: 10,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                color: Colors.white,
                                width: double.infinity,
                                child: TextField(
                                  focusNode: phoneFocus,
                                  autofocus: false,
                                  onChanged: onPhoneChanged,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: bahasa['nomor_hp'],
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
                                    LengthLimitingTextInputFormatter(12),
                                  ],
                                ),
                              ),
                            ],
                          ),
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