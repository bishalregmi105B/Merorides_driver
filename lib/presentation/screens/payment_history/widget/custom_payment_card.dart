import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/helper/date_converter.dart';
import 'package:ovoride_driver/core/helper/string_format_helper.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/core/utils/util.dart';
import 'package:ovoride_driver/data/controller/payment_history/payment_history_controller.dart';
import 'package:ovoride_driver/data/model/payment_history/payment_history_response_model.dart';
import 'package:ovoride_driver/data/services/api_client.dart';
import 'package:ovoride_driver/data/services/local_storage_service.dart';
import 'package:ovoride_driver/presentation/components/card/custom_app_card.dart';
import 'package:ovoride_driver/presentation/components/divider/custom_divider.dart';
import 'package:ovoride_driver/presentation/components/divider/custom_spacer.dart';
import 'package:ovoride_driver/presentation/components/text/header_text.dart';
import 'package:ovoride_driver/presentation/screens/payment_history/widget/payment_status_widget.dart';

import '../../../../core/utils/dimensions.dart';
import '../../../../core/utils/my_color.dart';
import '../../../../core/utils/my_strings.dart';
import '../../../components/column_widget/card_column.dart';

class CustomPaymentCard extends StatelessWidget {
  final PaymentHistoryModel payment;
  final int index;

  const CustomPaymentCard({
    super.key,
    required this.index,
    required this.payment,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PaymentHistoryController>(
      builder: (controller) => CustomAppCard(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: GestureDetector(
                          onTap: () {
                            MyUtils.copy(text: payment.trxNumber ?? payment.ride?.uid ?? '');
                          },
                          child: HeaderText(
                            text: "#${payment.trxNumber ?? payment.ride?.uid ?? ''}",
                            style: boldLarge.copyWith(
                              color: MyColor.getBodyTextColor(),
                            ),
                          ),
                        ),
                      ),
                      if (payment.transactionType != null) ...[
                        spaceSide(Dimensions.space8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimensions.space5,
                            vertical: Dimensions.space2,
                          ),
                          decoration: BoxDecoration(
                            color: payment.isWebTransaction
                                ? MyColor.highPriorityPurpleColor.withValues(alpha: 0.1)
                                : MyColor.colorGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            payment.isWebTransaction ? 'WEB' : 'RIDE',
                            style: boldDefault.copyWith(
                              fontSize: 10,
                              color: payment.isWebTransaction
                                  ? MyColor.highPriorityPurpleColor
                                  : MyColor.colorGreen,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                spaceSide(Dimensions.space10),
                Expanded(
                  child: HeaderText(
                    text: DateConverter.estimatedDate(
                      DateTime.tryParse(payment.createdAt ?? "") ?? DateTime.now(),
                      formatType: DateFormatType.onlyDate,
                    ),
                    textAlign: TextAlign.end,
                    style: regularDefault.copyWith(
                      color: MyColor.getBodyTextColor(),
                    ),
                  ),
                ),
              ],
            ),
            if (payment.isWebTransaction && payment.remark != null) ...[
              spaceDown(Dimensions.space5),
              Text(
                payment.remark!.replaceAll('_', ' ').capitalizeFirst ?? '',
                style: regularSmall.copyWith(
                  color: MyColor.colorGrey,
                  fontSize: 11,
                ),
              ),
            ],
            const CustomDivider(space: Dimensions.space15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (Get.find<LocalStorageService>().canShowPrices())
                  Expanded(
                    child: CardColumn(
                      header: MyStrings.amount,
                      body: "${Get.find<ApiClient>().getCurrency(isSymbol: true)}${StringConverter.formatNumber(payment.amount ?? '0')}",
                      headerTextStyle: regularDefault.copyWith(
                        color: MyColor.getBodyTextColor(),
                      ),
                      bodyTextStyle: boldLarge.copyWith(
                        color: MyColor.getHeadingTextColor(),
                        fontSize: Dimensions.fontTitleLarge,
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PaymentStatusWidget(
                      status: payment.paymentType == "1"
                          ? MyStrings.onlinePayment.tr
                          : payment.paymentType == "2"
                              ? MyStrings.cashPayment.tr
                              : "Gateway",
                      color: payment.paymentType == "1"
                          ? MyColor.informationColor
                          : payment.paymentType == "2"
                              ? MyColor.greenSuccessColor
                              : MyColor.highPriorityPurpleColor,
                    ),
                    if (payment.isWebTransaction && payment.trxType != null) ...[
                      spaceDown(Dimensions.space5),
                      Text(
                        payment.trxType == '+' ? 'Credit ↑' : 'Debit ↓',
                        style: boldDefault.copyWith(
                          fontSize: 11,
                          color: payment.trxType == '+'
                              ? MyColor.greenSuccessColor
                              : MyColor.colorRed,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (payment.isWebTransaction && payment.description != null) ...[
              const CustomDivider(space: Dimensions.space15),
              CardColumn(
                header: "Description",
                body: payment.description ?? "",
                headerTextStyle: regularDefault.copyWith(
                  color: MyColor.getBodyTextColor(),
                ),
                bodyTextStyle: regularDefault.copyWith(
                  color: MyColor.getTextColor(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
