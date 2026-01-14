import 'package:flutter/material.dart';

/// タブバーに表示するアイコンを定数化
class BottomNavbarIcons {
  static final labelList = <String>['Home', 'Pay', 'Stores', 'Order', 'Gift'];

  static final iconActiveList = <IconData>[
    Icons.star,
    Icons.credit_card,
    Icons.store_mall_directory,
    Icons.local_drink,
    Icons.redeem,
  ];

  static final iconList = <IconData>[
    Icons.star_border,
    Icons.credit_card_outlined,
    Icons.store_mall_directory_outlined,
    Icons.local_drink_outlined,
    Icons.redeem_outlined,
  ];
}
