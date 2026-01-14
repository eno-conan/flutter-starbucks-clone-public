// import 'package:flutter/material.dart';
// import 'package:testingapp/screens/qr/barcode_scanner_simple.dart';
// import 'package:testingapp/util/custom_text.dart';

// class ScanQrCode extends StatelessWidget {
//   const ScanQrCode({super.key});
//   static String routeName = 'create_qr_top';

//   Widget _buildItem(BuildContext context, String label, Widget page) {
//     return Padding(
//       padding: const .all(8.0),
//       child: Center(
//         child: ElevatedButton(
//           onPressed: () {
//             Navigator.of(context).push(
//               MaterialPageRoute(
//                 builder: (context) => page,
//               ),
//             );
//           },
//           child: Text(label),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//           child: Center(
//             child: Column(
//               spacing: 10,
//               children: [
//                 MyCustomText(text: 'QRコード読み込み', fontSize: 28),
//                 Expanded(
//                   child: ListView(
//                     children: [
//                       _buildItem(
//                         context,
//                         'MobileScanner Simple',
//                         const BarcodeScannerSimple(),
//                       ),
//                       // _buildItem(
//                       //   context,
//                       //   'MobileScanner with ListView',
//                       //   const BarcodeScannerListView(),
//                       // ),
//                       // _buildItem(
//                       //   context,
//                       //   'MobileScanner with Controller',
//                       //   const BarcodeScannerWithController(),
//                       // ),
//                       // _buildItem(
//                       //   context,
//                       //   'MobileScanner with ScanWindow',
//                       //   const BarcodeScannerWithScanWindow(),
//                       // ),
//                       // _buildItem(
//                       //   context,
//                       //   'MobileScanner with Controller (return image)',
//                       //   const BarcodeScannerReturningImage(),
//                       // ),
//                       // _buildItem(
//                       //   context,
//                       //   'MobileScanner with zoom slider',
//                       //   const BarcodeScannerWithZoom(),
//                       // ),
//                       // _buildItem(
//                       //   context,
//                       //   'MobileScanner with PageView',
//                       //   const BarcodeScannerPageView(),
//                       // ),
//                       // _buildItem(
//                       //   context,
//                       //   'MobileScanner with Overlay',
//                       //   const BarcodeScannerWithOverlay(),
//                       // ),
//                       // _buildItem(
//                       //   context,
//                       //   'Analyze image from file',
//                       //   const BarcodeScannerAnalyzeImage(),
//                       // ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//     ;
//   }
// }
