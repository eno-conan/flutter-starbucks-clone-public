import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// オフライン時に表示する共通Widget
class OfflinePage extends ConsumerWidget {
  const OfflinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Text('オフラインです', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: Image.asset(
                'assets/starbucks/png/aplogize_panda.png',
                width: 200,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
