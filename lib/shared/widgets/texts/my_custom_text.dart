import 'package:flutter/material.dart';

class MyCustomText extends StatelessWidget {
  const MyCustomText({
    super.key,
    required this.text,
    this.fontSize,
    this.textColor,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softwrap,
    this.useEnglishFont,
  });
  final String text;
  final double? fontSize;
  final Color? textColor;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softwrap;
  final bool? useEnglishFont;

  // デフォルトのスタイル設定
  static const defaultFontSize = 14.0;
  static const defaultTextColor = Colors.black87;
  static const defaultFontWeight = FontWeight.normal;
  static const defaultTextAlign = TextAlign.left;
  static const defaultSoftWrap = false;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        letterSpacing: -1.0,
        fontFamily: useEnglishFont ?? false ? 'Roboto' : 'NotoSansJP',
        fontSize: fontSize ?? defaultFontSize,
        color: textColor ?? defaultTextColor,
        fontWeight: fontWeight ?? defaultFontWeight,
      ),
      textAlign: textAlign ?? defaultTextAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softwrap ?? defaultSoftWrap,
    );
  }
}
