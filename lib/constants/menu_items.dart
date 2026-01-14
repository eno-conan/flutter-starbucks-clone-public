import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../screens/starbucks_store_side/mobileorder/orders.dart';
import '../screens/starbucks_user_side/home/main.dart';
import '../screens/starbucks_user_side/signup/signup.dart';

/// メニュー画面の項目一覧
final List<MenuItem> menuItems = [
  MenuItem(
    routeName: Home.routeName,
    materialIcon: Icons.star_outlined,
    cupertinoIcon: CupertinoIcons.star_fill,
    label: 'Starbucks User Side',
  ),
  MenuItem(
    routeName: SignUp.routeName,
    materialIcon: Icons.star_outlined,
    cupertinoIcon: CupertinoIcons.star_fill,
    label: 'SignUp',
  ),
  MenuItem(
    routeName: StoreSideOrderList.routeName,
    materialIcon: Icons.store_outlined,
    cupertinoIcon: CupertinoIcons.star_fill,
    label: 'Starbucks Store Side',
  ),
  MenuItem(
    routeName: '/poc-home',
    materialIcon: Icons.science_outlined,
    cupertinoIcon: CupertinoIcons.star_fill,
    label: 'poc',
  ),
];

class MenuItem {
  MenuItem({
    required this.routeName,
    required this.materialIcon,
    required this.cupertinoIcon,
    required this.label,
  });
  final String routeName;
  final IconData materialIcon;
  final IconData cupertinoIcon;
  final String label;
}
