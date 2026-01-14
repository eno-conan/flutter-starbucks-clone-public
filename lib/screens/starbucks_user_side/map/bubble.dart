import 'package:flutter/material.dart';

class BubbleWidget extends StatelessWidget {
  const BubbleWidget({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.grey,
    this.borderWidth = 1.0,
    this.borderRadius = 8.0,
    this.tailHeight = 10.0,
    this.tailWidth = 16.0,
    this.padding = const .all(12.0),
    this.margin = const .all(8.0),
    this.shadow,
  });

  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double tailHeight;
  final double tailWidth;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BoxShadow? shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // メインコンテンツ部分
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                border: borderWidth > 0 ? Border.all(color: borderColor, width: borderWidth) : null,
                borderRadius: BorderRadius.circular(borderRadius),
                // boxShadowを除去してRaster負荷を軽減
              ),
              padding: padding,
              child: child,
            ),
          ),
          // 尻尾部分
          RepaintBoundary(
            child: CustomPaint(
              size: Size(tailWidth, tailHeight),
              painter: TailPainter(
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                borderWidth: borderWidth,
                tailWidth: tailWidth,
                tailHeight: tailHeight,
                shadow: shadow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TailPainter extends CustomPainter {
  TailPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.tailWidth,
    required this.tailHeight,
    this.shadow,
  });

  // キャッシュ用のHashコードを計算
  int get _hashCode =>
      Object.hash(backgroundColor, borderColor, borderWidth, tailWidth, tailHeight, shadow);

  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double tailWidth;
  final double tailHeight;
  final BoxShadow? shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // 尻尾のパスを作成
    final path = _createTailPath(size, Offset.zero);

    // MaskFilter.blurを除去してRaster負荷を軽減
    // 代わりにシンプルな影効果で代用
    if (shadow != null) {
      final shadowPaint = Paint()
        ..color = shadow!.color.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      final shadowPath = _createTailPath(size, shadow!.offset);
      canvas.drawPath(shadowPath, shadowPaint);
    }

    // 背景を描画
    canvas.drawPath(path, paint);

    // 境界線を描画
    if (borderWidth > 0) {
      canvas.drawPath(path, borderPaint);
    }
  }

  Path _createTailPath(Size size, Offset offset) {
    final path = Path();
    final centerX = size.width / 2 + offset.dx;

    // 尻尾の三角形
    path.moveTo(centerX - tailWidth / 2, offset.dy);
    path.lineTo(centerX, tailHeight + offset.dy);
    path.lineTo(centerX + tailWidth / 2, offset.dy);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant TailPainter oldDelegate) {
    // 精密な比較で不要な再描画を防止
    return backgroundColor != oldDelegate.backgroundColor ||
        borderColor != oldDelegate.borderColor ||
        borderWidth != oldDelegate.borderWidth ||
        tailWidth != oldDelegate.tailWidth ||
        tailHeight != oldDelegate.tailHeight ||
        shadow != oldDelegate.shadow;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TailPainter &&
            backgroundColor == other.backgroundColor &&
            borderColor == other.borderColor &&
            borderWidth == other.borderWidth &&
            tailWidth == other.tailWidth &&
            tailHeight == other.tailHeight &&
            shadow == other.shadow);
  }

  @override
  int get hashCode => _hashCode;
}

// 使用例のサンプルWidget（修正版）
class Bubble extends StatelessWidget {
  const Bubble({super.key, required this.storeName});
  final String storeName;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: .center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 基本的な使用例
          BubbleWidget(
            borderColor: Colors.white,
            shadow: BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: .start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.store, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          storeName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '東京都 中央区 日本橋2-5-1\n日本橋高島屋S.C.新館1階',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: .spaceBetween,
                    children: const [
                      Text('詳細を見る', style: TextStyle(color: Colors.blue, fontSize: 12)),
                      Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
